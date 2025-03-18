# Video Compressor Script

This script compresses video files in a specified directory using `ffmpeg` with GPU acceleration. It supports various video formats and allows you to set a desired width and bitrate limit for the output videos.

## Prerequisites

- `ffmpeg` must be installed on your system.
- Ensure that your system has a compatible GPU and the necessary drivers for GPU acceleration.

## Usage

1. **Clone or download the script** to your local machine.

2. **Navigate to the directory** where the script is located.

3. **Edit the script** to set your desired parameters:
   - `DESIRED_WIDTH`: Set the desired width for the output videos (e.g., 1920, 1280, 720, etc.). Leave it empty to keep the original dimensions.
   - `BITRATE_LIMIT`: Set the maximum bitrate for the output videos in kbps (e.g., 15000).
   - `RC_MODE`: Set the rate control mode (e.g., VBR, CQP, or CBR).
   - `QUALITY`: Set the CRF value for the output videos (e.g., -crf 25).
   - `PRESET`: Set the preset for the output videos (e.g., -preset slow).
   - `APPEND`: Set the suffix to append to the output video filenames (e.g., _compressed).

4. **Run the script**:
   ```bash
   ./compress.sh
   ```

## Script Details

The script performs the following steps:

1. **Checks if the directory contains any files**. If the directory is empty, it exits with a message.

2. **Finds all video files** in the specified directory with the extensions `.mp4`, `.mkv`, `.avi`, and `.mov`.

3. **Verifies if `ffmpeg` is installed**. If not, it exits with a message.

4. **Processes each video file**:
   - Skips files that already have the specified suffix (`APPEND`).
   - Skips files that have already been converted (i.e., if the output file already exists).
   - Retrieves the original bitrate and resolution of the video.
   - Skips files with a bitrate lower than `BITRATE_LIMIT`.
   - Skips files with a width lower than `DESIRED_WIDTH`.
   - Constructs and executes the `ffmpeg` command to compress the video using GPU acceleration.
   - Verifies if the output file is valid and displays the properties of the converted video.

## Example

Here is an example of how to set the parameters and run the script:

```bash
#!/bin/bash

# Directory where the videos are located (one directory above)
INPUT_DIR="$(dirname "$(pwd)")"
# Desired width for the output videos
DESIRED_WIDTH="1280"
# Rate control mode
RC_MODE="-rc_mode VBR"
# Maximum bitrate for the output videos in kbps
BITRATE_LIMIT="15000"
# CRF value for the output videos
QUALITY="-crf 25"
# Preset for the output videos
PRESET="-preset slow"
# Suffix to append to the output video filenames
APPEND="_compressed"

# Run the script
compress.sh
```

## Notes

- Ensure that the `INPUT_DIR` variable is set correctly to point to the directory containing the videos you want to compress.
- Adjust the parameters as needed to achieve the desired output quality and file size.

## License

This script is provided as-is without any warranty. Use it at your own risk.
