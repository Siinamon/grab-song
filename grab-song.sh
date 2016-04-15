#!/bin/bash

STREAMING="true"

VERBOSE=${VERBOSE-false}

CONFIG_DIR=${CONFIG_DIR-Config}

PLAYER_SELECTION=${1-$(cat $CONFIG_DIR/settings.conf | grep "last-used-player=" | sed 's/last-used-player=//')} 

OUTPUT_DIR=${OUTPUT_DIR-$(cat $CONFIG_DIR/settings.conf | grep "output-directory=" | sed 's/output-directory=//')}

#TODO: Add a variable for custom output directory. (IMPORTANT)
SONG_METADATA="Temp/SongMetaData.txt"
SONG_TITLE="$OUTPUT_DIR/SongTitle.txt"
SONG_ARTIST="$OUTPUT_DIR/SongArtist.txt"
SONG_ALBUM="$OUTPUT_DIR/SongAlbum.txt"

mkdir -p Temp
mkdir -p $OUTPUT_DIR
mkdir -p $CONFIG_DIR
touch $SONG_METADATA
touch $SONG_TITLE
touch $SONG_ARTIST
touch $SONG_ALBUM

if [ ! -f $CONFIG_DIR/settings.conf ]; then
    echo "last-used-player=" >> $CONFIG_DIR/settings.conf
    echo "output-directory=$OUTPUT_DIR" >> $CONFIG_DIR/settings.conf
fi

save_and_clean()
{
sed -i "/last-used-player=/ c\last-used-player=$PLAYER_SELECTION" $CONFIG_DIR/settings.conf
sed -i "/output-directory=/ c\output-directory=$OUTPUT_DIR" $CONFIG_DIR/settings.conf
rm -rf Temp/*
exit
}

if [ $VERBOSE = true ]; then

printf "================================\n"

fi

while [ $STREAMING = true ]; do
(

if [ "$(qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)" != "$(cat $SONG_METADATA)" ]; then
(

qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata > $SONG_METADATA

if grep -q "mpris:artUrl:" $SONG_METADATA; then

SONG_ART=$(cat $SONG_METADATA | grep "mpris:artUrl:" | sed 's/mpris:artUrl: //')
convert $SONG_ART -resize 500x500! $OUTPUT_DIR/AlbumArt.jpg &>/dev/null

else

convert Images/NoArt.* -resize 500x500! $OUTPUT_DIR/AlbumArt.jpg &>/dev/null

fi

cat $SONG_METADATA | grep "xesam:title:" | sed 's/xesam:title: //' > $SONG_TITLE
cat $SONG_METADATA | grep "xesam:artist:" | sed 's/xesam:artist: //' > $SONG_ARTIST
cat $SONG_METADATA | grep "xesam:album:" | sed 's/xesam:album: //' > $SONG_ALBUM

#Verbosity:
if [ $VERBOSE = true ]; then
printf "Title: "
cat $SONG_TITLE
printf "\n"

printf "Artist: "
cat $SONG_ARTIST
printf "\n"

printf "Album: "
cat $SONG_ALBUM
printf "\r"

printf "================================\n"

fi

)
fi

sleep 1

)

trap save_and_clean EXIT INT

done
