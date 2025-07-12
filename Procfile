web: gunicorn --timeout 300 --bind 0.0.0.0:10000 app:app
worker: celery -A celery_worker.celery_app worker --loglevel=info
