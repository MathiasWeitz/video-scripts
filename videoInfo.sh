#!/bin/bash
# Aufruf
#	~/run/videoInfo.sh 
# Alle Videos nach Laufzeit
#	~/run/videoInfo.sh /home/mathias/Pictures/video
# Alle Videos nach Größe
#	~/run/videoInfo.sh -s /home/mathias/Pictures/video
# Alle Videos nach Name
#	~/run/videoInfo.sh -n /home/mathias/Pictures/video

# default is sort by time
sortBySize=false
sortByRate=false
sortByName=false
sortByModified=false
sortByDimension=false

# die Verzeichnis-Tiefe ist deprecated
# im gleichen Verzeichnis
target0Name=true
# im Workingdirectory
target1Name=false
# im Workingdirectory mit Unterpfad
target2Name=false


while [[ "$#" -gt 0 ]]; do
	isPathArg=true
	if [[ $1 == -*\?* ]]; then
		tabs 1,4,8
		echo -e "information of all video-files in directory and subdirectory sorted by runtime\n\t-s\tsorted by size\n\t-r\tsorted by rate\n\t-n\tsorted by name\n\t-m\tsorted by last modified\n\t-d\tsorted by x-dimension"
		tabs -0
		exit 0
	fi
	if [[ $1 == -*s* ]]; then
		isPathArg=false
		sortByName=false
		sortByRate=false
		sortBySize=true
		sortByModified=false
		sortByDimension=false
	fi
	if [[ $1 == -*r* ]]; then
		isPathArg=false
		sortByName=false
		sortByRate=true
		sortBySize=false
		sortByModified=false
		sortByDimension=false
	fi
	if [[ $1 == -*n* ]]; then
		isPathArg=false
		sortByName=true
		sortByRate=false
		sortBySize=false
		sortByModified=false
		sortByDimension=false
	fi
	if [[ $1 == -*m* ]]; then
		isPathArg=false
		sortByName=false
		sortByRate=false
		sortBySize=false
		sortByModified=true
		sortByDimension=false
	fi
	if [[ $1 == -*d* ]]; then
		isPathArg=false
		sortByName=false
		sortByRate=false
		sortBySize=false
		sortByModified=false
		sortByDimension=true
	fi
	if $isPathArg ; then
		src="$1"
		if [[ ! "$1" = /* ]]; then
			# relative path, make it absolute
			src=$(pwd)"/$1"
		fi
	fi
	shift
done

# Länge des Sourceverzeichnis
srcA=(${src//\// })
srcL=${#srcA[@]}
shopt -s nocaseglob

# alle Files aus dem Source
files=$(find $src -type f  \( -iname \*.mp4 -o -iname \*.flv -o -iname \*.webm  -o -iname \*.mkv -o -iname \*.mpg \) -printf "%10s %p\n" | sort -n)
result=""
echo "$files" | { while read line
do
	# echo "$line"
	# remove the size (everything til the first blank)
	filename="/${line#*/}"
	filenameLast="${line##*/}"
	filenameWithoutSuffix="${filename%.*}"
	# echo "$line $filename $filenameLast $filenameWithoutSuffix"
	
	filenameLastWithoutSuffix="${filenameWithoutSuffix##*/}"
	filenameLastPath="${filenameWithoutSuffix%/*}"
	filenameChannel="${filenameLastPath##*/}"
	targetNameLocal1=$(pwd)"/$filenameLastWithoutSuffix"
	targetNameLocal2=$(pwd)"/$filenameChannel/$filenameLastWithoutSuffix"
	
	targetBase=$filenameWithoutSuffix
	if $target1Name ; then
		targetBase=$targetNameLocal1
	fi
	if $target2Name ; then
		targetBase=$targetNameLocal2
		mkdir -p $(pwd)"/$filenameChannel"
	fi
	
	# split by forslash in an array  
	arrIN=(${filename//\// })
	# echo ${#arrIN[@]} ${arrIN[@]}
	# remove the parts from the array, that are in the src
	redPath=${arrIN[@]:$srcL}
	# echo ${#redPath[@]} ${redPath[@]}
	# codec_long_name
	videoData=$(ffprobe -analyzeduration 2147483647 -probesize 2147483647 -v error -of default=noprint_wrappers=1 -select_streams v:0 -show_entries stream=codec_name,width,height,avg_frame_rate:format=duration,size,bit_rate "/$filename")
	# echo "$videoData"
	
	codec=$(sed -n 1p <<< "$videoData")
	codec="${codec#*=}"
	width=$(sed -n 2p <<< "$videoData")
	printf -v width "%04d" ${width#*=}
	height=$(sed -n 3p <<< "$videoData")
	printf -v height "%04d" ${height#*=}
	framerate=$(sed -n 4p <<< "$videoData")
	framerate="${framerate#*=}"
	duration=$(sed -n 5p <<< "$videoData")
	LC_ALL=C printf -v duration "%.*f" 0 "${duration#*=}"
	size=$(sed -n 6p <<< "$videoData")
	size=$(echo "${size#*=}" | numfmt --to=iec)
	bitrate=$(sed -n 7p <<< "$videoData")
	bitrate=$(echo "${bitrate#*=}" | numfmt --to=iec)
	
	videoTimeM=$((duration/60))
	videoTimeS=$((duration%60))
	videoScreenSize="$width"x"$height"
	printf -v videoTimeM "%03d" $videoTimeM
	printf -v videoTimeS "%02d" $videoTimeS
	
	mdate=$(date -r "/$filename" "+%Y-%m-%d %H:%M:%S")
	# target="$filenameWithoutSuffix.01.mp4"
	# echo "/usr/bin/ffmpeg -i \"$filename\" -analyzeduration 2147483647 -probesize 2147483647 -vcodec libx264 -crf 27 -preset veryslow -strict -2 \"$target\""
	
	dots=$(echo "$filenameWithoutSuffix" | tr -cd '.' | wc -c)
	# echo "$dots $filenameWithoutSuffix"
	if false; then
		if [ $dots -eq 0 ]; then
			:
		fi
	fi
	# echo "$framerate"
	# echo -e "$videoTimeM:$videoTimeS\t$videoScreenSize\t$size\t$bitrate\t$codec\t$redPath"
	resultLen=${#result}
	if [[ $resultLen -eq 0 ]]; then
		result="$videoTimeM:$videoTimeS\t$videoScreenSize\t$mdate\t$size\t$bitrate\t$codec\t$filename"
	else
		result="$result\n$videoTimeM:$videoTimeS\t$videoScreenSize\t$mdate\t$size\t$bitrate\t$codec\t$filename"
	fi
done
tabs 1,10,21,45,51,57,64
echo -e "runtime\tdimension\tmodified\tsize\trate\tcodec\tname"
if $sortBySize ; then
	echo -e $result | sort -h -k5
elif $sortByRate ; then
	echo -e $result | sort -h -k6
elif $sortByName ; then
	echo -e $result | sort -fd -k8
elif $sortByModified ; then
	echo -e $result | sort -fd -k3
elif $sortByDimension ; then
	echo -e $result | sort -fd -k2
else
	echo -e $result | sort
fi
tabs -0
}



