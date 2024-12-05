#!/bin/bash

printf "\nRy's Lossless iPod Converter :)\n\n"

# Process arguments
while getopts "hdi" opt; do
	case $opt in
		h) # Help Case
			printf "%s\n" "By default, this script will detect all FLAC and ALAC files in the current directory and convert them to iPod-friendly ALAC (16-bit 44.1kHz). To change this, use any of the following arguments:

			-h: Help [This screen ;)]
			-d: Default functionality
			-i: Convert ALAC files to iPod-friendly ALAC files (16-bit, 44.1kHz)"
			printf ""
			exit
			;;
		i)
			# Add functionality
			;;
		d) # Default Case
			# Add functionality
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

# Check for the Originals folder and create one if it does not already exist
if [ -d "Originals" ]; then
	echo "An existing Originals folder was found. Please either remove or rename it and try again."
	unset ryconvertm4a
	unset ryconvertflac
	exit
else
	echo "Creating Originals folder..."
	mkdir Originals
fi

# m4a Check and Conversion
if [ $ryconvertm4a -eq 1 ]; then
	echo "Processing .m4a files..."
	# Add functionality
	for f in *.m4a;
	do 
		echo -e "\nProcessing $f"
		# Grab file information
		ryconvertfileinfo=$(ffprobe -v error -show_format -show_streams "$f")
		# Check for artwork
		if echo "$ryconvertfileinfo" | grep -q 'mjpeg'; then
			ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.jpg" -loglevel error
			ryconvertart=".tempart${f%.m4a}.jpg"
			echo "Found jpg artwork"
		fi
		if echo "$ryconvertfileinfo" | grep -q 'png'; then
			ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.png" -loglevel error
			ryconvertart=".tempart${f%.m4a}.png"
			echo "Found png artwork"
		fi
		# Ensure the current file is actually an ALAC file
		if echo "$ryconvertfileinfo" | grep -q "alac"; then

			echo "Converting to 16-bit 44100Hz..."
			ffmpeg -i "$f" -vn -ar 44100 -sample_fmt s16 -acodec flac ".temp${f%.m4a}.flac" -loglevel error
			mv "$f" "Originals/$f"

			echo "Encoding using ALAC..."
			ffmpeg -i ".temp${f%.m4a}.flac" -acodec alac "$f" -loglevel error
			# Attach artwork if applicable
			if [ "$(echo "$ryconvertart" | wc -c)" -gt 1 ]; then
				echo "Attaching artwork..."
				ffmpeg -i "$f" -i "$ryconvertart" -map 0 -map 1 -c copy -disposition:v:0 attached_pic ".temp$f" -loglevel error
				rm "$f"
				mv ".temp$f" "$f"
				rm "$ryconvertart"
			fi
			rm ".temp${f%.m4a}.flac"
			unset ryconvertart
		else
			ryconvertalacwarning=1
			echo "$f doesn't seem to be encoded with ALAC. Skipping."
		fi

	done
fi

# FLAC Conversion
if [ $ryconvertflac -eq 1 ]; then
	echo "Processing FLAC files..."
	for f in *.flac;
	# Do sample rate and bit depth conversion using a temporary .flac file
	do
		echo "\nProcessing $f"
		# Grab file information
		ryconvertfileinfo=$(ffprobe -v error -show_entries stream=index,codec_name:stream_tags=filename -of default=noprint_wrappers=1:nokey=1 "$f")
		# Check for artwork
		if echo "$ryconvertfileinfo" | grep -q 'mjpeg'; then
			ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.jpg" -loglevel error
			ryconvertart=".tempart${f%.m4a}.jpg"
			echo "Found jpg artwork"
		fi
		if echo "$ryconvertfileinfo" | grep -q 'png'; then
			ffmpeg -i "$f" -an -vcodec copy ".tempart${f%.m4a}.png" -loglevel error
			echo "Found png artwork"
		fi

		echo "Converting to 16-bit 44100Hz..."
		ffmpeg -i "$f" -vn -ar 44100 -sample_fmt s16 -acodec flac ".temp$f" -loglevel error;

		# Convert the temporary .flac file to ALAC
		echo "Encoding using ALAC..."
		ffmpeg -i ".temp$f" -vn -acodec alac "${f%.flac}.m4a" -loglevel error;
		if [ "$(echo "$ryconvertart" | wc -c)" -gt 1 ]; then
			echo "Attaching artwork..."
			ffmpeg -i "${f%.flac}.m4a" -i "$ryconvertart" -map 0 -map 1 -c copy -disposition:v:0 attached_pic ".temp${f%.flac}.m4a" -loglevel error	
			rm "${f%.flac}.m4a"
			mv ".temp${f%.flac}.m4a" "${f%.flac}.m4a"
			rm "$ryconvertart"
		fi
		# Delete the temporary file
		rm ".temp$f"
		# Move the original file to the "Originals" folder
		mv "$f" "Originals/$f";
		unset ryconvertart
	done
fi

# Add a newline between processor outputs and final messages
echo ""

# Show ALAC warning if applicale
if echo "$ryconvertalacwarning" | grep 1; then
	# Show warning in red
	echo "\033[31m\nThere were .m4a files which were not converted because they were not originally encoded with ALAC."
fi

# Unset used environment variables
# Reset text color to black
echo "\033[0mCleaning up..."
unset ryconvertm4a
unset ryconvertflac
unset ryconvertm4acheck
unset ryconvertalacwarning
unset ryconvertart

echo "Done!"
