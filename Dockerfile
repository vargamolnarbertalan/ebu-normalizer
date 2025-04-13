# Use a lightweight Python base image
FROM python:3.10-slim

# Set environment variables
ENV TZ=Europe/Budapest \ 
    WATCH_DIR=/watch \
    OUTPUT_DIR=/output \
    LOG_FILE=/logs/normalization.log \
    PRESET_NAME=EBU \
    TARGET_LOUDNESS=-25 \
    OUT_EXTENSION=mp4 \
    AUDIO_BITRATE=256k \
    STANDARD=ebu \
    SAMPLE_RATE=48000 \
    AUDIO_CODEC=aac \
    VIDEO_ENCODER=libx264 \
    VIDEO_BITRATE=10000k \
    FRAME_RATE=60000/1001 \
    RESOLUTION=1920x1080 \
    WATCH_DIR2=/watch2 \
    OUTPUT_DIR2=/output \
    LOG_FILE2=/logs/normalization2.log \
    PRESET_NAME2=MUTE \
    OUT_EXTENSION2=mp4 \
    VIDEO_ENCODER2=libx264 \
    VIDEO_BITRATE2=10000k \
    FRAME_RATE2=60000/1001 \
    RESOLUTION2=1920x1080 \
    WATCH_DIR3=/watch3 \
    OUTPUT_DIR3=/output \
    LOG_FILE3=/logs/normalization3.log \
    PRESET_NAME3=audioEBU \
    TARGET_LOUDNESS3=-25 \
    OUT_EXTENSION3=mp3 \
    AUDIO_BITRATE3=256k \
    STANDARD3=ebu \
    SAMPLE_RATE3=48000 \
    AUDIO_CODEC3=libmp3lame \
    ALLOWED_INPUT_FORMATS=mp4|webm|flv|ogg|gif|wmv|mts|m2ts|ts|m4v|mpg|mpeg|m4v|3gp|mxf|mkv|avi|mov|wav|aac|aiff|flac|mp3|mogg|wma

# Install system dependencies
RUN apt update && apt install -y ffmpeg bash

# Install ffmpeg-normalize inside a virtual environment
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir ffmpeg-normalize

RUN pip install aiohttp

# Set up working directory
WORKDIR /app

# Copy the watch folder script
COPY watch-folder.sh /app/

COPY index.html /app/

COPY server.py /app/

COPY websocat.x86_64-unknown-linux-musl /usr/local/bin/websocat

# Give execution permissions to the script
RUN chmod +x /app/watch-folder.sh

RUN chmod +x /app/server.py

#RUN websocat -s 4981 &

#RUN python3 -m http.server 443 &

EXPOSE 443

# Start the watcher script on container launch
#CMD ["/app/watch-folder.sh"]
#CMD ["sh", "-c", "while true; do echo hello; sleep 1; done"]
CMD ["python3", "-u", "server.py"]