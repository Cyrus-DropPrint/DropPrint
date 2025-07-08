import os
import subprocess
import tempfile
import json
from flask import Flask, request, jsonify
from flask_cors import CORS  # <-- added for CORS

app = Flask(__name__)
CORS(app)  # <-- enable CORS for all routes

CURAENGINE_PATH = "/usr/bin/CuraEngine"
DEFAULT_CONFIG = "default_config.json"

PRICE_PER_METER = 0.10
PRICE_PER_HOUR = 2.00
SETUP_FEE = 1.00

def parse_gcode(file_path):
    time_sec = 0
    filament_mm = 0
    with open(file_path, 'r') as f:
        for line in f:
            if line.startswith(";TIME:"):
                time_sec = int(line.split(":")[1])
            if line.startswith(";Filament used [mm]:"):
                filament_mm = float(line.split(":")[1])
    return time_sec, filament_mm

@app.route('/quote', methods=['POST'])
def get_quote():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files['file']
    if not file.filename.endswith('.stl'):
        return jsonify({"error": "Only .stl files supported"}), 400

    with tempfile.TemporaryDirectory() as tmpdir:
        input_path = os.path.join(tmpdir, "input.stl")
        output_path = os.path.join(tmpdir, "output.gcode")
        file.save(input_path)

        result = subprocess.run([
            CURAENGINE_PATH,
            "slice",
            "-v",
            "-j", DEFAULT_CONFIG,
            "-l", input_path,
            "-o", output_path
        ], capture_output=True, text=True)

        if result.returncode != 0:
            return jsonify({"error": "Slicing failed", "details": result.stderr}), 500

        time_sec, filament_mm = parse_gcode(output_path)
        print_hours = time_sec / 3600
        price = filament_mm / 1000 * PRICE_PER_METER + print_hours * PRICE_PER_HOUR + SETUP_FEE

        return jsonify({
            "filament_mm": round(filament_mm, 2),
            "print_time_sec": time_sec,
            "price": round(price, 2)
        })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
