#! /bin/bash
function progress(){
	printf "\r"
	printf "$1 out of $2 songs processed for playlist: $3."
}

function downloadSong {
	urlUnformatted="$1"
	outloc="$2"
	if [[ "$urlUnformatted" == *"youtube.com"* ]]; then 
		url="$urlUnformatted" 
	else
		url="https://music.youtube.com/watch?v=$urlUnformatted" 
	fi

	#echo "EXEC: yt-dlp for url: $url into location $outloc for unformat $urlUnformatted"
	yt-dlp --extract-audio -f "bestaudio[ext=m4a]","bestaudio[ext=webm]" --audio-format mp3 --write-description --embed-thumbnail --embed-metadata "$url" -o "$outloc"
}


function playlistDownload {
	# raw playlist
	tmpList="ytdl.tmp.rawplaylist.$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)"

	# Sorted complete without ID
	tmpList2="ytdl.tmp.sortedWithoutId.$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)"

	# List of songs already downloaded (formatted already)
	tmpList3="ytdl.tmp.songsDownloaded.$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)"

	# Songs to download
	tmpList4="ytdl.tmp.songsToDownload.$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)"

	# Only IDs of the todownload
	tmpList5="ytdl.tmp.IDtoDownload.$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)"

	name="$1"
        url="$3"
        outDir="$2"
        echo "Downloading: $name into $outDir with URL $url"

        mkdir "$outDir/$name" 2> /dev/null

	yt-dlp --print "%(id)s %(title)s" --flat-playlist "$url" > "$tmpList"

	awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' "$tmpList" | sort > "$tmpList2"

	# get list of already existing files
	ls "$outDir/$name"  | sed 's/.mp3$//g' | grep -v description | sort > $tmpList3

	# get list of not downloaded songs
	grep -v -F -x -f "$tmpList3" "$tmpList2" > "$tmpList4"

	# make list of yt IDs
	cat "$tmpList4"|while read x; do grep -a -F -- "${x}" "$tmpList" ; done | awk '{print $1}' > "$tmpList5"

	total=$(wc -l "$tmpList5")
	echo "Downloading: $total songs from playlist $name"

	n=1
	cat "$tmpList5" | while read x; do
		progress $n $total $name
		((n++))
		downloadSong "https://music.youtube.com/watch?v=${x}" "${outDir}/${name}/%(title)s.%(ext)s"
		
	done

	rm "ytdl.tmp.*"
}

# url outloc

function pidWait {
	while kill -0 "$1" 2>/dev/null; do
		sleep 1
	done
}

function install {
	pkg upgrade
	pkg install python-pip ffmpeg
	pip3 install yt-dlp --upgrade
}

output="/storage/emulated/0/Music"

function download {
        echo "downloading..."
        # You need to edit this part. the automatic output is the music folder.
        # The only things necessary to configure are the name of the playlists and the playlist URL.
        # The playlist must be either on "public" or "unlisted" (Unlisted is better for privacy)
        # Also remove the comment (this charecter -> #) at the start. otherwise it will be ignored 
        
        # playlistDownload "name-of-playlist"   "$output"       "https://music.youtube.com/playlist?list=blablabla"
        # playlistDownload ""   "$output"       ""
        # playlistDownload ""   "$output"       ""
        # playlistDownload ""   "$output"       ""
        # playlistDownload ""   "$output"       ""
        # playlistDownload ""   "$output"       ""
        # playlistDownload ""   "$output"       ""
        # playlistDownload ""   "$output"       ""
	
	chown -R media_rw:media_rw ${output} &
	chmod 644 -R ${output}

}

echo "1/a. download all music"
echo "2/b. download one song"
echo "3/c. lock the directory and fork to download multiple songs quicker"
echo "4/d. update yt-dlp"

if [ -z $1 ]; then
	read opt
else
	opt=$1
fi

[ $opt = 'a' ] && opt=1
[ $opt = 'b' ] && opt=2
[ $opt = 'c' ] && opt=3
[ $opt = 'd' ] && opt=4

if [ $opt -eq 1 ]; then
	download

elif [ $opt -eq 2 ]; then
	echo "url?"
	read url
	echo "directory?"
	read dir

	downloadSong "${url}" "${output}/${dir}/%(title)s.%(ext)s"
elif [ $opt -eq 3 ]; then
	echo 'directory?'
	read dir
	until [ "$url" == "e" ]; do
		echo "url?"
		read url
		if [ "$url" = "e" ]; then
			break
		fi
		echo "${url} to ${output}/${dir}"
		downloadSong "${url}" "${output}/${dir}/%(title)s.%(ext)s" &
	done
elif [ $opt -eq 4 ]; then
	install
else
	download
fi
