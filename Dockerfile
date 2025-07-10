# Final Build: Using the exact executable path discovered from the logs

FROM ubuntu:22.04

# Install only the absolute minimum dependencies needed
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download the official Cura 5.10.1 AppImage, extract it, and copy out the engine
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract >/dev/null && \
    # This is the corrected copy command using the path we discovered from the logs
    cp /tmp/squashfs-root/CuraEngine /usr/local/bin/CuraEngine && \
    # Make it executable
    chmod +x /usr/local/bin/CuraEngine && \
    # Clean up
    rm -rf /tmp/Cura.AppImage /tmp/squashfs-root

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
