# Dockerized video encoder and auido normalization tool
## Intro
This is a service that can batch encode media files and normalize audio streams. It is intended for Docker only to include in broadcast teams' server setups.
Based on the official [ffmpeg](https://github.com/FFmpeg/FFmpeg) library and [ffmpeg-normalize repository by Werner Robitza](https://github.com/slhck/ffmpeg-normalize/).

## Installation
Pull from GitHub Packages

OR

> You need to have Docker and docker-compose installed.

Clone this repository and run the following commands inside the project's folder:
```
docker-compose up --build -d
```

## Usage
There is no GUI at the moment for this app. You setup your filesystem and environment variables so each preset is watching their respective folders and that's it. See **weblog for progress details at opened port**. Upon completion you will find the encoded file in the desired output folder and the original file moved to /Source folder inside the watchfolder. Video and audio parameters may be set in environment variables. See details below.
- `/watch1` folder is for **video & audio > video & audio** encoding, where the video is processed as you desire and the audio is normalized.
- `/watch2` folder is for **video & audio > video** encoding, where the video is processed as you desire and the audio is removed so the video gets muted.
- `/watch3` folder is for **video & audio / audio > audio** encoding, where the audio is normalized and the video stream gets removed.
- `/watch4` folder is for **video & audio > video & audio** encoding, where the video is processed as you desire and the audio is normalized, but with other parameters than in folder 1.
- `/watch5` folder is for **video & audio > video** encoding, where the video is processed as you desire and the audio is removed so the video gets muted, but with other parameters than in folder 2.

## Environment variables
### See Dockerfile for default values
- **ALLOWED_INPUT_FORMATS**: File extensions divided by `|` and surrounded with `"` that the app will process. Any other format will be ignored and moved to `/Source` without encoding.
- **WATCH_DIR1**: Any valid path inside the container such as `/watch`.
- **OUTPUT_DIR1**: Any valid path inside the container such as `/output` or `/watch/Output`.
- **PRESET_NAME1**: Just a custom name, can be anything such as `MyPreset` or `EBU`. This will be appended to the encoded filename: `filename_encoded_<PRESET_NAME>.<OUT_EXTENSION>`.
- **TARGET_LOUDNESS1**: Any valid float between -70.0 and -5.0 for EBU, otherwise -99.0 and 0.
- **OUT_EXTENSION1**: Any valid media container such as `mp4` for video or `mp3` for audio. 
- **AUDIO_BITRATE1**: Any valid audio bitrate with 'k' at the end. Default is `256k`.
- **STANDARD1**: You can choose from 3 different normalization standards/types. `ebu` | `rms` | `peak`
- **SAMPLE_RATE1**: Any valid sample rate for audio.
- **AUDIO_CODEC1**: Any valid ffmpeg audio encoder. (Use `ffmpeg -encoders` command to see list)
- **VIDEO_ENCODER1**: Any valid ffmpeg audio encoder. (Use `ffmpeg -encoders` command to see list)
- **VIDEO_BITRATE1**: Any valid video bitrate with 'k' at the end.
- **FRAME_RATE1**: Any valid video frame rate. Could be whole number or fraction. Examples: `30` | `50` | `30000/1001` which is 29.97.
- **WIDTH1**: Any valid video width such as `1920`.
- **HEIGHT1**: Any valid video height such as `1080`. (Note: aspect ratio of output will match the source file, and will be scaled to height)
- **PTYPE1**: Enum value to decide what kind of output you want: video/audio, video only, audio only. `both` | `vonly` | `aonly`
> Other variables ending in **2**, **3**, **4**, **5** will be used for their respective `/watch2`, `/watch3`, `/watch4`, `/watch5` folder.


## List of features / known issues I plan to work on:

## Done:
### 2025. 05. 24.
- ✅ Backend code restructured, added support for 4th and 5th folder.
### 2025. 05. 23.
- ✅ Resolution approach reworked: the size of the video will not be stretched to the output resolution, but will be scaled to fit the desired resolution while keeping aspect ratio. Resolution environment variable removed, width and height added.
- ✅ Temporary files such as .crdownload and others won't be moved or processed until completed into a valid media file.
### 2025. 05. 22.
- ✅ Long term support version of python alpine is now used for base image in order to further lighten the total size of this image.
- ✅ "File is still being written" bugs into infinite loop error fixed.
### 2025. 04. 13.
- ✅ Fixed issue when app does not recognize allowed input format if extension is uppercase.
- ✅ Web log design.
- ✅ Config through environment variables implemented.
### 2025. 03. 14.
- ✅ Timezone as environmental variable added for correct logging timestamps. Default is `Europe/Budapest`.
### 2025. 03. 11.
- ✅ Fixed: check if the file is finished and only start processing after. Useful when directly exporting files from media apps to a wathfolder.
- ✅ You can set allowed input formats in config.env from now on.
### 2025. 03. 06.
- ✅ Multiple watchfolders for different presets (2 video watchfolders: normalize&encode | mute&encode, 1 audio watchfolder: normalize)
### 2025. 03. 05.
- ✅ Move original file instead of deleting upon completion
- ✅ Append encode info to output file
- ✅ Config file: Be able to set output format, normalization standard and detail, extension, output folder, watchfolder, etc. from a standalone file before runtime.
- ✅ Handle files that do not have audio tracks or they are completely muted
- ✅ Video encode not just audio normalization