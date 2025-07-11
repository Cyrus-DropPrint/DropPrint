# FINAL ATTEMPT: Using a different pre-built image (with a specific version tag)

# --- Stage 1: Get the pre-built CuraEngine from a community image ---
FROM thopiekar/cura-slicer:5.7.2 as builder

# --- Stage 2: Build your final application ---
FROM ubuntu:22.04

# Install only the runtime dependencies for your Python app
RUN apt-get update && apt-get install -y \
    python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the pre-built CuraEngine executable from the first stage
# The path in this image is /usr/bin/cura-engine
COPY --from=builder /usr/bin/cura-engine /usr/local/bin/CuraEngine

# Make it executable
RUN chmod +x /usr/local/bin/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
