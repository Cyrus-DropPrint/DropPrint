# FINAL BUILD: Installing CuraEngine directly from Ubuntu repositories

FROM ubuntu:22.04

# Install Python and the official cura-engine package
RUN apt-get update && apt-get install -y \
    cura-engine \
    python3 \
    python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup the Flask application
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port and set a long timeout for Gunicorn
EXPOSE 10000
CMD ["gunicorn", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
