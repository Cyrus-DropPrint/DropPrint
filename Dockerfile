# FINAL DIAGNOSTIC V2: List all executables to find the right one

FROM ubuntu:22.04

# Install only the absolute minimum dependencies needed
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download, extract, and then LIST all potential executables
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract >/dev/null && \
    echo "########### LISTING EXECUTABLES ###########" && \
    ls -l /tmp/squashfs-root/usr/bin
