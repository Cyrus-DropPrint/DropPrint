# FINAL STRATEGY: Multi-Stage Build to reliably extract the executable

# --- Stage 1: The Builder ---
# This stage's only job is to download and extract the AppImage
FROM ubuntu:22.04 as builder

RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage
RUN chmod +x /tmp/Cura.AppImage
RUN cd /tmp && ./Cura.AppImage --appimage-extract

# --- Stage 2: The Final Application ---
# This stage builds your actual application
FROM ubuntu:22.04

# Install only the runtime dependencies for Python
RUN apt-get update && apt-get install -y python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the CuraEngine executable from the builder stage
COPY --from=builder /tmp/squashfs-root/CuraEngine /usr/local/bin/CuraEngine

# Make it executable
RUN chmod +x /usr/local/bin/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
