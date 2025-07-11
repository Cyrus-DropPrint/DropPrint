import os
import tempfile
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)

# Use the AppImage as the executable
CURAENGINE_PATH = "/app/Cura.AppImage"
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
        # Construct the command to be passed to the AppImage
        # The "--" is crucial. It tells the AppImage to pass all subsequent arguments
        # directly to its internal CuraEngine command.
        command_to_run = [
            CURAENGINE_PATH,
            "--",
            "slice",
            "-v",
            "-j", PRINTER_PROFILE,
            "-l", stl_path,
            "-o", output_gcode
        ]

        # Run the AppImage with the slice command
        proc = subprocess.run(command_to_run, capture_output=True, text=True)

        if proc.returncode != 0:
            return jsonify({"error": "CuraEngine failed inside AppImage", "details": proc.stderr}), 500

        print_time = None
        filament = None

        # Parse output for print time and filament
        for line in proc.stdout.splitlines():
            if "Print time (s):" in line:
                try:
                    print_time = float(line.split(":")[1].strip())
                except ValueError:
                    pass
            if "Filament (mm^3):" in line:
                try:
                    filament = float(line.split(":")[1].strip())
                except ValueError:
                    pass

        if print_time is None or filament is None:
            return jsonify({"error": "Failed to parse CuraEngine output"}), 500

        return jsonify({
            "print_time_seconds": print_time,
            "filament_mm3": filament
        })

    finally:
        # Cleanup temp files
        try:
            os.remove(stl_path)
            os.remove(output_gcode)
        except Exception:
            pass

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
