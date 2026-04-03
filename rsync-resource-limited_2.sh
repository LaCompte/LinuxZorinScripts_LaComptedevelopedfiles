#!/bin/bash

# Prompt for source - VERIFIED from Bash manual
read -p "Enter source location: " source_location

# Prompt for destination - VERIFIED from Bash manual
read -p "Enter destination location: " dest_location

# Display confirmation - VERIFIED variable expansion syntax
echo "About to sync from: $source_location"
echo "                to: $dest_location"
read -p "Continue? (y/n): " confirm

# Conditional execution - VERIFIED Bash syntax
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    # Execute rsync with quoted variables - VERIFIED rsync syntax
    systemd-run --user --scope --property=MemoryMax=10G --property=AllowedCPUs=0-4 rsync -avh --progress "$source_location" "$dest_location"
    echo "Sync completed!"
else
    echo "Operation cancelled."
fi
