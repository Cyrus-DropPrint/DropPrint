import os
import tempfile
import uuid
from flask import Flask, request, jsonify, url_for
from celery_worker import run_slicing_job_task

app = Flask(__name__)

@app.route("/quote", methods=["POST"])
def submit_quote_job():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # Save the file to a temporary location that the worker can access.
    # Note: For production, a shared file store like AWS S3 is better.
    job_id = str(uuid.uuid4())
    stl_filename = f"{job_id}.stl"
    stl_path = os.path.join(tempfile.gettempdir(), stl_filename)
    file.save(stl_path)

    # Send the slicing task to the background Celery worker
    run_slicing_job_task.delay(job_id, stl_path)

    return jsonify({
        "job_id": job_id,
        "status": "queued",
        "status_url": url_for('get_job_status', job_id=job_id, _external=True)
    }), 202

@app.route("/status/<job_id>", methods=["GET"])
def get_job_status(job_id):
    # Check the status of the job from Celery's backend
    task = run_slicing_job_task.AsyncResult(job_id)
    
    response = {
        "job_id": job_id,
        "status": task.state
    }
    if task.state == 'SUCCESS':
        response['result'] = task.result
    elif task.state == 'FAILURE':
        response['error'] = str(task.info)

    return jsonify(response)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
