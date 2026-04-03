#!/bin/bash

#getting a reading from the person focusing on where they are going to access the folder
read -p "Enter path to FOLDER with files to work on: " SCAN_PATH
SCAN_PATH="${SCAN_PATH/#\~/$HOME}"
#Ask threshold which will be in MB
read -p "Define what your threshold is in GB  : " THRESHOLD
#confirm if the actual folder exists
if [ -d "$SCAN_PATH" ]; then 
	echo "Folder found. Scanning..."
else 
	echo "This path does not exist, please enter another path"
	exit 1
fi
#search through the folder after it is found, and use the loop to determine the size and path, more accurately, only showing paths with files that fit our threshold. This is only the folder overview. We have not started finding yet.
du --block-size=G --max-depth=3 "$SCAN_PATH" | sort -rn | while read SIZE PATH
do
	SIZE_NUM="${SIZE//G/}"
	if [ "$SIZE_NUM" -ge "$THRESHOLD" ]; then
	echo "$SIZE $PATH"
	fi
done
#before heading over to the next section echo that each file is being individually checked
echo " "
echo "individual files being scanned now"
#find approach is now bieng used to determine the files. Here the file type can be changed dependeing on 
find "$SCAN_PATH" -type f \( -name "*.iso" -o -name "*.deb" -o -name "*.tar.gz" -o -name "*.7z" -o -name "*.zip" \) -size +${THRESHOLD}G -printf "%s\t%f\t%p\n" | awk 'BEGIN{FS="\t"} {printf "%.2fGB\t%s\n", $1/1073741824, $2}'
