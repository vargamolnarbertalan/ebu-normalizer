# ebu-normalizer
Work in progress project to normalize audio of media files.

## List of features/fixes I'm working on:
- Multiple watchfolders for different presets (2 video watchfolders: normalize&encode | mute&encode, 1 audio watchfolder: normalize)
- Show progress bar or percentage of encoding
- UI or at least web log

## Done:
- Move original file instead of deleting upon completion
- Append encode info to output file
- Config file: Be able to set output format, normalization standard and detail, extension, output folder, watchfolder
- Handle files that do not have audio tracks or they are completely muted
- Video encode not just audio normalization


## Config file variables
- **WATCH_DIR**: Any valid path inside the container such as `/watch`.
- **OUTPUT_DIR**: Any valid path inside the container such as `/output`.
- **LOG_FILE**: Any valid logfile path inside the container such as `/logs/normalization.log`.
- **PRESET_NAME**: Just a custom name, can be anything such as `MyPreset` or `EBU`. This will be appended to the encoded filename: `filename_encoded_<PRESET_NAME>.<OUT_FORMAT>`.
- **TARGET_LOUDNESS**: Any valid float between -70.0 and -5.0 for EBU, otherwise -99.0 and 0. EBU default is -23, but this preset uses `-25` as default.
- **OUT_EXTENSION**: Any valid media container such as `mp4` for video or `mp3` for audio. 
- **AUDIO_BITRATE**: Any valid audio bitrate with 'k' at the end. Default is `256k`.
- **STANDARD**: You can choose from 3 different normalization standards/types. `ebu` | `rms` | `peak` - `ebu` is default.
- **SAMPLE_RATE**: Any valid sample rate for audio. Default is `48000`.
- **AUDIO_CODEC**: Any valid ffmpeg audio encoder. `aac` is default. (Use `ffmpeg -encoders` command to see list)
- **VIDEO_ENCODER**: Any valid ffmpeg audio encoder. `libx264` is default. (Use `ffmpeg -encoders` command to see list)
- **VIDEO_BITRATE**: Any valid video bitrate with 'k' at the end. Default is `10000k`.
- **FRAME_RATE**: Any valid video frame rate. Could be whole number or fraction. Examples: `30` | `50` | `30000/1001` which is 29.97. `60000/1001` aka 59.94 is default.
- **RESOLUTION**: Any valid video resolution such as `1920x1080`.