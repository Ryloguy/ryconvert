# ryconvert

ryconvert is a shell script which finds .flac and .alac files in a local directory, then converts them to 16-bit 44.1kHz .alac files for use with an iPod.

## Why not 24-bit?

While I am aware iPods support 24-bit audio, I have experienced many issues with audio artifacts and compatibility with accessories. For this reason, I wrote the script to transcode to 16-bit only to improve compatibility. I may add 24-bit functionality in the future via a flag.

## Multicore support?

Working on it ;) (No guarantee for timeframe)
