#!/bin/bash

printf "\nRy's Lossless iPod Converter :)\n\n"

# Default singlethread variable to 0 to avoid operator error
singlethread=0

# Process arguments
while getopts "hs" opt; do
	case $opt in
		h) # Help Case
			printf "%s\n" "By default, this script will detect all FLAC and ALAC files in the current directory and convert them to iPod-friendly ALAC (16-bit 44.1kHz). To change this, use any of the following arguments:

			-h: Help [This screen ;)]
			-s: Run with a single thread"
			# ADD FLAG TO DISABLE MULTI-CORE
			printf ""
			exit
			;;

		s) # Single-thread mode
			singlethread=1
			;;

		\?) # Exception Case
			echo "Invalid argument. Please use -h for help."
			;;
	esac
done

# Check for audio files in the current working directory
echo "Looking for compatible audio files..."
# Search for .m4a files
if [ "$(find . -maxdepth 1 -type f -name "*.m4a" | wc -l)" -gt 0 ]; then
	ryconvertm4a=1
else
	ryconvertm4a=0
fi
# Search for FLAC files
if [ "$(find . -maxdepth 1 -type f -name "*.flac" | wc -l)" -gt 0 ]; then
	ryconvertflac=1
else
	ryconvertflac=0
fi

# Exit the program if no compatible lossless files were found
if [ $ryconvertflac -eq 0 ] && [ $ryconvertm4a -eq 0 ]; then
	echo "No compatible lossless files were found."
	unset ryconvertm4a
	unset ryconvertflac
	exit
fi

# Find and set # of threads
if [ $singlethread -eq 1 ] ; then
	echo "Running in single-thread mode"
	threads=1
else
	threads=$(nproc)
	echo "Found $threads threads"
fi

# Check for the Originals folder and create one if it does not already exist
if [ -d "Originals" ]; then
	echo "An existing Originals folder was found. Please either remove or rename it and try again."
	unset ryconvertm4a
	unset ryconvertflac
	exit
else
	echo "Creating Originals folder...\n"
	mkdir Originals
fi

m4a_convert() {
	# Grab file information
	ryconvertfileinfo=$(ffprobe -v error -show_format -show_streams "$f")
	# Check for artwork
	if echo "$ryconvertfileinfo" | grep -q 'mjpeg'; then
		ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.jpg" -loglevel error
		ryconvertart=".tempart${f%.m4a}.jpg"
	fi
	if echo "$ryconvertfileinfo" | grep -q 'png'; then
		ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.png" -loglevel error
		ryconvertart=".tempart${f%.m4a}.png"
	fi
	# Ensure the current file is actually an ALAC file
	if echo "$ryconvertfileinfo" | grep -q "alac"; then
		# Convert to FLAC for bit depth conversion
		ffmpeg -i "$f" -vn -ar 44100 -sample_fmt s16 -acodec flac ".temp${f%.m4a}.flac" -loglevel error
		mv "$f" "Originals/$f"
		# Convert to ALAC
		ffmpeg -i ".temp${f%.m4a}.flac" -acodec alac "$f" -loglevel error
		# Attach artwork if possible
		if [ "$(echo "$ryconvertart" | wc -c)" -gt 1 ]; then
			ffmpeg -i "$f" -i "$ryconvertart" -map 0 -map 1 -c copy -disposition:v:0 attached_pic ".temp$f" -loglevel error
			rm "$f"
			mv ".temp$f" "#f"
			rm "$ryconvertart"
		fi
		rm ".temp${f%.m4a}.flac"
		unset ryconvertart
		echo "$f converted"
	else
		ryconvertalacwarning=1
		echo "$f doesn't seem to be encoded with ALAC. Skipping."
	fi
}

flac_convert() {
	# Grab file information
	ryconvertfileinfo=$(ffprobe -v error -show_entries stream=index,codec_name:stream_tags=filename -of default=noprint_wrappers=1:nokey=1 "$f")
	# Check for artwork
	if echo "$ryconvertfileinfo" | grep -q 'mjpeg'; then
		ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.jpg" -loglevel error
		ryconvertart=".tempart${f%.m4a}.jpg"
	fi
	if echo "$ryconvertfileinfo" | grep -q 'png'; then
		ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.png" -loglevel error
		ryconvertart=".tempart${f%.m4a}.jpg"
	fi

	# Convert to 16-bit 44100Hz
	ffmpeg -i "$f" -vn -ar 44100 -sample_fmt s16 -acodec flac ".temp$f" -loglevel error

	# Convert temp .flac file to ALAC
	ffmpeg -i ".temp$f" -vn -acodec alac "${f%.flac}.m4a" -loglevel error
	
	# Add artwork if applicable
	if [ "$(echo "$ryconvertart" | wc -c)" -gt 1 ]; then
		ffmpeg -i "${f%.flac}.m4a" -i "$ryconvertart" -map 0 -map 1 -c copy -disposition:v:0 attached_pic ".temp${f%.flac}.m4a" -loglevel error
		rm "${f%.flac}.m4a"
		mv ".temp${f%.flac}.m4a" "${f%.flac}.m4a"
		rm "$ryconvertart"
	fi
	# Delete temp file
	rm ".temp$f"
	# Move original file to "Originals" folder
	mv "$f" "Originals/$f"
	unset ryconvertart
	echo "$f converted from FLAC"
}

# Export functions for subshells
export -f m4a_convert
export -f flac_convert

# m4a conversion loop
if [ $ryconvertm4a -gt 0 ]; then
	for f in *.m4a; do
		m4a_convert "$f" &
		((count++))
		# Try and find a way to start a new job as soon as an existing one ends
		if [[ $count -ge $threads ]]; then
			wait
			count=0
		fi
	done
fi

wait

# flac conversion loop
if [ $ryconvertflac -gt 0 ]; then
	for f in *.flac; do
		flac_convert "$f" &
		((count++))
		# Try and find a way to start a new job as soon as an existing one ends
		if [[ $count -ge $threads ]]; then
			wait
			count=0
		fi
	done
fi

wait

# Show ALAC warning if applicale
if echo "$ryconvertalacwarning" | grep 1; then
	# Show warning in red
	echo "\033[31m\nThere were .m4a files which were not converted because they were not originally encoded with ALAC."
fi

# Unset used environment variables
# Reset text color to black
echo "\033[0m\nCleaning up..."
unset ryconvertm4a
unset ryconvertflac
unset ryconvertm4acheck
unset ryconvertalacwarning
unset ryconvertart

echo "Done!"
