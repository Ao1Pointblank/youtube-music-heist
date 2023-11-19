#!/bin/bash
#https://github.com/Ao1Pointblank/youtube-music-heist
#modify to your heart's content! the music must flow!

#YOUR VARIABLES HERE
session_num=$(date +%s) #timestamp for download session folder names (i suggest not using formats with spaces, just in case)
api_key="GOOGLE API KEY"
playlist_name="YOUR PLAYLIST NAME" #make sure it matches exactly to the one displayed on YT page
playlist_id="PLAYLIST ID"
download_dir="$HOME/Downloads/YOUTUBE-HEIST/Sessions/YT-DLP-$session_num"
sessions_dir="$HOME/Downloads/YOUTUBE-HEIST/Sessions"
ytdlp_useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"

mkdir -p "$download_dir"

#define ANSI color codes
RED='\033[38;5;196m'
GREEN='\033[0;32m'
NC='\033[0m' #no color

#./yt-heist 5  -  download 5 videos from top of playlist
if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
	#download only the $1 latest thumbnails & music
	echo -e "${GREEN}downloading the last $1 audio and thumbnails...${NC}";
	yt-dlp -i --quiet --progress --no-overwrites --write-thumbnail --extract-audio --add-metadata --audio-format best --max-sleep-interval 5 --min-sleep-interval 2 --user-agent "$ytdlp_useragent" --output "$download_dir/%(artist)s/%(title)s.%(ext)s" "$playlist_id" --playlist-items 1-"$1"

#./yt-heist all  -  download entire playlist
elif [[ "$1" = "all" ]] ; then
	echo -e "${GREEN}downloading all playlist audio and thumbnails...${NC}";
	yt-dlp -i --quiet --progress --no-overwrites --write-thumbnail --extract-audio --add-metadata --audio-format best --max-sleep-interval 5 --min-sleep-interval 2 --user-agent "$ytdlp_useragent" --output "$download_dir/%(artist)s/%(title)s.%(ext)s" "$playlist_id"

#./yt-heist search "song name 1" "song name 2" ...
elif [[ "$1" = "search" ]]; then
    shift #move to the next argument after "search"
    search_terms=("$@")
    echo -e "${GREEN}searching for specified titles to download...${NC}"

    #use a loop to iterate over the search terms
    for term in "${search_terms[@]}"; do
        yt-dlp -i --quiet --progress --no-overwrites --write-thumbnail --extract-audio --add-metadata --audio-format best --max-sleep-interval 5 --min-sleep-interval 2 --user-agent "$ytdlp_useragent" --default-search "ytsearch" --output "$download_dir/%(artist)s/%(title)s.%(ext)s" "$term"
    done

#./yt-heist (with no args): download just the items added since last session
else
	echo -e "${GREEN}fetching video IDs from playlist...${NC}" ;

#API script to pull list of playlist item IDs
	python_script=$(cat <<EOF
import os
import requests
from datetime import datetime
def fetch_video_ids(api_key, playlist_id):
    next_page_token = None
    video_ids = []
    while True:
        #build the api request url
        url = f"https://www.googleapis.com/youtube/v3/playlistItems"
        params = {
            "playlistId": playlist_id,
            "key": api_key,
            "part": "snippet",
            "maxResults": 50,  #fixed to 50 per page
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
	#save the python script content to a temporary file
	python_script_file=$(mktemp)
	echo "$python_script" > "$python_script_file"

	#run the python script and capture its output
	python_output=$(python3 "$python_script_file")
	echo "$python_output"

	#clean up the temporary python script file
	rm -f "$python_script_file"

	#get newly added playlist items in space-separated list (vid-ID1 vid-ID2 vid-ID3...)
	echo -e "${GREEN}looking for new additions to playlist...${NC}" ;
	new_items="$(find "$sessions_dir" -maxdepth 1 -type f -iname "EXPLODED-*.txt" | xargs ls -t | head -2 | xargs diff | grep '^<' | cut -c 3- )"
	number_new_items=$(echo "$new_items" | wc -l)

	touch "$sessions_dir/batchfile-$session_num"
	new_items_batchfile="$sessions_dir/batchfile-$session_num"
	echo "$new_items" > "$new_items_batchfile"

	if [ -n "$new_items" ] ; then
		echo -e "${GREEN}downloading $number_new_items new audio and thumbnails...${NC}";
		yt-dlp -i --quiet --progress --no-overwrites --write-thumbnail --extract-audio --add-metadata --audio-format best --max-sleep-interval 5 --min-sleep-interval 2 --user-agent "$ytdlp_useragent" --output "$download_dir/%(artist)s/%(title)s.%(ext)s" --no-playlist -a "$new_items_batchfile"
	else
		echo -e "${RED}no new playlist items to download${NC}"
		exit 0
	fi
fi

#cropping thumbnails
[ -e "$download_dir/NA/$playlist_name.jpg" ] && rm "$download_dir/NA/$playlist_name.jpg"
echo -e "${GREEN}cropping thumbnails...${NC}"

#for regularly sized images
find "$download_dir" \( -iname "*.jpg" -o -iname "*.webp" \) -type f -exec identify -format '%w %h %i\n' '{}' \; | awk -F ' ' '$1 > 720 && $2 = 720 { $1=""; $2=""; print substr($0, 3) }' | xargs -I {} mogrify -crop 720x720+280+0 -format jpg +repage "{}" ;

#for weird small thumbnails
find "$download_dir" \( -iname "*.jpg" -o -iname "*.webp" \) -type f -exec identify -format '%w %h %i\n' '{}' \; | awk -F ' ' '$1 < 720 && $2 < 720 { $1=""; $2=""; print substr($0, 3) }' | xargs -I {} mogrify -resize 720x720^ -gravity center -extent 720x720 -background black -format jpg +repage "{}" ;

#remove crusty uncropped webps
echo -e "${GREEN}cleaning up junk images...${NC}"
find "$download_dir" -iname "*.webp" -type f -exec rm {} \;

#embed images
find "$download_dir" -iname '*.jpg' | while IFS= read -r cover_file; do
	#pair matching audio file
    input_audio_file=${cover_file%.jpg}.opus

    if [ -e "$input_audio_file" ]; then
        #use opustags to set album art for the audio file
        opustags --in-place "$input_audio_file" --set-cover "$cover_file"
    else
        echo -e "${RED}Corresponding audio file not found for $cover_file${NC}"
        #sometimes this message appears if yt-dlp has only .m4a available to download instead of .opus
    fi
done

#sanitize filenames in the download directory and its subdirectories
echo -e "${GREEN}sanitizing filenames...${NC}"

remove_symbols() {
    input_string="$1"

    #pattern for allowed characters. all others will be removed. (allowed: all digits and letters, even foreign. spaces. parentheses. hyphen & period.)
    regex_pattern="[^[:alnum:][:space:]\\(')-.&]"

    #remove double or more spaces, tabs
    cleaned_string=$(echo "$input_string" | sed -E "s/$regex_pattern//g; s/ +/ /g; s/[[:space:]]+/ /g")
    echo "$cleaned_string"
}

sanitize_and_move() {
    local source="$1"

    if [ -d "$source" ]; then
        #iterate over files and subdirectories
        for item in "$source"/*; do
            #Check if it's a file
            if [ -f "$item" ]; then
                #extract the filename (with extension) from the file path
                filename=$(basename "$item")
                #extract the filename without extension
                base_filename="${filename%.*}"
                #sanitize the base filename and keep the extension intact
                sanitized_base_filename=$(remove_symbols "$base_filename")
                #construct the new filename with the original extension
                new_filename="$sanitized_base_filename.${filename##*.}"
                #check if the new filename is different from the old filename
                if [ "$filename" != "$new_filename" ]; then
                    #rename the file and handle errors
                    mv "$item" "$source/$new_filename"
                    if [ $? -ne 0 ]; then
                        echo -e "${RED}Failed to rename file: $item${NC}"
                    else
                        echo -e "Sanitizing: ${RED}$filename${NC} -> ${GREEN}$new_filename${NC}"
                    fi
                fi
            elif [ -d "$item" ]; then
                #recursively process subdirectories
                sanitize_and_move "$item"
            fi
        done
    fi
}
#start the process for the main download directory
sanitize_and_move "$download_dir"

#find opus files with "Official" or " - Topic" anywhere in their contents
readarray -t opus_with_junk < <(find "$download_dir" -iname '*.opus' -exec grep -rlZ -e " Official" -e " - Topic" {} \;)

#iterate over each file to process
for opus_with_junk_file_path in "${opus_with_junk[@]}"; do
    #extract performer information
    cleaned_artist_name=$(mediainfo "$opus_with_junk_file_path" --Inform="General;%Performer%" | sed -e 's/Official[[:space:]]*$//' -e 's/ - Topic[[:space:]]*$//')

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
