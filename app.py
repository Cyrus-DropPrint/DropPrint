import os
import tempfile
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)

# --- Configuration ---
PRUSASLICER_PATH = "./PrusaSlicer.AppImage"
PRINTER_PROFILE = "prusa_config.ini" # A simple config file for PrusaSlicer

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
        # The AppImage will automatically call the console version
        proc = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=290
        )

        if proc.returncode != 0:
            return jsonify({"error": "PrusaSlicer failed", "details": proc.stderr}), 500
        
        # PrusaSlicer prints estimated time to stderr, so we parse that
        print_time_seconds = 0
        lines = proc.stderr.splitlines()
        for line in lines:
            if "Estimated printing time (normal mode)" in line:
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
                break
        
        if print_time_seconds == 0:
            return jsonify({"error": "Failed to parse print time from PrusaSlicer output", "details": proc.stderr}), 500

        return jsonify({
            "print_time_seconds": print_time_seconds
            # Note: PrusaSlicer console doesn't easily output filament usage by default.
            # This would require more complex config and parsing.
        })

    except subprocess.TimeoutExpired:
        return jsonify({"error": "Slicing process timed out after 290 seconds"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        # Clean up the temporary files
        try:
            os.remove(stl_path)
            os.remove(output_gcode_path)
        except OSError:
            pass

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
