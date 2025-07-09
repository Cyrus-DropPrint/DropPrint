FROM python:3.10-slim

# Install CuraEngine and other packages
RUN apt-get update && \
    apt-get install -y cura-engine unzip && \
    apt-get clean

# Symlink lowercase curaengine to the expected uppercase path
RUN ln -sf /usr/bin/curaengine /usr/bin/CuraEngine

WORKDIR /app

COPY app.py default_config.json requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 10000

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
