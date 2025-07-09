# 1) Python base
FROM python:3.10-slim

# 2) Pull in minimal tools to grab and extract the AppImage
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      ca-certificates curl unzip && \
    rm -rf /var/lib/apt/lists/*

# 3) Download CuraEngine AppImage and extract the CLI binary
RUN curl -L -o /tmp/CuraEngine.AppImage \
     https://github.com/Ultimaker/CuraEngine/releases/download/5.4.1/CuraEngine-5.4.1-linux.AppImage && \
    chmod +x /tmp/CuraEngine.AppImage && \
    /tmp/CuraEngine.AppImage --appimage-extract && \
    mv squashfs-root/usr/bin/CuraEngine /usr/local/bin/CuraEngine && \
    rm -rf /tmp/CuraEngine.AppImage squashfs-root

# 4) Confirm it’s there (optional sanity check)
RUN [ -x /usr/local/bin/CuraEngine ]

# 5) Set up your Flask app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./

RUN pip install --no‑cache‑dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
