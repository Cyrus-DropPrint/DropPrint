# Debugging Build: List all files to find the correct engine name

FROM ubuntu:22.04

# Install only the absolute minimum dependencies needed
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download the official Cura 5.10.1 AppImage, extract it, and list its contents
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract >/dev/null && \
    # This is the debugging command to list all files
    ls -R /tmp/squashfs-root && \
    # The copy command below will fail, which is expected for this step
    find /tmp/squashfs-root -name "This_Will_Fail" -exec cp {} /usr/local/bin/CuraEngine \;

# The rest of the Dockerfile is not needed for this test, as the build will fail above.
