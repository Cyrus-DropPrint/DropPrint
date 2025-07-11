# FINAL BUILD: Using a reliable image and a verified path

# --- Stage 1: The Builder ---
FROM linuxserver/cura:5.7.1 as builder

# --- Stage 2: The Final Application ---
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the pre-built executable from the correct path we discovered in the builder
COPY --from=builder /opt/cura/CuraEngine /usr/local/bin/CuraEngine

# Make it executable
RUN chmod +x /usr/local/bin/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./

# Install Python packages without the unsupported flag
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port and set a long timeout for Gunicorn
EXPOSE 10000
CMD ["gunicorn", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
