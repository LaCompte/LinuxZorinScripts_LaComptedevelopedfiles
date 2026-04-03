#!/bin/bash

lsblk -la

echo "Enter your source location (confirm with lsblk BEFORE selecting):"
read SOURCE

echo "Enter your destination location (confirm with lsblk BEFORE selecting):"
read DESTINATION

echo "DISCLAIMER: You are attempting to run dd, a disk duplication tool built into Linux which functions as a cloning tool, making exact copies from source to destination. It seems obvious in hindsight but it bears repeating: your destination must ALWAYS be larger - repeating again, LARGER - than the source. This script is structured specifically for disk cloning. If you are running this script, then this disclaimer also warns you about the following: all data in your destination disk will be wiped out, because dd does a full bootsector cloning, and thus it not only cleans out all the data in the destination disk anything in it is also lost and cannot be recovered. If you do not want that and instead want to be able to use your disk as well as have a backup of your source, I recommend making an image. If you want to create a raw image file instead, you will need to run dd separately with your destination as a mount point followed by a filename ending in .img -- for example /path/to/destination/ddimage.img. This script will only produce direct disk clones."

echo ""
sudo -v
echo "Transfer using dd from $SOURCE to $DESTINATION?"
read -p "Confirm (y/n): " confirm


if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    sudo dd if=$SOURCE of=$DESTINATION bs=4M conv=noerror,sync status=progress && echo "Transfer complete." || echo "Transfer failed."
else
    echo "Operation cancelled."
fi
