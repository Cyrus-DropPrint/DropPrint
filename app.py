import os
import tempfile
import subprocess
from flask import Flask, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from models import Base, SlicingJob  # your model file

DATABASE_URL = "sqlite:///slicing_jobs.db"
engine = create_engine(DATABASE_URL)
Base.metadata.create_all(engine)
Session = sessionmaker(bind=engine)
db_session = Session()

app = Flask(__name__)

# --- Config ---
PRUSASLICER_PATH = "./PrusaSlicer.AppImage"
PRINTER_PROFILE = "prusa_config.ini"

UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'stl'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# === Upload endpoint ===
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Empty filename"}), 400
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(save_path)
        public_url = f"https://overseas-gwenette-3dmodelslicer-6c28fb6a.koyeb.app/static/uploads/{filename}"
        return jsonify({"url": public_url})
    else:
        return jsonify({"error": "Invalid file type"}), 400

# === Serve uploaded files ===
@app.route('/static/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# === Slicing endpoint ===
@app.route("/quote", methods=["POST"])
def get_quote():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # Save uploaded STL temporarily
    with tempfile.NamedTemporaryFile(delete=False, suffix=".stl") as tmp_stl:
        file.save(tmp_stl.name)
        stl_path = tmp_stl.name

    output_gcode_path = tempfile.NamedTemporaryFile(delete=False, suffix=".gcode").name

    # Create DB job
    new_job = SlicingJob(filename=file.filename, status="processing")
    db_session.add(new_job)
    db_session.commit()
    job_id = new_job.id

    try:
        command = [
            PRUSASLICER_PATH,
            "--export-gcode",
            "--load", PRINTER_PROFILE,
            "-o", output_gcode_path,
            stl_path
        ]
        proc = subprocess.run(command, capture_output=True, text=True, timeout=290)
        if proc.returncode != 0:
            new_job.status = "error"
            db_session.commit()
            return jsonify({"error": "PrusaSlicer failed", "details": proc.stderr}), 500

        print_time_seconds = None
        filament_length_mm = None

        with open(output_gcode_path, 'r') as gcode_file:
            for line in gcode_file:
                if "estimated printing time (normal mode)" in line:
                    time_str = line.split("= ")[1]
                    days, hours, minutes, seconds = 0, 0, 0, 0
                    if "d" in t


