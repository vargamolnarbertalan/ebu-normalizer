#!/bin/bash

WATCH_DIR="/watch"
OUTPUT_DIR="/output"
LOG_FILE="/logs/normalization.log"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date) - Watching directory: $WATCH_DIR for new files..." | tee -a "$LOG_FILE"

while true; do
  for FILE in "$WATCH_DIR"/*; do
    if [[ -f "$FILE" ]]; then
      EXT="${FILE##*.}"
      BASENAME=$(basename "$FILE")

      echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE"

      /app/venv/bin/ffmpeg-normalize "$FILE" \
        -o "$OUTPUT_DIR/$BASENAME" \
        -ext "$EXT" \
        -c:v copy -c:a aac -b:a 256k \
        -nt ebu -t -25 --dual-mono -ar 48000 \
        | tee -a "$LOG_FILE"


      echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE"


        # Optional: Remove processed file after it's handled, with check
        if [ -f "$FILE" ]; then
        rm "$FILE"
        else
        echo "File not found: $FILE"
        fi

    fi
  done
  sleep 5  # Wait 5 seconds before checking again
done