#!/bin/bash

is_file_complete() {
  local file="$1"
  local prev_size=0
  local curr_size=1

  # Wait until the file size stops changing
  while [[ "$prev_size" -ne "$curr_size" ]]; do
    prev_size="$curr_size"
    sleep 2 # Adjust delay if needed
    curr_size=$(stat -c%s "$file" 2>/dev/null || echo 0)

    # If file disappears (deleted or moved), return false
    [[ "$curr_size" -eq 0 ]] && return 1
  done

  # Check if file is still open by another process
  if lsof "$file" >/dev/null 2>&1; then
    return 1 # File is still in use
  fi

  return 0 # File is ready
}

check_extension() {
  filename="$1"
  extension="${filename##*.}"
  extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
  [[ "$extension_lower" =~ ^($ALLOWED_INPUT_FORMATS)$ ]] && return 0 || return 1
}

##### START ####

mkdir -p "$WATCH_DIR"
mkdir -p "$WATCH_DIR2"
mkdir -p "$WATCH_DIR3"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR2"
mkdir -p "$OUTPUT_DIR3"

LOG_FILE="encode.log"

echo "$(date) - Watching directory: $WATCH_DIR for new files..." | tee -a "$LOG_FILE"
echo "$(date) - Watching directory: $WATCH_DIR2 for new files..." | tee -a "$LOG_FILE"
echo "$(date) - Watching directory: $WATCH_DIR3 for new files..." | tee -a "$LOG_FILE"

while true; do
  ############### watch dir 1 ##################
  for FILE in "$WATCH_DIR"/*; do
    if [[ -f "$FILE" ]] && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME}"

        echo "########## $(date) - Processing file: $FILE via $PRESET_NAME preset ##########" | tee -a "$LOG_FILE"
        out_path="${OUTPUT_DIR}/${out_basename}.${OUT_EXTENSION}"

        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION" -e="$VIDEO_OPTIONS" -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -v 2>&1 | tee -a "$LOG_FILE"
        else
          ffmpeg -i "$FILE" -c:v "$VIDEO_ENCODER" -b:v "$VIDEO_BITRATE" -r "$FRAME_RATE" -s "$RESOLUTION" -c:a copy "$out_path" -loglevel verbose 2>&1 | tee -a "$LOG_FILE"
        fi

        echo "########## $(date) - Finished processing: $out_path ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR/Source"
        mv "$FILE" "$WATCH_DIR/Source/"
      else
        echo "########## $(date) - File is still being written: $FILE ##########" | tee -a "$LOG_FILE"
        continue
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "########## $(date) - Not supported input format: $FILE ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR/Source"
        mv "$FILE" "$WATCH_DIR/Source/"
      fi
    fi
  done

  ############### watch dir 2 ##################
  for FILE in "$WATCH_DIR2"/*; do
    if [[ -f "$FILE" ]] && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME2}"

        echo "########## $(date) - Processing file: $FILE via $PRESET_NAME2 preset ##########" | tee -a "$LOG_FILE"
        out_path="${OUTPUT_DIR2}/${out_basename}.${OUT_EXTENSION2}"

        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        if [ -n "$AUDIO_STREAM" ]; then
          ffmpeg -i "$FILE" -an -c:v "$VIDEO_ENCODER2" -b:v "$VIDEO_BITRATE2" -r "$FRAME_RATE2" -s "$RESOLUTION2" "$out_path" -loglevel verbose 2>&1 | tee -a "$LOG_FILE"
        else
          ffmpeg -i "$FILE" -c:v "$VIDEO_ENCODER2" -b:v "$VIDEO_BITRATE2" -r "$FRAME_RATE2" -s "$RESOLUTION2" -c:a copy "$out_path" -loglevel verbose 2>&1 | tee -a "$LOG_FILE"
        fi

        echo "########## $(date) - Finished processing: $out_path ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR2/Source"
        mv "$FILE" "$WATCH_DIR2/Source/"
      else
        echo "########## $(date) - File is still being written: $FILE ##########" | tee -a "$LOG_FILE"
        continue
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "########## $(date) - Not supported input format: $FILE ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR2/Source"
        mv "$FILE" "$WATCH_DIR2/Source/"
      fi
    fi
  done

  ############### watch dir 3 ##################
  for FILE in "$WATCH_DIR3"/*; do
    if [[ -f "$FILE" ]] && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME3}"

        echo "########## $(date) - Processing file: $FILE via $PRESET_NAME3 preset ##########" | tee -a "$LOG_FILE"
        out_path="${OUTPUT_DIR3}/${out_basename}.${OUT_EXTENSION3}"

        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION3" -vn -c:a "$AUDIO_CODEC3" -b:a "$AUDIO_BITRATE3" -nt "$STANDARD3" -t "$TARGET_LOUDNESS3" --dual-mono -ar "$SAMPLE_RATE3" -v 2>&1 | tee -a "$LOG_FILE"
        else
          echo "########## $(date) - No audio stream found, can't output normalized audio file. ##########" | tee -a "$LOG_FILE"
        fi

        echo "########## $(date) - Finished processing: $out_path ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR3/Source"
        mv "$FILE" "$WATCH_DIR3/Source/"
      else
        echo "########## $(date) - File is still being written: $FILE ##########" | tee -a "$LOG_FILE"
        continue
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "########## $(date) - Not supported input format: $FILE ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR3/Source"
        mv "$FILE" "$WATCH_DIR3/Source/"
      fi
    fi
  done

  sleep 5
done
