import os
import subprocess
import uuid
from flask import Flask, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename

app = Flask(__name__)

UPLOAD_FOLDER = 'static/uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
ALLOWED_EXTENSIONS = {'stl'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        unique_filename = f"{uuid.uuid4().hex}_{filename}"
        file_path = os.path.join(UPLOAD_FOLDER, unique_filename)
        file.save(file_path)

        public_url = f"https://YOUR-SUBDOMAIN.koyeb.app/static/uploads/{unique_filename}"
        return jsonify({'url': public_url}), 200

    return jsonify({'error': 'Invalid file type'}), 400

@app.route('/static/uploads/<path:filename>')
def serve_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

@app.route('/slice', methods=['POST'])
def slice_file():
    data = request.get_json()
    stl_url = data.get('stl_url')
    print_settings = data.get('print_settings', {})  # optional, not required for now

    if not stl_url or not stl_url.endswith('.stl'):
        return jsonify({'error': 'Invalid STL URL'}), 400

    try:
        filename = os.path.basename(stl_url)
        local_path = os.path.join(UPLOAD_FOLDER, filename)

        # Download STL file if not already present
        if not os.path.exists(local_path):
            subprocess.run(["wget", stl_url, "-O", local_path], check=True)

        # Run PrusaSlicer and output G-code
        gcode_path = os.path.join(UPLOAD_FOLDER, filename.replace('.stl', '.gcode'))
        command = [
            "./PrusaSlicer.AppImage",
            "--export-gcode",
            "--load", "prusa_config.ini",
            "--output", gcode_path,
            local_path
        ]
        subprocess.run(command, check=True)

        # Analyze G-code
        analysis = subprocess.run(
            ["./PrusaSlicer.AppImage", "--info", gcode_path],
            capture_output=True, text=True, check=True
        )

        info = {}
        for line in analysis.stdout.splitlines():
            if ":" in line:
                key, val = line.split(":", 1)
                info[key.strip()] = val.strip()

        return jsonify({
            "filament_used_mm": float(info.get("Filament used [mm]", 0)),
            "filament_used_g": float(info.get("Filament used [g]", 0)),
            "print_time_sec": int(info.get("Estimated printing time (normal mode)", "0").split()[0]),
            "estimated_cost_usd": round(float(info.get("Filament cost", "0").replace("$", "")), 2)
        }), 200

    except subprocess.CalledProcessError as e:
        return jsonify({'error': 'Slicing failed', 'details': e.stderr}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=10000)


