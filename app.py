import os
import tempfile
import uuid
from flask import Flask, request, jsonify, url_for
from flask_sqlalchemy import SQLAlchemy
from celery_worker import run_slicing_job_task

app = Flask(__name__)

# --- Database Configuration ---
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

# --- Database Model ---
class Job(db.Model):
    id = db.Column(db.String(36), primary_key=True)
    status = db.Column(db.String(20), nullable=False, default="processing")
    print_time = db.Column(db.Float, nullable=True)
    filament_mm = db.Column(db.Float, nullable=True)
    error_message = db.Column(db.Text, nullable=True)

with app.app_context():
    db.create_all()

@app.route("/quote", methods=["POST"])
def submit_quote_job():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    with tempfile.NamedTemporaryFile(delete=False, suffix=".stl") as tmp_stl:
        file.save(tmp_stl.name)
        stl_path = tmp_stl.name
    
    job_id = str(uuid.uuid4())
    
    # Create and save the new job in the database
    new_job = Job(id=job_id, status="queued")
    db.session.add(new_job)
    db.session.commit()

    # Send the slicing task to the background Celery worker
    run_slicing_job_task.delay(job_id, stl_path)

    return jsonify({
        "job_id": job_id,
        "status": "queued",
        "status_url": url_for('get_job_status', job_id=job_id, _external=True)
    }), 202

@app.route("/status/<job_id>", methods=["GET"])
def get_job_status(job_id):
    job = db.session.get(Job, job_id)
    if not job:
        return jsonify({"error": "Job not found"}), 404
    
    response = {"job_id": job.id, "status": job.status}
    if job.status == "completed":
        response["result"] = {
            "print_time_seconds": job.print_time,
            "filament_length_mm": job.filament_mm
        }
    elif job.status == "failed":
        response["error"] = job.error_message
        
    return jsonify(response)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
