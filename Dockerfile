# FINAL STRATEGY: Multi-Stage Build with the Correct, Verified Path

# --- Stage 1: The Builder ---
FROM linuxserver/cura:5.7.1 as builder

# --- Stage 2: The Final Application ---
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the pre-built executable from the correct path we discovered
COPY --from=builder /opt/cura/CuraEngine /usr/local/bin/CuraEngine

# Make it executable
RUN chmod +x /usr/local/bin/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
