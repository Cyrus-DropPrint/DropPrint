import os
import tempfile
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)

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
            return jsonify({"error": "PrusaSlicer failed", "details": proc.stderr}), 500
        
        # --- PARSE G-CODE FILE FOR FILAMENT AND TIME ---
        print_time_seconds = None
        filament_length_mm = None

        with open(output_gcode_path, 'r') as gcode_file:
            for line in gcode_file:
                if "estimated printing time (normal mode)" in line:
                    # Format is "; estimated printing time (normal mode) = 1d 2h 3m 4s"
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
                    # Format is "; filament used [mm] = 1234.56"
                    filament_length_mm = float(line.split("= ")[1])
                
                # Stop reading if we have both values
                if print_time_seconds is not None and filament_length_mm is not None:
                    break
        
        if print_time_seconds is None or filament_length_mm is None:
            return jsonify({"error": "Failed to parse slicer output from G-code file", "details": proc.stderr}), 500

        return jsonify({
            "print_time_seconds": print_time_seconds,
            "filament_length_mm": filament_length_mm
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
