# FINAL STRATEGY: Multi-Stage Build with a verified LinuxServer.io image

# --- Stage 1: The Builder ---
# This stage uses a reliable, community-verified image
FROM linuxserver/cura:5.7.1 as builder

# --- Stage 2: The Final Application ---
FROM ubuntu:22.04

# Install only the runtime dependencies for Python
RUN apt-get update && apt-get install -y \
    python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the pre-built CuraEngine executable from the first stage
# The path in this image is /usr/bin/CuraEngine
COPY --from=builder /usr/bin/CuraEngine /usr/local/bin/CuraEngine

# Make it executable
RUN chmod +x /usr/local/bin/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
