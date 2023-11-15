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

![Screenshot_from_2023-11-06_05-52-28](https://github.com/Ao1Pointblank/youtube-music-heist/assets/88149675/04ddbcf5-4ce3-48e5-8817-6a4497757c13)
# What do the errors mean?!
``ERROR: [youtube] SYfcy0QmdPs: Video unavailable. This video is not available``: 
it's been deleted or unlisted. use the [Wayback Machine](https://web.archive.org) to check for a youtube.com video with a matching ID. This is usually only a problem when using with the "all" option since newly added videos won't be unlisted. artists sometimes do this to some old versions of their songs when they remaster them or change label companies

``Corresponding audio file not found for blah/blah/blah/song.jpg``:
this is what happens when the script can't find a matching .opus file for the .jpg thumbnail it has just nicely cropped for you. this is usually only with weird non-music playlist items which only have .m4a audio formats available. these may be embedded with an uncropped image, unfortunately. check your sessions folder for m4a files and adjust them manually.

``Processed file: /blah/blah/blah/song.opus``, ``Cleaned Performer: Artist``:
this is a good thing to see, but maybe check the artist metadata for these files just in case. it is letting you know that it deleted some fluff like " - Topic" or " Official" from the artist name.

there are other error messages but i don't know yet under what circumstances they will appear.

#genius-lyrics.py
this is an optional script i planned on incorporating into the final version. it searches genius.com but can be easily confused if the artist name / song title of the file from youtube does not match exactly
i also ran into problems using opustags to embed the lyrics into the audio files, when there was already an image file also embedded. a workaround is to save the lyrics as a .txt file and use a music player that will detect the lyrics in the same directory as the audio (i don't know of any such players, please suggest one if you know one)

usage of genius-lyrics.py:
``python3 ./genius-lyrics.py "ARTIST" "SONG TITLE"`` 
output is sent to stdout and can easily be piped into a file with > 

# What's next?
- automate the process of checking for new additions to the playlist. run at startup/login, and send notification or maybe even open a zenity window prompting interaction to confirm downloads
- add more "--options" so users won't have to edit the file and add their api-key, playlist id, and download directory (hardcoding is not nice)
