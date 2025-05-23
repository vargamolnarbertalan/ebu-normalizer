#!/bin/bash

##### FUNCTIONS #####

is_temp_file() {
  local file="$1"
  case "$file" in
    *.crdownload|*.part|*.download|*.opdownload|*.tmp|*.temp|*.~|*~|*.swp|*.swo|*.bak|*.filepart|*.partial|*.downloading|*.incomplete)
      return 0 ;;  # It's a temp file
    *) return 1 ;; # Safe to process
  esac
}

is_file_complete() {
  local file="$1"
  local prev_size=0
  local curr_size=0
  local stable_count=0
  local required_stable_count=3

  while true; do
    [[ ! -f "$file" ]] && return 1
    curr_size=$(stat -c%s "$file" 2>/dev/null || echo 0)

    if [[ "$curr_size" -eq "$prev_size" ]]; then
      ((stable_count++))
    else
      stable_count=0
    fi

    [[ "$stable_count" -ge "$required_stable_count" ]] && return 0

    prev_size="$curr_size"
    sleep 2
  done
}

check_extension() {
  local filename="$1"
  local extension="${filename##*.}"
  local extension_lower
  extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
  [[ "$extension_lower" =~ ^($ALLOWED_INPUT_FORMATS)$ ]] && return 0 || return 1
}

process_watch_dir() {
  local DIR="$1"
  local OUTPUT="$2"
  local PRESET="$3"
  local EXT="$4"
  local VIDEO_OPTS="$5"
  local AUDIO_CODEC="$6"
  local AUDIO_BITRATE="$7"
  local STANDARD="$8"
  local TARGET_LOUDNESS="$9"
  local SAMPLE_RATE="${10}"
  local USE_NORMALIZE="${11}"

  mkdir -p "$DIR/Source"

  for FILE in "$DIR"/*; do
    [[ ! -f "$FILE" || is_temp_file "$FILE" || ! check_extension "$FILE" ]] && continue

    if is_file_complete "$FILE"; then
      local filename in_basename out_basename out_path AUDIO_STREAM
      filename=$(basename "$FILE")
      in_basename="${filename%.*}"
      out_basename="${in_basename}_encoded_${PRESET}"
      out_path="${OUTPUT}/${out_basename}.${EXT}"

      echo "########## $(date) - Processing file: $FILE via $PRESET preset ##########" | tee -a "$LOG_FILE"

      AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

      if [[ "$USE_NORMALIZE" == "true" && -n "$AUDIO_STREAM" ]]; then
        /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$EXT" -e="$VIDEO_OPTS" -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -q
      elif [[ -n "$AUDIO_STREAM" ]]; then
        ffmpeg -i "$FILE" -an $VIDEO_OPTS "$out_path" -loglevel fatal
      elif [[ "$USE_NORMALIZE" != "true" ]]; then
        ffmpeg -i "$FILE" $VIDEO_OPTS -c:a copy "$out_path" -loglevel fatal
      else
        echo "########## $(date) - No audio stream found, can't output normalized audio file. ##########" | tee -a "$LOG_FILE"
      fi

      echo "########## $(date) - Finished processing: $out_path ##########" | tee -a "$LOG_FILE"
      mv "$FILE" "$DIR/Source/"
    else
      echo "########## $(date) - File is still being written: $FILE ##########" | tee -a "$LOG_FILE"
    fi
  done
}

##### CONFIG #####

LOG_FILE="encode.log"

##### DETECT HOW MANY PROFILES #####

NUM_PROFILES=0
while true; do
  test_var="WATCH_DIR$((NUM_PROFILES + 1))"
  [[ -n "${!test_var}" ]] || break
  ((NUM_PROFILES++))
done

##### VIDEO OPTIONS #####

declare -A VIDEO_OPTIONS

for i in $(seq 1 "$NUM_PROFILES"); do
  encoder_var="VIDEO_ENCODER$i"
  bitrate_var="VIDEO_BITRATE$i"
  fps_var="FRAME_RATE$i"
  width_var="WIDTH$i"
  height_var="HEIGHT$i"

  encoder="${!encoder_var}"
  bitrate="${!bitrate_var}"
  fps="${!fps_var}"
  width="${!width_var}"
  height="${!height_var}"

  VIDEO_OPTIONS["$i"]="-c:v $encoder -b:v $bitrate -r $fps -vf scale=w=$width:h=$height:force_original_aspect_ratio=decrease"
done

##### SETUP #####

for i in $(seq 1 "$NUM_PROFILES"); do
  watch_var="WATCH_DIR$i"
  output_var="OUTPUT_DIR$i"

  watch_dir="${!watch_var}"
  output_dir="${!output_var}"

  mkdir -p "$watch_dir" "$output_dir"
  echo "$(date) - Watching directory: $watch_dir for new files..." | tee -a "$LOG_FILE"
done

##### CONFIG ARRAYS #####

WATCH_DIRS=("$WATCH_DIR1" "$WATCH_DIR2" "$WATCH_DIR3" "$WATCH_DIR4" "$WATCH_DIR5")
OUTPUT_DIRS=("$OUTPUT_DIR1" "$OUTPUT_DIR2" "$OUTPUT_DIR3" "$OUTPUT_DIR4" "$OUTPUT_DIR5")
PRESETS=("$PRESET_NAME1" "$PRESET_NAME2" "$PRESET_NAME3" "$PRESET_NAME4" "$PRESET_NAME5")
OUT_EXTS=("$OUT_EXTENSION1" "$OUT_EXTENSION2" "$OUT_EXTENSION3" "$OUT_EXTENSION4" "$OUT_EXTENSION5")
VIDEO_OPTS_LIST=("$VIDEO_OPTIONS1" "$VIDEO_OPTIONS2" "" "$VIDEO_OPTIONS4" "$VIDEO_OPTIONS5")
AUDIO_CODECS=("$AUDIO_CODEC1" "" "$AUDIO_CODEC3" "$AUDIO_CODEC4" "")
AUDIO_BITRATES=("$AUDIO_BITRATE1" "" "$AUDIO_BITRATE3" "$AUDIO_BITRATE4" "")
STANDARDS=("$STANDARD1" "" "$STANDARD3" "$STANDARD4" "")
LOUDNESSES=("$TARGET_LOUDNESS1" "" "$TARGET_LOUDNESS3" "$TARGET_LOUDNESS4" "")
SAMPLE_RATES=("$SAMPLE_RATE1" "" "$SAMPLE_RATE3" "$SAMPLE_RATE4" "")
NORMALIZE_FLAGS=("true" "false" "true" "true" "false")

##### MAIN LOOP #####

while true; do
  for i in "${!WATCH_DIRS[@]}"; do
    process_watch_dir \
      "${WATCH_DIRS[$i]}" \
      "${OUTPUT_DIRS[$i]}" \
      "${PRESETS[$i]}" \
      "${OUT_EXTS[$i]}" \
      "${VIDEO_OPTS_LIST[$i]}" \
      "${AUDIO_CODECS[$i]}" \
      "${AUDIO_BITRATES[$i]}" \
      "${STANDARDS[$i]}" \
      "${LOUDNESSES[$i]}" \
      "${SAMPLE_RATES[$i]}" \
      "${NORMALIZE_FLAGS[$i]}"
  done
  sleep 5
done