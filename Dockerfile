FROM python:3.10-slim

# Install system packages
RUN apt-get update && \
    apt-get install -y curl unzip && \
    apt-get clean

# Download and install CuraEngine v15.04.6
RUN curl -L -o CuraEngine.zip https://github.com/Ultimaker/CuraEngine/releases/download/15.04.6/CuraEngine-15.04.6-linux.zip && \
    unzip CuraEngine.zip && \
    mv CuraEngine /usr/bin/CuraEngine && \
    chmod +x /usr/bin/CuraEngine && \
    rm CuraEngine.zip

WORKDIR /app

# Copy your application files
COPY app.py default_config.json requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 10000

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
