# FINAL DIAGNOSTIC: List all files in the permanent directory

FROM ubuntu:22.04

# Install only the absolute minimum dependencies needed
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download, extract, move, and then LIST all files in the final location
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract >/dev/null && \
    # Move the entire extracted directory to a permanent location
    mv /tmp/squashfs-root /opt/cura && \
    # This is the debugging command to list all files
    echo "########### START OF FINAL FILE LIST ###########" && \
    ls -R /opt/cura && \
    echo "########### END OF FINAL FILE LIST ###########" && \
    # Clean up the downloaded AppImage
    rm /tmp/Cura.AppImage

# The Dockerfile will stop here after listing the files.
