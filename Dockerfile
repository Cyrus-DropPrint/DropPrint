# FINAL BUILD: Running the application inside the working Cura image

FROM linuxserver/cura:5.7.1

# The linuxserver images are based on Ubuntu, so we can use apt-get.
# Install Python and Pip.
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up the application directory
WORKDIR /app

# Copy your application files
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port and set a long timeout for Gunicorn
EXPOSE 10000
CMD ["gunicorn", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
