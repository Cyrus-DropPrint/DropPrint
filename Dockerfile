FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    git build-essential cmake libboost-all-dev libeigen3-dev \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch 5.0.0 https://github.com/Ultimaker/CuraEngine.git /tmp/CuraEngine

RUN mkdir /tmp/CuraEngine/build && cd /tmp/CuraEngine/build && \
    cmake .. && \
    make VERBOSE=1

RUN cp /tmp/CuraEngine/build/CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine

RUN rm -rf /tmp/CuraEngine

WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]

