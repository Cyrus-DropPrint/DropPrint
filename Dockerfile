# FINAL BUILD: Running the application inside the working Cura image

FROM linuxserver/cura:5.7.1

# The linuxserver images are based on Ubuntu.
# Install Python and Pip.
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up the application directory
WORKDIR /app

# --- THIS IS THE CORRECTED LINE ---
# Copy ALL your application files, including the new worker and Procfile
COPY app.py celery_worker.py Procfile prusa_config.ini requirements.txt ./

# Install Python packages
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Expose the port
EXPOSE 10000

# The Procfile will be used by Koyeb to start the web and worker processes,
# so the CMD is not strictly necessary but is good practice.
CMD ["gunicorn", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
