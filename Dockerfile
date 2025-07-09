FROM python:3.10-slim

# Install build tools
RUN apt-get update && \
    apt-get install -y git build-essential cmake && \
    apt-get clean

# Clone and build CuraEngine v15.04.6
RUN git clone --depth 1 --branch 15.04.6 https://github.com/Ultimaker/CuraEngine.git /curaengine && \
    mkdir /curaengine/build && \
    cd /curaengine/build && \
    cmake .. && \
    make && \
    mv CuraEngine /usr/bin/CuraEngine

WORKDIR /app

# Copy your application files
COPY app.py default_config.json requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 10000

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
