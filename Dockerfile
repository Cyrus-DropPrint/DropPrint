# Final Strategy: Use a multi-stage build to copy the official pre-built CuraEngine

# Stage 1: Get the pre-built CuraEngine from the official Ultimaker image
FROM ultimaker/cura-engine:latest as builder

# Stage 2: Build your final application image
FROM ubuntu:22.04

# Install only the runtime dependencies needed for your Python app
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
