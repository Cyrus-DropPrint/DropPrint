import os
import tempfile
import subprocess
import uuid
from flask import Flask, request, jsonify, url_for

# This is the critical import for gevent
from gevent import monkey, spawn
monkey.patch_all() # Patches standard libraries to be gevent-friendly

app = Flask(__name__)

# In-memory "database" to store job status and results
jobs = {}

def run_slicing_job(job_id, stl_path, gcode_path):
    """This function runs in a gevent greenlet"""
    try:
        proc_env = os.environ.copy()
        proc_env["QT_QPA_PLATFORM"] = "offscreen"

        command_to_run = [
            "/app/Cura.AppImage",
            "--",
            "slice",
            "-v",
            "-j", "default_config.json",
            "-l", stl_path,
            "-o", gcode_path
        ]
        
        proc = subprocess.run(
            command_to_run,
            capture_output=True,
            text=True,
            env=proc_env
        )

        if proc.returncode != 0:
            jobs[job_id] = {"status": "failed", "error": proc.stderr}
            return

        print_time = None
        filament = None
        for line in proc.stdout.splitlines():
            if "Print time (s):" in line:
                print_time = float(line.split(":")[1].strip())
            if "Filament (mm^3):" in line:
                filament = float(line.split(":")[1].strip())

        if print_time is None or filament is None:
            jobs[job_id] = {"status": "failed", "error": "Failed to parse CuraEngine output"}
            return
            
        jobs[job_id] = {
            "status": "completed",
            "result": {
                "print_time_seconds": print_time,
                "filament_mm3": filament
            }
        }

    except Exception as e:
        jobs[job_id] = {"status": "failed", "error": str(e)}
    finally:
        try:
            os.remove(stl_path)
            os.remove(gcode_path)
        except OSError:
            pass

@app.route("/quote", methods=["POST"])
def submit_quote_job():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    with tempfile.NamedTemporaryFile(delete=False, suffix=".stl") as tmp_stl:
        file.save(tmp_stl.name)
        stl_path = tmp_stl.name

    output_gcode = tempfile.NamedTemporaryFile(delete=False, suffix=".gcode").name
    
    job_id = str(uuid.uuid4())
    jobs[job_id] = {"status": "processing"}

    # Start the slicing job in a background greenlet using gevent.spawn
    spawn(run_slicing_job, job_id, stl_path, output_gcode)

    return jsonify({
        "job_id": job_id,
        "status": "processing",
        "status_url": url_for('get_job_status', job_id=job_id, _external=True)
    }), 202

@app.route("/status/<job_id>", methods=["GET"])
def get_job_status(job_id):
    job = jobs.get(job_id)
    if not job:
        return jsonify({"error": "Job not found"}), 404
    return jsonify(job)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
