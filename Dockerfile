# FINAL DIAGNOSTIC: Find the exact path of the engine executable

FROM ubuntu:22.04

# Install only the absolute minimum dependencies needed
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download, extract, and then FIND the executable
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract >/dev/null && \
    echo "########### SEARCHING FOR CURA ENGINE ###########" && \
    find /tmp/squashfs-root -type f -name "*CuraEngine*"

# This Dockerfile is only for finding the path. It will not create a full app.
