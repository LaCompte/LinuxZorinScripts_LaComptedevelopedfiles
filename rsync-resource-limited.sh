#!/bin/bash

SOURCE="/media/shehrozeameen/New Volume 500GB/BootEFI_ZORINOSIMG.img"
DESTINATION="/media/shehrozeameen/Data Storage Volume/"
CORES="0-4"
THREADS=5
RAM_LIMIT="10G"

systemd-run --user --scope --property=MemoryMax=$RAM_LIMIT --property=AllowedCPUs=$CORES rsync -avz --progress --partial --inplace --bwlimit=0 "$SOURCE" "$DESTINATION"
