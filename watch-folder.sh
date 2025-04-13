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
  # echo "#### extension: $extension_lower ####" | websocat -1 ws://localhost:443/ws
  [[ "$extension_lower" =~ ^($ALLOWED_INPUT_FORMATS)$ ]] && return 0 || return 1
}

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$LOG_FILE2")"
mkdir -p "$(dirname "$LOG_FILE3")"

#websocat -t ws-l:0.0.0.0:4981 -E broadcast:mirror: &
#python3 -m http.server 443 &

echo "$(date) - Watching directory: $WATCH_DIR for new files..." | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
echo "$(date) - Watching directory: $WATCH_DIR2 for new files..." | tee -a "$LOG_FILE2" | websocat -1 ws://localhost:443/ws
echo "$(date) - Watching directory: $WATCH_DIR3 for new files..." | tee -a "$LOG_FILE3" | websocat -1 ws://localhost:443/ws

while true; do
  ############### watch dir 1 ##################
  for FILE in "$WATCH_DIR"/*; do
    if [[ -f "$FILE" ]] && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        #echo "$(date) - File is complete: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws

        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME}"

        echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        #echo "Input file basename: $in_basename"
        #echo "Output file basename: $out_basename"
        out_path="${OUTPUT_DIR}/${out_basename}.${OUT_EXTENSION}"

        #echo "Output path: $out_path"

        # Check if the input file has an audio stream
        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        # If audio stream exists, normalize audio and encode video
        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION" -e="$VIDEO_OPTIONS" -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -v | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        else
          # If no audio stream, just encode the video stream
          ffmpeg -i "$FILE" -c:v "$VIDEO_ENCODER" -b:v "$VIDEO_BITRATE" -r "$FRAME_RATE" -s "$RESOLUTION" -c:a copy "$out_path.$OUT_EXTENSION" -loglevel verbose | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        fi

        echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws

        # move file
        mkdir -p "$WATCH_DIR/_original"
        mv "$FILE" "$WATCH_DIR/_original/"
      else
        echo "$(date) - File is still being written: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        continue # Skip this file and check again later
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "$(date) - Not supported input format: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        # move file
        mkdir -p "$WATCH_DIR/_original"
        mv "$FILE" "$WATCH_DIR/_original/"
      fi
    fi
  done
  ############### watch dir 2 ##################
  for FILE in "$WATCH_DIR2"/*; do
    if [[ -f "$FILE" ]] && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        #echo "$(date) - File is complete: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws

        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME2}"

        echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE2" | websocat -1 ws://localhost:443/ws
        #echo "Input file basename: $in_basename"
        #echo "Output file basename: $out_basename"
        out_path="${OUTPUT_DIR2}/${out_basename}.${OUT_EXTENSION2}"

        #echo "Output path: $out_path"

        # Check if the input file has an audio stream
        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        # If audio stream exists remove audio and encode video
        if [ -n "$AUDIO_STREAM" ]; then
          ffmpeg -i "$FILE" -an -c:v "$VIDEO_ENCODER2" -b:v "$VIDEO_BITRATE2" -r "$FRAME_RATE2" -s "$RESOLUTION2" "$out_path.$OUT_EXTENSION2" -loglevel verbose | tee -a "$LOG_FILE2" | websocat -1 ws://localhost:443/ws
        else
          # If no audio stream, just encode the video stream
          ffmpeg -i "$FILE" -c:v "$VIDEO_ENCODER2" -b:v "$VIDEO_BITRATE2" -r "$FRAME_RATE2" -s "$RESOLUTION2" -c:a copy "$out_path.$OUT_EXTENSION2" -loglevel verbose | tee -a "$LOG_FILE2" | websocat -1 ws://localhost:443/ws
        fi

        echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE2" | websocat -1 ws://localhost:443/ws

        # move file
        mkdir -p "$WATCH_DIR2/_original"
        mv "$FILE" "$WATCH_DIR2/_original/"
      else
        echo "$(date) - File is still being written: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        continue # Skip this file and check again later
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "$(date) - Not supported input format: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        # move file
        mkdir -p "$WATCH_DIR2/_original"
        mv "$FILE" "$WATCH_DIR2/_original/"
      fi
    fi
  done
  ############### watch dir 3 ##################
  for FILE in "$WATCH_DIR3"/*; do
    if [[ -f "$FILE" ]] && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        #echo "$(date) - File is complete: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws

        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME3}"

        echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE3" | websocat -1 ws://localhost:443/ws
        #echo "Input file basename: $in_basename"
        #echo "Output file basename: $out_basename"
        out_path="${OUTPUT_DIR3}/${out_basename}.${OUT_EXTENSION3}"

        #echo "Output path: $out_path"

        # Check if the input file has an audio stream
        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        # If audio stream exists, normalize audio and remove video stream
        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION3" -vn -c:a "$AUDIO_CODEC3" -b:a "$AUDIO_BITRATE3" -nt "$STANDARD3" -t "$TARGET_LOUDNESS3" --dual-mono -ar "$SAMPLE_RATE3" -v | tee -a "$LOG_FILE3" | websocat -1 ws://localhost:443/ws
        else
          # If no audio stream, log it and move file
          echo "No audio stream found, can't output normalized audio file." | tee -a "$LOG_FILE3" | websocat -1 ws://localhost:443/ws
        fi

        echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE3" | websocat -1 ws://localhost:443/ws

        # move file
        mkdir -p "$WATCH_DIR3/_original"
        mv "$FILE" "$WATCH_DIR3/_original/"
      else
        echo "$(date) - File is still being written: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        continue # Skip this file and check again later
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "$(date) - Not supported input format: $FILE" | tee -a "$LOG_FILE" | websocat -1 ws://localhost:443/ws
        # move file
        mkdir -p "$WATCH_DIR3/_original"
        mv "$FILE" "$WATCH_DIR3/_original/"
      fi
    fi
  done
  sleep 5 # Wait 5 seconds before checking again
done