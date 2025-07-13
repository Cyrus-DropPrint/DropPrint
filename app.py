import os
import json
import tempfile
import subprocess
import math # Needed for filament calculation
from flask import Flask, request, jsonify

# --- Firebase Admin SDK Setup ---
import firebase_admin
from firebase_admin import credentials, storage

# Load the secret key from Koyeb's environment variables
firebase_creds_json = os.environ.get('FIREBASE_CREDENTIALS')
if firebase_creds_json:
    creds_dict = json.loads(firebase_creds_json)
    cred = credentials.Certificate(creds_dict)
    # Check if the app is already initialized to prevent errors on reload
    if not firebase_admin._apps:
        # --- MODIFICATION: Using the correct bucket name for your project ---
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'dropprint-31d26.firebasestorage.app'
        })
else:
    print("FATAL ERROR: FIREBASE_CREDENTIALS secret not found.")

app = Flask(__name__)

# --- Configuration ---
PRUSASLICER_PATH = "./PrusaSlicer.AppImage"
PRINTER_PROFILE = "prusa_config.ini" 

@app.route('/')
def home():
    return "PrusaSlicer API with Firebase Integration is running."

@app.route("/slice", methods=["POST"])
def get_quote():
    data = request.get_json()

    if not data or 'storagePath' not in data:
        return jsonify({"error": "Missing 'storagePath' in request body"}), 400

    storage_path = data.get('storagePath')
    print(f"Received request to slice file from Firebase Storage: {storage_path}")

    with tempfile.NamedTemporaryFile(delete=False, suffix=".stl") as tmp_stl, \
         tempfile.NamedTemporaryFile(delete=False, suffix=".gcode") as tmp_gcode:
        stl_path = tmp_stl.name
        output_gcode_path = tmp_gcode.name

    try:
        # Get the bucket. It now knows the name from the initialization step.
        bucket = storage.bucket() 
        blob = bucket.blob(storage_path)
        
        print(f"Downloading to temporary path: {stl_path}")
        blob.download_to_filename(stl_path)
        print("Download complete.")

        print("Starting PrusaSlicer...")
        command = [
            PRUSASLICER_PATH,
            "--export-gcode",
            "--load", PRINTER_PROFILE,
            "-o", output_gcode_path,
            stl_path
        ]

        proc = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=290
        )

        if proc.returncode != 0:
            print(f"PrusaSlicer failed. Stderr: {proc.stderr}")
            return jsonify({"error": "PrusaSlicer failed", "details": proc.stderr}), 500
        
        print("PrusaSlicer finished successfully. Parsing G-code...")
        
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
            return jsonify({"error": "Failed to parse slicer output from G-code file"}), 500

        filament_diameter_mm = 1.75
        filament_density_g_cm3 = 1.24
        radius_cm = (filament_diameter_mm / 2) / 10
        length_cm = filament_length_mm / 10
        volume_cm3 = math.pi * (radius_cm ** 2) * length_cm
        filament_used_g = volume_cm3 * filament_density_g_cm3
        
        print(f"Calculation complete. Grams: {filament_used_g:.2f}, Seconds: {print_time_seconds}")

        return jsonify({
            "filament_used_g": round(filament_used_g, 2),
            "print_time_sec": int(print_time_seconds)
        })

    except subprocess.TimeoutExpired:
        return jsonify({"error": "Slicing process timed out after 290 seconds"}), 500
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"error": "An unexpected error occurred on the server.", "details": str(e)}), 500
    finally:
        print("Cleaning up temporary files.")
        try:
            os.remove(stl_path)
            os.remove(output_gcode_path)
        except OSError as e:
            print(f"Error removing temp files: {e}")
            pass

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)

