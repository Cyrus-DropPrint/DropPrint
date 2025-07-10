# Strategy 3: Use a multi-stage build to copy a pre-built CuraEngine

# Stage 1: Get the pre-built CuraEngine from a public image
FROM jlesage/cura-novnc:latest as builder
# The engine is located at /usr/bin/CuraEngine in this image

# Stage 2: Build your final application image
FROM ubuntu:22.04

# Install only the runtime dependencies needed
RUN apt-get update && apt-get install -y \
    python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the pre-built CuraEngine executable from the first stage
COPY --from=builder /usr/bin/CuraEngine /usr/local/bin/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
