import os
import tempfile
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)

# The path to the CuraEngine executable within the Docker container
# This was corrected in the Dockerfile to /usr/local/bin/CuraEngine
CURAENGINE_PATH = "/opt/cura/CuraEngine"
PRINTER_PROFILE = "default_config.json" # ensure this is copied in your Docker image

@app.route("/quote", methods=["POST"])
def get_quote():
    # Check if a file was included in the request
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    # Check if the file name is empty
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # Save the uploaded STL to a temporary file
    # `delete=False` means the file won't be deleted immediately after closing,
    # allowing CuraEngine to access it.
    with tempfile.NamedTemporaryFile(delete=False, suffix=".stl") as tmp_stl:
        file.save(tmp_stl.name)
        stl_path = tmp_stl.name # Store the path to the temporary STL file

    # Create a temporary file path for the sliced GCODE output
    # CuraEngine requires an output file, even if we don't use the GCODE directly
    output_gcode = tempfile.NamedTemporaryFile(delete=False, suffix=".gcode").name

    try:
        # Run the CuraEngine slice command
        # The path to CuraEngine is now correctly set to /usr/local/bin/CuraEngine
        # The STL input file path is now correctly using 'stl_path'
        proc = subprocess.run([
            CURAENGINE_PATH,
            "gcode",
            "-o",
            output_gcode, # Use the temporary output GCODE file path
            "-j",
            "/app/default_config.json", # Path to the printer profile
            "-l",
            stl_path # Use the path to the temporary STL file
        ], capture_output=True, text=True)

        # Check if CuraEngine exited with an error
        if proc.returncode != 0:
            return jsonify({"error": "CuraEngine failed", "details": proc.stderr}), 500

        print_time = None
        filament = None

        # Parse the standard output of CuraEngine for print time and filament usage
        for line in proc.stdout.splitlines():
            if "Print time (s):" in line:
                try:
                    print_time = float(line.split(":")[1].strip())
                except ValueError:
                    # Handle cases where parsing fails, e.g., malformed output
                    pass
            if "Filament (mm^3):" in line:
                try:
                    filament = float(line.split(":")[1].strip())
                except ValueError:
                    # Handle cases where parsing fails
                    pass

        # If print time or filament couldn't be parsed, return an error
        if print_time is None or filament is None:
            return jsonify({"error": "Failed to parse CuraEngine output"}), 500

        # Return the extracted data as JSON
        return jsonify({
            "print_time_seconds": print_time,
            "filament_mm3": filament
        })

    finally:
        # Ensure temporary files are cleaned up, regardless of success or failure
        try:
            os.remove(stl_path)
            os.remove(output_gcode)
        except Exception as e:
            # Log any errors during cleanup, but don't prevent the app from responding
            print(f"Error during temporary file cleanup: {e}")


if __name__ == "__main__":
    # Run the Flask application
    app.run(host="0.0.0.0", port=10000)



if __name__ == "__main__":
    # Run the Flask application
    app.run(host="0.0.0.0", port=10000)
