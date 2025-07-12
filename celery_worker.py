import os
import tempfile
import subprocess
from celery import Celery

# --- Celery Configuration for RabbitMQ ---
# Get the AMQP URL from an environment variable
amqp_url = os.environ.get("CLOUDAMQP_URL")
celery_app = Celery("tasks", broker=amqp_url, backend=amqp_url)


@celery_app.task
def run_slicing_job_task(job_id, stl_path):
    # This function is now a Celery task that runs in the background
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

        if proc.returncode != 0:
            # When a task fails, Celery stores the exception.
            raise Exception(proc.stderr)

        # Parse the output to get the results
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

        if print_time_seconds is None or filament_length_mm is None:
            raise Exception("Failed to parse slicer output from G-code file")
        
        # If successful, return a dictionary with the results
        return {
            "print_time_seconds": print_time_seconds,
            "filament_length_mm": filament_length_mm
        }
    finally:
        # Clean up the temporary files
        try:
            os.remove(stl_path)
            os.remove(output_gcode_path)
        except OSError:
            pass
