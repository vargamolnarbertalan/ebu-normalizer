# Use a lightweight Python base image
FROM python:3.12-alpine

# Set environment variables
ENV TZ=Europe/Budapest \ 
    WATCH_DIR1=/watch1 \
    OUTPUT_DIR1=/watch1/Output \
    PRESET_NAME1=EBUp50 \
    TARGET_LOUDNESS1=-23 \
    OUT_EXTENSION1=mp4 \
    AUDIO_BITRATE1=256k \
    STANDARD1=ebu \
    SAMPLE_RATE1=48000 \
    AUDIO_CODEC1=aac \
    VIDEO_ENCODER1=libx264 \
    VIDEO_BITRATE1=10000k \
    FRAME_RATE1=50 \
    WIDTH1=1920 \
    HEIGHT1=1080 \
    NORMALIZE1=both \
    WATCH_DIR2=/watch2 \
    OUTPUT_DIR2=/watch2/Output \
    PRESET_NAME2=MUTEp50 \
    OUT_EXTENSION2=mp4 \
    VIDEO_ENCODER2=libx264 \
    VIDEO_BITRATE2=10000k \
    FRAME_RATE2=50 \
    WIDTH2=1920 \
    HEIGHT2=1080 \
    NORMALIZE2=vonly \
    WATCH_DIR3=/watch3 \
    OUTPUT_DIR3=/watch3/Output \
    PRESET_NAME3=audioEBU \
    TARGET_LOUDNESS3=-23 \
    OUT_EXTENSION3=mp3 \
    AUDIO_BITRATE3=256k \
    STANDARD3=ebu \
    SAMPLE_RATE3=48000 \
    AUDIO_CODEC3=libmp3lame \
    NORMALIZE3=aonly \
    WATCH_DIR4=/watch4 \
    OUTPUT_DIR4=/watch4/Output \
    PRESET_NAME4=EBUp60 \
    TARGET_LOUDNESS4=-23 \
    OUT_EXTENSION4=mp4 \
    AUDIO_BITRATE4=256k \
    STANDARD4=ebu \
    SAMPLE_RATE4=48000 \
    AUDIO_CODEC4=aac \
    VIDEO_ENCODER4=libx264 \
    VIDEO_BITRATE4=10000k \
    FRAME_RATE4=60 \
    WIDTH4=1920 \
    HEIGHT4=1080 \
    NORMALIZE4=both \
    WATCH_DIR5=/watch5 \
    OUTPUT_DIR5=/watch5/Output \
    PRESET_NAME5=MUTEp60 \
    OUT_EXTENSION5=mp4 \
    VIDEO_ENCODER5=libx264 \
    VIDEO_BITRATE5=10000k \
    FRAME_RATE5=60 \
    WIDTH5=1920 \
    HEIGHT5=1080 \
    NORMALIZE5=vonly \
    ALLOWED_INPUT_FORMATS=mp4|webm|flv|ogg|gif|wmv|mts|m2ts|ts|m4v|mpg|mpeg|m4v|3gp|mxf|mkv|avi|mov|wav|aac|aiff|flac|mp3|mogg|wma

# Install system dependencies
RUN apk add --no-cache \
    bash \
    ffmpeg \
    tzdata \
    libstdc++ \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev

# Set timezone
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo "${TZ}" > /etc/timezone

# Create virtual environment and install Python packages
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /app/venv/bin/pip install ffmpeg-normalize

# Install aiohttp globally
RUN pip install --no-cache-dir aiohttp

# Set up working directory
WORKDIR /app

# Copy needed files
COPY watch-folder.sh index.html encode.log server.py start.sh /app/

# Give execution permissions to the script
RUN chmod +x /app/*

EXPOSE 80

# Start the http server and the watcher script on container launch
ENTRYPOINT ["./start.sh"]