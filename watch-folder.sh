#!/bin/bash

WATCH_DIR="/watch"
OUTPUT_DIR="/output"
LOG_FILE="/logs/normalization.log"

PRESET_NAME="EBU"
TARGET_LOUDNESS="-25"
OUT_EXTENSION="mp4"
AUDIO_BITRATE="256k"
STANDARD="ebu"
SAMPLE_RATE="48000"
AUDIO_CODEC="aac"

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
