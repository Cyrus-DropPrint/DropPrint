# Final Strategy: Extract CuraEngine from the official 5.10.1 AppImage release

FROM ubuntu:22.04

# Install only the absolute minimum dependencies needed
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download the official Cura 5.10.1 AppImage, extract it, and copy out the CuraEngine binary
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract >/dev/null && \
    # Find the executable, copy it, and make it executable
    find /tmp/squashfs-root -name "UltiMaker-Cura-Engine" -exec cp {} /usr/local/bin/CuraEngine \; && \
    chmod +x /usr/local/bin/CuraEngine && \
    rm -rf /tmp/Cura.AppImage /tmp/squashfs-root

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
