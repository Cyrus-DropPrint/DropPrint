FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y curl unzip build-essential cmake git && \
    apt-get clean

# Download and install CuraEngine binary
RUN curl -L -o CuraEngine.zip https://github.com/Ultimaker/CuraEngine/releases/download/15.04.6/CuraEngine-15.04.6-linux.zip && \
    unzip CuraEngine.zip && \
    mv CuraEngine /usr/bin/CuraEngine && \
    chmod +x /usr/bin/CuraEngine && \
    rm CuraEngine.zip

# Create app directory
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py default_config.json .
# Add any other required files if needed
# Expose correct port for Render
EXPOSE 10000

# Run the app
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
