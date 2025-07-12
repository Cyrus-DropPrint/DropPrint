import os
import tempfile
import subprocess
from celery import Celery
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

# --- Celery Configuration ---
# Get the Redis URL from an environment variable you'll set in Koyeb
redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
celery_app = Celery("tasks", broker=redis_url, backend=redis_url)

# --- Database Setup (for the worker) ---
app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

# Define the Job model again so the worker knows about it
class Job(db.Model):
    id = db.Column(db.String(36), primary_key=True)
    status = db.Column(db.String(20), nullable=False, default="processing")
    print_time = db.Column(db.Float, nullable=True)
    filament_mm = db.Column(db.Float, nullable=True)
    error_message = db.Column(db.Text, nullable=True)


@celery_app.task
def run_slicing_job_task(job_id, stl_path):
    """This function is now a Celery task that runs in the background"""
    output_gcode_path = tempfile.NamedTemporaryFile(delete=False, suffix=".gcode").name

    try:
        command = [
            "./PrusaSlicer.AppImage",
            "--export-gcode",
            "--load", "prusa_config.ini",
            "-o", output_gcode_path,
            stl_path
        ]
        
        proc = subprocess.run(command, capture_output=True, text=True)

        with app.app_context():
            job = db.session.get(Job, job_id)
            if not job:
                return # Job was deleted or not found

            if proc.returncode != 0:
                job.status = "failed"
                job.error_message = proc.stderr
            else:
                print_time_seconds = None
                filament_length_mm = None
                with open(output_gcode_path, 'r') as gcode_file:
                    for line in gcode_file:
                        if "estimated printing time (normal mode)" in line:
                            time_str = line.split("= ")[1]
                            days, hours, minutes, seconds = 0, 0, 0, 0
                            if "d" in time_str: days = int(time_str.split("d")[0]); time_str = time_str.split("d")[1].strip()
                            if "h" in time_str: hours = int(time_str.split("h")[0]); time_str = time_str.split("h")[1].strip()
                            if "m" in time_str: minutes = int(time_str.split("m")[0]); time_str = time_str.split("m")[1].strip()
                            if "s" in time_str: seconds = int(time_str.split("s")[0])
                            print_time_seconds = (days * 86400) + (hours * 3600) + (minutes * 60) + seconds
                        if "; filament used [mm] =" in line:
                            filament_length_mm = float(line.split("= ")[1])
                
                job.status = "completed"
                job.print_time = print_time_seconds
                job.filament_mm = filament_length_mm
            
            db.session.commit()

    except Exception as e:
        with app.app_context():
            job = db.session.get(Job, job_id)
            if job:
                job.status = "failed"
                job.error_message = str(e)
                db.session.commit()
    finally:
        try:
            os.remove(stl_path)
            os.remove(output_gcode_path)
        except OSError:
            pass
