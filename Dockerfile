# Use a lightweight Python base image
FROM python:3.10-slim

ENV TZ="Europe/Budapest"

# Install system dependencies
RUN apt update && apt install -y ffmpeg bash

# Install ffmpeg-normalize inside a virtual environment
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir ffmpeg-normalize

# Set up working directory
WORKDIR /app

# Copy the watch folder script
COPY watch-folder.sh /app/

COPY config.env /app/

COPY index.html /app/

COPY websocat.x86_64-unknown-linux-musl /usr/local/bin/websocat

# Give execution permissions to the script
RUN chmod +x /app/watch-folder.sh

#RUN websocat -s 4981 &

#RUN python3 -m http.server 4980 &

EXPOSE 4980 4981

# Start the watcher script on container launch
CMD ["/app/watch-folder.sh"]
#CMD ["sh", "-c", "while true; do echo hello; sleep 1; done"]