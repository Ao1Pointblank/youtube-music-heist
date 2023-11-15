#!/usr/bin/env python3

import requests
from bs4 import BeautifulSoup
from html import unescape
import sys

def scrape_lyrics(artistname, songname):
    artistname2 = str(artistname.replace(' ','-')) if ' ' in artistname else str(artistname)
    songname2 = str(songname.replace(' ','-')) if ' ' in songname else str(songname)
    page = requests.get(f'https://genius.com/{artistname2}-{songname2}-lyrics')

    # Use lxml as the parser
    html = BeautifulSoup(page.text, 'lxml')

    # Find all div elements with the specified class
    lyrics_containers = html.find_all("div", class_="Lyrics__Container-sc-1ynbvzw-1 kUgSbL")

    # Combine text from all matching div elements
    lyrics = "\n".join(container.get_text(separator="\n") for container in lyrics_containers)

    # Get the Genius URL
    genius_url = page.url

    # Replace unescaped ampersands with HTML entities
    lyrics = lyrics.replace('&', '&amp;')

    return lyrics.strip(), genius_url  # Strip leading/trailing whitespaces

if __name__ == "__main__":
    # Check if the correct number of arguments is provided
    if len(sys.argv) != 3:
        print("Usage: python script.py ARTIST SONG")
        sys.exit(1)

    artist_name = sys.argv[1]
    song_title = sys.argv[2]

    lyrics, genius_url = scrape_lyrics(artist_name, song_title)

    if lyrics:
        # Print lyrics and Genius URL
        print(lyrics)
        print("\nGenius URL:", genius_url)
    else:
        print("Lyrics not found.")
