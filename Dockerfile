FROM python:3.10-slim

# Install system packages and CuraEngine from Debian
RUN apt-get update && \
    apt-get install -y cura-engine unzip && \
    apt-get clean

# At this point /usr/bin/curaengine (lowercase) is available
# Create a symlink to match uppercase usage in your code
RUN ln -s /usr/bin/curaengine /usr/bin/CuraEngine

WORKDIR /app

# Copy your application files
COPY app.py default_config.json requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port your app will listen on
EXPOSE 10000

# Start with Gunicorn on port 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
