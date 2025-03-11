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
VIDEO_ENCODER=$(echo -n "$VIDEO_ENCODER" | tr -d '\r')
VIDEO_BITRATE=$(echo -n "$VIDEO_BITRATE" | tr -d '\r')
FRAME_RATE=$(echo -n "$FRAME_RATE" | tr -d '\r')
RESOLUTION=$(echo -n "$RESOLUTION" | tr -d '\r')
VIDEO_OPTIONS="-c:v ${VIDEO_ENCODER} -b:v ${VIDEO_BITRATE} -r ${FRAME_RATE} -s ${RESOLUTION}"

WATCH_DIR2=$(echo -n "$WATCH_DIR2" | tr -d '\r')
OUTPUT_DIR2=$(echo -n "$OUTPUT_DIR2" | tr -d '\r')
LOG_FILE2=$(echo -n "$LOG_FILE2" | tr -d '\r')
PRESET_NAME2=$(echo -n "$PRESET_NAME2" | tr -d '\r')
OUT_EXTENSION2=$(echo -n "$OUT_EXTENSION2" | tr -d '\r')
VIDEO_ENCODER2=$(echo -n "$VIDEO_ENCODER2" | tr -d '\r')
VIDEO_BITRATE2=$(echo -n "$VIDEO_BITRATE2" | tr -d '\r')
FRAME_RATE2=$(echo -n "$FRAME_RATE2" | tr -d '\r')
RESOLUTION2=$(echo -n "$RESOLUTION2" | tr -d '\r')
VIDEO_OPTIONS2="-c:v ${VIDEO_ENCODER2} -b:v ${VIDEO_BITRATE2} -r ${FRAME_RATE2} -s ${RESOLUTION2}"

WATCH_DIR3=$(echo -n "$WATCH_DIR3" | tr -d '\r')
OUTPUT_DIR3=$(echo -n "$OUTPUT_DIR3" | tr -d '\r')
LOG_FILE3=$(echo -n "$LOG_FILE3" | tr -d '\r')
PRESET_NAME3=$(echo -n "$PRESET_NAME3" | tr -d '\r')
TARGET_LOUDNESS3=$(echo -n "$TARGET_LOUDNESS3" | tr -d '\r')
OUT_EXTENSION3=$(echo -n "$OUT_EXTENSION3" | tr -d '\r')
AUDIO_BITRATE3=$(echo -n "$AUDIO_BITRATE3" | tr -d '\r')
STANDARD3=$(echo -n "$STANDARD3" | tr -d '\r')
SAMPLE_RATE3=$(echo -n "$SAMPLE_RATE3" | tr -d '\r')
AUDIO_CODEC3=$(echo -n "$AUDIO_CODEC3" | tr -d '\r')

ALLOWED_INPUT_FORMATS=$(echo -n "$ALLOWED_INPUT_FORMATS" | tr -d '\r')

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
  echo "#### extension: $extension ####"
  [[ "$extension" =~ ^($ALLOWED_INPUT_FORMATS)$ ]] && return 0 || return 1
}

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$LOG_FILE2")"
mkdir -p "$(dirname "$LOG_FILE3")"

echo "$(date) - Watching directory: $WATCH_DIR for new files..." | tee -a "$LOG_FILE"
echo "$(date) - Watching directory: $WATCH_DIR2 for new files..." | tee -a "$LOG_FILE2"
echo "$(date) - Watching directory: $WATCH_DIR3 for new files..." | tee -a "$LOG_FILE3"

while true; do
  ############### watch dir 1 ##################
  for FILE in "$WATCH_DIR"/*; do
    if [[ -f "$FILE" ]] && check_extension "$FILE"; then
      if is_file_complete "$FILE"; then
        echo "$(date) - File is complete: $FILE" | tee -a "$LOG_FILE"

        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME}"

        echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE"
        #echo "Input file basename: $in_basename"
        #echo "Output file basename: $out_basename"
        out_path="${OUTPUT_DIR}/${out_basename}.${OUT_EXTENSION}"

        #echo "Output path: $out_path"

        # Check if the input file has an audio stream
        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        # If audio stream exists, normalize audio and encode video
        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION" -e="$VIDEO_OPTIONS" -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -v | tee -a "$LOG_FILE"
        else
          # If no audio stream, just encode the video stream
          ffmpeg -i "$FILE" -c:v "$VIDEO_ENCODER" -b:v "$VIDEO_BITRATE" -r "$FRAME_RATE" -s "$RESOLUTION" -c:a copy "$out_path.$OUT_EXTENSION" -loglevel verbose | tee -a "$LOG_FILE"
        fi

        echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE"

        # move file
        mkdir -p "$WATCH_DIR/_original"
        mv "$FILE" "$WATCH_DIR/_original/"
      else
        echo "$(date) - File is still being written: $FILE" | tee -a "$LOG_FILE"
        continue # Skip this file and check again later
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "$(date) - Not supported input format: $FILE" | tee -a "$LOG_FILE"
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
        echo "$(date) - File is complete: $FILE" | tee -a "$LOG_FILE"

        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME2}"

        echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE2"
        #echo "Input file basename: $in_basename"
        #echo "Output file basename: $out_basename"
        out_path="${OUTPUT_DIR2}/${out_basename}.${OUT_EXTENSION2}"

        #echo "Output path: $out_path"

        # Check if the input file has an audio stream
        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        # If audio stream exists remove audio and encode video
        if [ -n "$AUDIO_STREAM" ]; then
          ffmpeg -i "$FILE" -an -c:v "$VIDEO_ENCODER2" -b:v "$VIDEO_BITRATE2" -r "$FRAME_RATE2" -s "$RESOLUTION2" "$out_path.$OUT_EXTENSION2" -loglevel verbose | tee -a "$LOG_FILE2"
        else
          # If no audio stream, just encode the video stream
          ffmpeg -i "$FILE" -c:v "$VIDEO_ENCODER2" -b:v "$VIDEO_BITRATE2" -r "$FRAME_RATE2" -s "$RESOLUTION2" -c:a copy "$out_path.$OUT_EXTENSION2" -loglevel verbose | tee -a "$LOG_FILE2"
        fi

        echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE2"

        # move file
        mkdir -p "$WATCH_DIR2/_original"
        mv "$FILE" "$WATCH_DIR2/_original/"
      else
        echo "$(date) - File is still being written: $FILE" | tee -a "$LOG_FILE"
        continue # Skip this file and check again later
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "$(date) - Not supported input format: $FILE" | tee -a "$LOG_FILE"
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
        echo "$(date) - File is complete: $FILE" | tee -a "$LOG_FILE"

        filename=$(basename "$FILE")
        in_basename="${filename%.*}"
        out_basename="${in_basename}_encoded_${PRESET_NAME3}"

        echo "$(date) - Processing file: $FILE" | tee -a "$LOG_FILE3"
        #echo "Input file basename: $in_basename"
        #echo "Output file basename: $out_basename"
        out_path="${OUTPUT_DIR3}/${out_basename}.${OUT_EXTENSION3}"

        #echo "Output path: $out_path"

        # Check if the input file has an audio stream
        AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

        # If audio stream exists, normalize audio and remove video stream
        if [ -n "$AUDIO_STREAM" ]; then
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$OUT_EXTENSION3" -vn -c:a "$AUDIO_CODEC3" -b:a "$AUDIO_BITRATE3" -nt "$STANDARD3" -t "$TARGET_LOUDNESS3" --dual-mono -ar "$SAMPLE_RATE3" -v | tee -a "$LOG_FILE3"
        else
          # If no audio stream, log it and move file
          echo "No audio stream found, can't output normalized audio file." | tee -a "$LOG_FILE3"
        fi

        echo "$(date) - Finished processing: $FILE" | tee -a "$LOG_FILE3"

        # move file
        mkdir -p "$WATCH_DIR3/_original"
        mv "$FILE" "$WATCH_DIR3/_original/"
      else
        echo "$(date) - File is still being written: $FILE" | tee -a "$LOG_FILE"
        continue # Skip this file and check again later
      fi
    else
      if [[ -f "$FILE" ]]; then
        echo "$(date) - Not supported input format: $FILE" | tee -a "$LOG_FILE"
        # move file
        mkdir -p "$WATCH_DIR3/_original"
        mv "$FILE" "$WATCH_DIR3/_original/"
      fi
    fi
  done
  sleep 5 # Wait 5 seconds before checking again
done
