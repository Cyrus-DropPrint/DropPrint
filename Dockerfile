# Use a lightweight Python base
FROM python:3.10-slim

# Install system dependencies required to build CuraEngine
RUN apt-get update && \
    apt-get install -y build-essential cmake git curl unzip && \
    apt-get clean

# Build CuraEngine from source
RUN git clone --depth 1 https://github.com/Ultimaker/CuraEngine.git /curaengine && \
    mkdir /curaengine/build && \
    cd /curaengine/build && \
    cmake .. && \
    make && \
    mv CuraEngine /usr/bin/CuraEngine

# Set working directory
WORKDIR /app

# Copy your Python app and config
COPY app.py default_config.json requirements.txt .  # make sure these are in your repo root

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port used by your Flask app
EXPOSE 10000

# Start the app using Gunicorn
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]

