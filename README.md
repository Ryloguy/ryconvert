# ryconvert

ryconvert is a shell script which finds .flac and ALAC files in a local directory, then converts them to 16-bit 44.1kHz ALAC files for use with an iPod. This script should be compatible with all UNIX-based systems with ffmpeg installed and in your PATH.

## Dependencies

ffmpeg

## Usage

Running the command without arguments will find all .flac and ALAC files in the current working directory, and convert all files to 16-bit 44.1kHz ALAC while presering album artwork and tag information. By default, the script will utilize all cores on your machine and process all files in parallel. The original files will be moved to a new directory within the current working directory, "Originals".

Note: If the script detects .m4a which were encoded using AAC as opposed to ALAC, the script will leave the files as-is, since converting a non-lossless file to a lossless format provides no benefits.

## Arguments

 -s - Single-thread mode

## Why not 24-bit?

While I am aware iPods support 24-bit audio, I have experienced many issues with audio artifacts and compatibility with accessories. For this reason, I wrote the script to transcode to 16-bit only to improve compatibility. I may add 24-bit functionality in the future via a flag.

## Multicore support?

It's here baybeeeeee ;)
Multi-core processing is enabled by default. Enable single-core mode with the -s flag.
