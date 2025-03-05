# Use a lightweight Python base image
FROM python:3.11-slim

# Install system dependencies
RUN apt update && apt install -y ffmpeg

# Install ffmpeg-normalize inside a virtual environment
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir ffmpeg-normalize

# Set up working directory
WORKDIR /app

# Copy the watch folder script
COPY watch-folder.sh /app/

COPY config.env /app/

# Give execution permissions to the script
RUN chmod +x /app/watch-folder.sh

# Start the watcher script on container launch
CMD ["/app/watch-folder.sh"]