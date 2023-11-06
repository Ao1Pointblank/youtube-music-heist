#!/bin/bash
#https://github.com/Ao1Pointblank/youtube-music-heist
#modify to your heart's content! the music must flow!

session_num=$(date +%s) #unix timestamp
api_key="KEYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY"
playlist_id="PLAYLIST-IDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"
download_dir="$HOME/Downloads/YOUTUBE-HEIST/Sessions/YT-DLP-$session_num"
sessions_dir="$HOME/Downloads/YOUTUBE-HEIST/Sessions"
ytdlp_useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
mkdir -p "$download_dir";

# Define ANSI color codes for green text
RED='\033[38;5;196m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#check if $1 is a number greater than 0
if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
	#download only the $1 latest thumbnails & music
	echo -e "${GREEN}downloading the last $1 audio and thumbnails...${NC}";
	yt-dlp -i --no-overwrites --write-thumbnail --extract-audio --add-metadata --audio-format best --max-sleep-interval 5 --min-sleep-interval 2 --user-agent "$ytdlp_useragent" --output "$download_dir/%(title)s.%(ext)s" "$playlist_id" --playlist-items 1-"$1"
elif [[ "$1" = "all" ]] ; then
	echo -e "${GREEN}downloading all playlist audio and thumbnails...${NC}";
	yt-dlp -i --quiet --progress --no-overwrites --write-thumbnail --extract-audio --add-metadata --audio-format best --max-sleep-interval 5 --min-sleep-interval 2 --user-agent "$ytdlp_useragent" --output "$download_dir/%(title)s.%(ext)s" "$playlist_id"
else
	echo -e "${GREEN}fetching all video IDs from playlist...${NC}" ;

	# Define the Python script content using a here document
	python_script=$(cat <<EOF
import os
import requests
from datetime import datetime
def fetch_video_ids(api_key, playlist_id):
    next_page_token = None
    video_ids = []
    while True:
        # Build the API request URL
        url = f"https://www.googleapis.com/youtube/v3/playlistItems"
        params = {
            "playlistId": playlist_id,
            "key": api_key,
            "part": "snippet",
            "maxResults": 50,  # Fixed to 50 per page
            "pageToken": next_page_token
        }
        response = requests.get(url, params=params)
        data = response.json()
        items = data.get("items", [])
        for item in items:
            video_ids.append(item["snippet"]["resourceId"]["videoId"])
        next_page_token = data.get("nextPageToken")
        if not next_page_token or not items:
            break
    return video_ids
if __name__ == "__main__":
    video_ids = fetch_video_ids("$api_key", "$playlist_id")
    current_datetime = datetime.now()
    output_directory = f"$sessions_dir"
    os.makedirs(output_directory, exist_ok=True)
    output_file_path = os.path.join(output_directory, "EXPLODED-$session_num.txt")
    with open(output_file_path, "w") as file:
        for video_id in video_ids:
            file.write(video_id + "\\n")
    print(f"Video IDs saved to {output_file_path}")
EOF
)
	# Save the Python script content to a temporary file
	python_script_file=$(mktemp)
	echo "$python_script" > "$python_script_file"
	# Run the Python script and capture its output
	python_output=$(python3 "$python_script_file")
	# Print the Python script's output
	echo "$python_output"
	# Clean up the temporary Python script file
	rm -f "$python_script_file"

	#get newly added playlist items in list (vid-ID1 vid-ID2 vid-ID3...)
	echo -e "${GREEN}looking for new additions to playlist...${NC}" ;
	new_items="$(find "$sessions_dir" -maxdepth 1 -type f -name "EXPLODED-*.txt" | xargs ls -t | head -2 | xargs diff | grep '^<' | cut -c 3- | tr '\n' ' ')"

	if [ -n "$new_items" ] ; then
		echo -e "${GREEN}downloading new audio and thumbnails...${NC}";
		yt-dlp -i --no-overwrites --write-thumbnail --extract-audio --add-metadata --audio-format best --max-sleep-interval 5 --min-sleep-interval 2 --user-agent "$ytdlp_useragent" --output "$download_dir/%(title)s.%(ext)s" --no-playlist $new_items
	else
		echo -e "${RED}no new playlist items to download${NC}"
		exit 0
	fi
fi

#crop thumbnails
echo -e "${GREEN}cropping thumbnails...${NC}"
for img_file in "$download_dir"/*.{jpg,webp}; do
	convert "$img_file" -crop 720x720+280+0 +repage "${img_file%.*}.jpg"
done ;

#image file cleanup
echo -e "${GREEN}cleaning up junk images...${NC}"
if [ -e "$download_dir/Youtube Music Likes.jpg" ] ; then
	rm "$download_dir/Youtube Music Likes.jpg"
fi ;
find "$download_dir" -type f -name "*.webp" -exec rm {} \; ;

#embed images
echo -e "${GREEN}embedding images to audio files...${NC}"
for cover_file in "$download_dir"/*.jpg; do
    # Extract the base filename (without extension) from the image file
    cover_filename=$(basename "$cover_file" .jpg)
    input_audio_file=$download_dir/"$cover_filename".opus

    if [ -e "$input_audio_file" ]; then
    	# Use opustags to set album art for the audio file and save the modified file to the temporary directory
        opustags --in-place "$input_audio_file" --set-cover "$cover_file"
    else
        echo -e "${RED}Corresponding audio file not found for $cover_file${NC}"
        #sometimes this message appears if yt-dlp has only .m4a available to download instead of .opus
    fi
done

#sanitize filenames
echo -e "${GREEN}sanitizing filenames...${NC}"
remove_symbols() {
    input_string="$1"

    #pattern for allowed characters. all others will be removed. (allowed: all digits and letters, even foreign. spaces. parentheses. hyphen & period.)
    regex_pattern="[^[:alnum:][:space:]\\(')-.]"

    cleaned_string=$(echo "$input_string" | sed -E "s/$regex_pattern//g")
    echo "$cleaned_string"
}

if [ -d "$download_dir" ]; then
    for file in "$download_dir"/*; do
        if [ -f "$file" ]; then
            # Extract the filename (with extension) from the file path
            filename=$(basename "$file")
            # Extract the filename without extension
            base_filename="${filename%.*}"
            # Sanitize the base filename and keep the extension intact
            sanitized_base_filename=$(remove_symbols "$base_filename")
            # Construct the new filename with the original extension
            new_filename="$sanitized_base_filename.${filename##*.}"
            # Check if the new filename is different from the old filename
            if [ "$filename" != "$new_filename" ]; then
                # Rename the file and handle errors
                mv "$file" "$download_dir/$new_filename"
                if [ $? -ne 0 ]; then
                    echo -e "${RED}Failed to rename file: $file${NC}"
                fi
            fi
        fi
    done
else
    echo -e "${RED}Directory '$download_dir' does not exist${NC}"
fi

# Find opus files with "Official" or " - Topic" anywhere in their contents
readarray -t opus_with_junk < <(find "$download_dir" -name '*.opus' -exec grep -rl -e " Official" -e " - Topic" {} \;)

# Iterate over each file to process
for opus_with_junk_file_path in "${opus_with_junk[@]}"; do
    # Step 2: Extract Performer information
    cleaned_artist_name=$(mediainfo "$opus_with_junk_file_path" | grep "Performer" | sed 's/^[^:]*: //' | sed -e 's/Official[[:space:]]*$//' -e 's/ - Topic[[:space:]]*$//')

    if [ -n "$cleaned_artist_name" ]; then
    	#output to same file
        opustags -i "$opus_with_junk_file_path" -s "artist=$cleaned_artist_name"
        if [ $? -eq 0 ]; then
            echo "Processed file: $opus_with_junk_file_path"
            echo "Cleaned Performer: $cleaned_artist_name"
        else
            echo -e "${RED}Error processing file: $opus_with_junk_file_path${NC}"
        fi
    else
        echo -e "${RED}Performer information not found or not in the expected format for file: $opus_with_junk_file_path${NC}"
    fi
done

#remove the existing "latest" symbolic link if it exists
if [ -L "$sessions_dir/latest" ]; then
    rm "$sessions_dir/latest"
fi
#create a new "latest" symbolic link to the most recently created session folder
ln -s "$download_dir" "$sessions_dir/latest"
