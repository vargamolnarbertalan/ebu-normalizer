#!/bin/bash

VIDEO_OPTIONS="-c:v ${VIDEO_ENCODER} -b:v ${VIDEO_BITRATE} -r ${FRAME_RATE} -vf scale=w=${WIDTH}:h=${HEIGHT}:force_original_aspect_ratio=decrease"
VIDEO_OPTIONS2="-c:v ${VIDEO_ENCODER2} -b:v ${VIDEO_BITRATE2} -r ${FRAME_RATE2} -vf scale=w=${WIDTH2}:h=${HEIGHT2}:force_original_aspect_ratio=decrease"

is_temp_file() {
  local file="$1"
  case "$file" in
    *.crdownload|*.part|*.download|*.opdownload|*.tmp|*.temp|*.~|*~|*.swp|*.swo|*.bak|*.filepart|*.partial|*.downloading|*.incomplete)
      return 0 ;;  # It's a temp file
    *)
      return 1 ;;  # It's safe to process
  esac
}

is_file_complete() {
  local file="$1"
  local prev_size=0
  local curr_size=0
  local stable_count=0
  local required_stable_count=3  # Number of stable checks before considering file complete

  while true; do
    if [[ ! -f "$file" ]]; then
      return 1 # File no longer exists
    fi

    curr_size=$(stat -c%s "$file" 2>/dev/null || echo 0)

    if [[ "$curr_size" -eq "$prev_size" ]]; then
      ((stable_count++))
    else
      stable_count=0
    fi

    # File has been stable long enough
    if [[ "$stable_count" -ge "$required_stable_count" ]]; then
      return 0
    fi

    prev_size="$curr_size"
    sleep 2
  done
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
    if [[ -f "$FILE" ]] && ! is_temp_file "$FILE" && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME}"

        echo "########## $(date) - Processing file: $FILE via $PRESET_NAME preset ##########" | tee -a "$LOG_FILE"
        out_path="${OUTPUT_DIR}/${out_basename}.${OUT_EXTENSION}"

        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION" -e="$VIDEO_OPTIONS" -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -q
        else
          ffmpeg -i "$FILE" $VIDEO_OPTIONS -c:a copy "$out_path" -loglevel fatal
        fi

        echo "########## $(date) - Finished processing: $out_path ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR/Source"
        mv "$FILE" "$WATCH_DIR/Source/"
      else
        echo "########## $(date) - File is still being written: $FILE ##########" | tee -a "$LOG_FILE"
        continue
      fi
    else
      if [[ -f "$FILE" ]] && ! is_temp_file "$FILE"; then
        echo "########## $(date) - Not supported input format: $FILE ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR/Source"
        mv "$FILE" "$WATCH_DIR/Source/"
      fi
    fi
  done

  ############### watch dir 2 ##################
  for FILE in "$WATCH_DIR2"/*; do
    if [[ -f "$FILE" ]] && ! is_temp_file "$FILE" && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME2}"

        echo "########## $(date) - Processing file: $FILE via $PRESET_NAME2 preset ##########" | tee -a "$LOG_FILE"
        out_path="${OUTPUT_DIR2}/${out_basename}.${OUT_EXTENSION2}"

        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        if [ -n "$AUDIO_STREAM" ]; then
          ffmpeg -i "$FILE" -an $VIDEO_OPTIONS2 "$out_path" -loglevel fatal
        else
          ffmpeg -i "$FILE" $VIDEO_OPTIONS2 -c:a copy "$out_path" -loglevel fatal
        fi

        echo "########## $(date) - Finished processing: $out_path ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR2/Source"
        mv "$FILE" "$WATCH_DIR2/Source/"
      else
        echo "########## $(date) - File is still being written: $FILE ##########" | tee -a "$LOG_FILE"
        continue
      fi
    else
      if [[ -f "$FILE" ]] && ! is_temp_file "$FILE"; then
        echo "########## $(date) - Not supported input format: $FILE ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR2/Source"
        mv "$FILE" "$WATCH_DIR2/Source/"
      fi
    fi
  done

  ############### watch dir 3 ##################
  for FILE in "$WATCH_DIR3"/*; do
    if [[ -f "$FILE" ]] && ! is_temp_file "$FILE" && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME3}"

        echo "########## $(date) - Processing file: $FILE via $PRESET_NAME3 preset ##########" | tee -a "$LOG_FILE"
        out_path="${OUTPUT_DIR3}/${out_basename}.${OUT_EXTENSION3}"

        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION3" -vn -c:a "$AUDIO_CODEC3" -b:a "$AUDIO_BITRATE3" -nt "$STANDARD3" -t "$TARGET_LOUDNESS3" --dual-mono -ar "$SAMPLE_RATE3" -q
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
      if [[ -f "$FILE" ]] && ! is_temp_file "$FILE"; then
        echo "########## $(date) - Not supported input format: $FILE ##########" | tee -a "$LOG_FILE"
        mkdir -p "$WATCH_DIR3/Source"
        mv "$FILE" "$WATCH_DIR3/Source/"
      fi
    fi
  done

  sleep 5
done