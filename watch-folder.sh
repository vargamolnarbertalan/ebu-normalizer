#!/bin/bash
source config.env

WATCH_DIR=$(echo -n "$WATCH_DIR" | tr -d '\r')
OUTPUT_DIR=$(echo -n "$OUTPUT_DIR" | tr -d '\r')
LOG_FILE=$(echo -n "$LOG_FILE" | tr -d '\r')
PRESET_NAME=$(echo -n "$PRESET_NAME" | tr -d '\r')
TARGET_LOUDNESS=$(echo -n "$TARGET_LOUDNESS" | tr -d '\r')
OUT_EXTENSION=$(echo -n "$OUT_EXTENSION" | tr -d '\r')
AUDIO_BITRATE=$(echo -n "$AUDIO_BITRATE" | tr -d '\r')
STANDARD=$(echo -n "$STANDARD" | tr -d '\r')
SAMPLE_RATE=$(echo -n "$SAMPLE_RATE" | tr -d '\r')
AUDIO_CODEC=$(echo -n "$AUDIO_CODEC" | tr -d '\r')

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date) - Watching directory: $WATCH_DIR for new files..." | tee -a "$LOG_FILE"

while true; do
  for FILE in "$WATCH_DIR"/*; do
    if [[ -f "$FILE" ]]; then

      filename=$(basename "$FILE")
      in_basename="${filename%.*}"
      out_basename="${in_basename}_encoded_${PRESET_NAME}"

      echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE"
      #echo "Input file basename: $in_basename"
      #echo "Output file basename: $out_basename"
      out_path="${OUTPUT_DIR}/${out_basename}.${OUT_EXTENSION}"

      #echo "Output path: $out_path"

      /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION" -c:v copy -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -d -v | tee -a "$LOG_FILE"

      echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE"

      # move file
      mkdir -p "$WATCH_DIR/_original"
      mv "$FILE" "$WATCH_DIR/_original/"

    fi
  done
  sleep 5 # Wait 5 seconds before checking again
done
