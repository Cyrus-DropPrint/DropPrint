import os
import tempfile
import subprocess
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from models import Base, SlicingJob  # Make sure models.py is in same directory

DATABASE_URL = "sqlite:///slicing_jobs.db"

engine = create_engine(DATABASE_URL)
Base.metadata.create_all(engine)

Session = sessionmaker(bind=engine)
db_session = Session()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL

# --- Configuration ---
PRUSASLICER_PATH = "./PrusaSlicer.AppImage"
PRINTER_PROFILE = "prusa_config.ini" 

@app.route("/quote", methods=["POST"])
def get_quote():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # Save the uploaded file temporarily
    with tempfile.NamedTemporaryFile(delete=False, suffix=".stl") as tmp_stl:
        file.save(tmp_stl.name)
        stl_path = tmp_stl.name

    output_gcode_path = tempfile.NamedTemporaryFile(delete=False, suffix=".gcode").name

    # Create job entry in DB
    new_job = SlicingJob(filename=file.filename, status="processing")
    db_session.add(new_job)
    db_session.commit()
    job_id = new_job.id

    try:
        # Construct the command for prusa-slicer-console
        command = [
            PRUSASLICER_PATH,
            "--export-gcode",
            "--load", PRINTER_PROFILE,
            "-o", output_gcode_path,
            stl_path
        ]

        # Run the PrusaSlicer AppImage
        proc = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=290
        )

        if proc.returncode != 0:
            new_job.status = "error"
            db_session.commit()
            return jsonify({"error": "PrusaSlicer failed", "details": proc.stderr}), 500
        
        # --- PARSE G-CODE FILE FOR FILAMENT AND TIME ---
        print_time_seconds = None
        filament_length_mm = None

        with open(output_gcode_path, 'r') as gcode_file:
            for line in gcode_file:
                if "estimated printing time (normal mode)" in line:
                    time_str = line.split("= ")[1]
                    days, hours, minutes, seconds = 0, 0, 0, 0
                    if "d" in time_str:
                        days = int(time_str.split("d")[0])
                        time_str = time_str.split("d")[1].strip()
                    if "h" in time_str:
                        hours = int(time_str.split("h")[0])
                        time_str = time_str.split("h")[1].strip()
                    if "m" in time_str:
                        minutes = int(time_str.split("m")[0])
                        time_str = time_str.split("m")[1].strip()
                    if "s" in time_str:
                        seconds = int(time_str.split("s")[0])
                    
                    print_time_seconds = (days * 86400) + (hours * 3600) + (minutes * 60) + seconds
                
                if "; filament used [mm] =" in line:
                    filament_length_mm = float(line.split("= ")[1])
                
                if print_time_seconds is not None and filament_length_mm is not None:
                    break
        
        if print_time_seconds is None or filament_length_mm is None:
            new_job.status = "error"
            db_session.commit()
            return jsonify({"error": "Failed to parse slicer output from G-code file", "details": proc.stderr}), 500

        # Update DB job as successful
        new_job.print_time_seconds = print_time_seconds
        new_job.filament_length_mm = filament_length_mm
        new_job.status = "completed"
        db_session.commit()

        return jsonify({
            "job_id": job_id,
            "print_time_seconds": print_time_seconds,
            "filament_length_mm": filament_length_mm
        })

    except subprocess.TimeoutExpired:
        new_job.status = "error"
        db_session.commit()
        return jsonify({"error": "Slicing process timed out after 290 seconds"}), 500

    except Exception as e:
        new_job.status = "error"
        db_session.commit()
        return jsonify({"error": str(e)}), 500

    finally:
        try:
            os.remove(stl_path)
            os.remove(output_gcode_path)
        except OSError:
            pass

@app.route("/status/<int:job_id>", methods=["GET"])
def check_status(job_id):
    job = db_session.query(SlicingJob).filter_by(id=job_id).first()
    if not job:
        return jsonify({"error": "Job not found"}), 404

    return jsonify({
        "job_id": job.id,
        "filename": job.filename,
        "status": job.status,
        "print_time_seconds": job.print_time_seconds,
        "filament_length_mm": job.filament_length_mm,
        "created_at": job.created_at.isoformat()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)


