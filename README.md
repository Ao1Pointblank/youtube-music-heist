# youtube-music-heist
Check YT-music playlist for newly added songs and download just those (API key needed)

What you need:
- Google's Youtube Data V3 API Key
- Your playlist's ID
- yt-dlp (https://github.com/yt-dlp/yt-dlp)
- opustags (https://github.com/fmang/opustags)
- python3
- imagemagick (uses the convert command to crop thumbnails)

# 3 Usages:
``./yt-heist.sh all``
attempt to download all videos from the playlist ID. this is the recommended way to run it for the first time.

``./yt-heist.sh NUMBER``
download the last NUMBER of videos from the playlist ID. Starts downloading from the top of the playlist. Does not check if you already downloaded the same files in the last session.

``./yt-heist``
this will create a list of video IDs from the given playlist ID, and compare this list to what was created last session. it will download any new video IDs, regardless where they are located in the playlist. 
this mode of usage is how you update a downloaded playlist with a small batch of freshly added videos. it saves a lot more internet and time than downloading the whole playlist or manually counting out which playlist items you want to download.
this mode is also the only one that uses the API key.

# what else does it do? what makes it different from just using yt-dlp by itself?
i wanted to squeeze as much audio quality out of yt-music as possible, which meant using yt-dlp with the ``--audio-format best``, which usually results in .opus files. however, these audio files do not seem to be easy to embed images into, even with yt-dlp's ``--add-metadata`` option. 
so, this will download the images separately, crop them to be 720x720p squares, and use opustags to embed them easily. 

it also will remove some yucky metadata from the opus files, such as artist names with " - Topic" or " Official" in their name (it removes just the clutter at the end)

then, it will even sanitize some file names, removing most strange characters.
it leaves all digits and alphabetical characters, even cyrillic/japanese etc, and also the symbols ``( ) - . '``
it should be fairly easy to modify to your own needs.

finally, it will take the last session of downloads and make a symbolic link in the download directory and title it "latest" so you can easily grab the contents and copy them to a phone, music folder, smart fridge, etc., topping off your playlist!
