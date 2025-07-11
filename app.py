import os
import tempfile
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)

# This is the correct, absolute path inside the linuxserver/cura image
CURAENGINE_PATH = "/opt/cura/CuraEngine"
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
            if "Print time (s):" in line:
                print_time = float(line.split(":")[1].strip())
            if "Filament (mm^3):" in line:
                filament = float(line.split(":")[1].strip())

        if print_time is None or filament is None:
            return jsonify({"error": "Failed to parse CuraEngine output"}), 500

        return jsonify({
            "print_time_seconds": print_time,
            "filament_mm3": filament
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
