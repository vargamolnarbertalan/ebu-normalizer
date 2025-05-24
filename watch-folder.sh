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
    if [[ ! -f "$FILE" ]]; then
      continue
    fi

    if is_temp_file "$FILE"; then
      continue
    fi

    if ! check_extension "$FILE"; then
      continue
    fi

    if is_file_complete "$FILE"; then
      local filename in_basename out_basename out_path AUDIO_STREAM
      filename=$(basename "$FILE")
      in_basename="${filename%.*}"
      out_basename="${in_basename}_encoded_${PRESET}"
      out_path="${OUTPUT}/${out_basename}.${EXT}"

      echo "########## $(date) - Processing file: $FILE via $PRESET preset ##########" | tee -a "$LOG_FILE"

      AUDIO_STREAM=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")
      VIDEO_STREAM=$(ffprobe -v error -select_streams v -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$FILE")

      if [[ "$USE_NORMALIZE" == "both" ]]; then
        if [[ -n "$AUDIO_STREAM" && -n "$VIDEO_STREAM" ]]; then
          #echo "Both audio and video streams exist"
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$EXT" -e="$VIDEO_OPTS" -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -q
        else
          echo "########## $(date) - Video or audio stream is missing from file. ##########" | tee -a "$LOG_FILE"
        fi
      elif [[ "$USE_NORMALIZE" == "vonly"]]; then
        if [[ -n "$VIDEO_STREAM" ]]; then
          #echo "Video stream detected"
          ffmpeg -i "$FILE" $VIDEO_OPTS -an "$out_path" -loglevel fatal
        else
          echo "########## $(date) - Video stream is missing from file. ##########" | tee -a "$LOG_FILE"
        fi      
      elif [[ "$USE_NORMALIZE" == "aonly"]]; then
        if [[ -n "$AUDIO_STREAM" ]]; then
          #echo "Audio stream detected"
          /app/venv/bin/ffmpeg-normalize "$FILE" -o "$out_path" -ext "$EXT" -vn -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" -nt "$STANDARD" -t "$TARGET_LOUDNESS" --dual-mono -ar "$SAMPLE_RATE" -q
        else
          echo "########## $(date) - Audio stream is missing from file. ##########" | tee -a "$LOG_FILE"
        fi
      else
        echo "########## $(date) - Invalid preset type/normalization setting. ##########" | tee -a "$LOG_FILE"
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

  if [[ -n "$encoder" && -n "$bitrate" && -n "$fps" && -n "$width" && -n "$height" ]]; then
    VIDEO_OPTIONS["$i"]="-c:v $encoder -b:v $bitrate -r $fps -vf scale=w=$width:h=$height:force_original_aspect_ratio=decrease"
  else
    VIDEO_OPTIONS["$i"]=""  # Allow audio-only profiles
  fi
done

##### SETUP + CONFIG ARRAYS #####

WATCH_DIRS=()
OUTPUT_DIRS=()
PRESETS=()
OUT_EXTS=()
VIDEO_OPTS_LIST=()
AUDIO_CODECS=()
AUDIO_BITRATES=()
STANDARDS=()
LOUDNESSES=()
SAMPLE_RATES=()
NORMALIZE_FLAGS=()

for i in $(seq 1 "$NUM_PROFILES"); do
  watch_var="WATCH_DIR$i"
  output_var="OUTPUT_DIR$i"
  preset_var="PRESET_NAME$i"
  ext_var="OUT_EXTENSION$i"
  codec_var="AUDIO_CODEC$i"
  bitrate_var="AUDIO_BITRATE$i"
  standard_var="STANDARD$i"
  loudness_var="TARGET_LOUDNESS$i"
  rate_var="SAMPLE_RATE$i"
  normalize_var="PTYPE$i"

  WATCH_DIRS+=("${!watch_var}")
  OUTPUT_DIRS+=("${!output_var}")
  PRESETS+=("${!preset_var}")
  OUT_EXTS+=("${!ext_var}")
  VIDEO_OPTS_LIST+=("${VIDEO_OPTIONS[$i]}")
  AUDIO_CODECS+=("${!codec_var}")
  AUDIO_BITRATES+=("${!bitrate_var}")
  STANDARDS+=("${!standard_var}")
  LOUDNESSES+=("${!loudness_var}")
  SAMPLE_RATES+=("${!rate_var}")
  NORMALIZE_FLAGS+=("${!normalize_var}")

  mkdir -p "${!watch_var}" "${!output_var}"
  echo "$(date) - Watching directory: ${!watch_var} for new files..." | tee -a "$LOG_FILE"
done

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