import os
import tempfile
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)

# This is the standard path for a package installed with apt-get
CURAENGINE_PATH = "/usr/bin/cura-engine"
PRINTER_PROFILE = "default_config.json"

@app.route("/quote", methods=["POST"])
def get_quote():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    with tempfile.NamedTemporaryFile(delete=False, suffix=".stl") as tmp_stl:
        file.save(tmp_stl.name)
        stl_path = tmp_stl.name

    output_gcode = tempfile.NamedTemporaryFile(delete=False, suffix=".gcode").name

    try:
        command_to_run = [
            CURAENGINE_PATH,
            "slice",
            "-v",
            "-j", PRINTER_PROFILE,
            "-l", stl_path,
            "-o", output_gcode
        ]
        
        proc = subprocess.run(
            command_to_run,
            capture_output=True,
            text=True,
            timeout=290  # Timeout slightly less than Gunicorn's
        )

        if proc.returncode != 0:
            return jsonify({"error": "CuraEngine failed", "details": proc.stderr}), 500

        print_time = None
        filament = None
        for line in proc.stdout.splitlines():
            if ";TIME:" in line:
                print_time = float(line.split(":")[1].strip())
            if ";Filament used:" in line:
                filament_str = line.split(":")[1].strip().split("m")[0]
                filament = float(filament_str) * 1000 # Convert m to mm

        if print_time is None or filament is None:
            return jsonify({"error": "Failed to parse CuraEngine output", "raw_output": proc.stdout}), 500

        return jsonify({
            "print_time_seconds": print_time,
            "filament_mm": filament 
        })

    except subprocess.TimeoutExpired:
        return jsonify({"error": "Slicing process timed out after 290 seconds"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        try:
            os.remove(stl_path)
            os.remove(output_gcode)
        except OSError:
            pass

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
