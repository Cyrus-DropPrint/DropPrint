FROM python:3.10-slim

# Install build tools and dependencies
RUN apt-get update && \
    apt-get install -y git build-essential cmake && \
    apt-get clean

# Clone legacy CuraEngine branch and build
RUN git clone --depth 1 --branch legacy https://github.com/Ultimaker/CuraEngine.git /curaengine && \
    mkdir /curaengine/build && \
    cd /curaengine/build && \
    cmake .. && \
    make && \
    mv CuraEngine /usr/bin/CuraEngine

WORKDIR /app

# Copy app files
COPY app.py default_config.json requirements.txt .

# Install python deps
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 10000

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
