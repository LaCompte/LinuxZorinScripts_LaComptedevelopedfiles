#!/bin/bash

# Get current date in format DDMMYYYY
CURRENT_DATE=$(date +"%d%m%Y")
FOLDER_NAME="ZORINOSFILES_${CURRENT_DATE}"
LOG_FILE=~/rclone_backup_log.txt

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Backup log file created on $(date)" > "$LOG_FILE"
fi

echo "=== Starting backup process on $(date) ===" >> "$LOG_FILE"

# Check if today's folder already exists
echo "Checking if folder for today already exists..."
FOLDER_EXISTS=$(rclone lsf onedrive: | grep -c "${FOLDER_NAME}")

if [ $FOLDER_EXISTS -gt 0 ]; then
    echo "Folder ${FOLDER_NAME} already exists. Files may have been uploaded today." | tee -a "$LOG_FILE"
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        echo "Operation cancelled. Exiting..." | tee -a "$LOG_FILE"
        exit 0
    fi
fi

# Create destination folder in OneDrive
echo "Creating folder ${FOLDER_NAME} in OneDrive..." | tee -a "$LOG_FILE"
rclone mkdir onedrive:${FOLDER_NAME}

# Create category folders
echo "Creating category folders..." | tee -a "$LOG_FILE"
rclone mkdir onedrive:${FOLDER_NAME}/"Documents (sorting required)"
rclone mkdir onedrive:${FOLDER_NAME}/"Documents (sorting required)/Word Files"
rclone mkdir onedrive:${FOLDER_NAME}/"Documents (sorting required)/Excel Files"
rclone mkdir onedrive:${FOLDER_NAME}/"Documents (sorting required)/Image Files"
rclone mkdir onedrive:${FOLDER_NAME}/"Documents (sorting required)/PowerPoint Files"
rclone mkdir onedrive:${FOLDER_NAME}/"Documents (sorting required)/Graphic Designing Files"
rclone mkdir onedrive:${FOLDER_NAME}/"Documents (sorting required)/Print Docs"
rclone mkdir onedrive:${FOLDER_NAME}/"Zip Files (sorting required)"

# Create project-specific folders
rclone mkdir onedrive:${FOLDER_NAME}/"Project Files"
rclone mkdir onedrive:${FOLDER_NAME}/"Project Files/NHSD"
rclone mkdir onedrive:${FOLDER_NAME}/"Project Files/KKO"
rclone mkdir onedrive:${FOLDER_NAME}/"Project Files/La Compte"
rclone mkdir onedrive:${FOLDER_NAME}/"Project Files/Reach to be Heard"
rclone mkdir onedrive:${FOLDER_NAME}/"Project Files/Other Projects"

# Function to check if file was previously processed
check_if_processed() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    local file_size=$(stat -c %s "$file_path")
    local file_hash=$(md5sum "$file_path" | cut -d ' ' -f 1)
    
    if grep -q "$file_hash $file_size $file_name" "$LOG_FILE"; then
        return 0  # File was processed before
    else
        return 1  # File was not processed
    fi
}

# Function to record processed file
record_processed_file() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    local file_size=$(stat -c %s "$file_path")
    local file_hash=$(md5sum "$file_path" | cut -d ' ' -f 1)
    
    echo "$file_hash $file_size $file_name" >> "$LOG_FILE"
}

# Function to check if file should be excluded
should_exclude_file() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    
    # Exclude files in cache/backup directories
    if [[ "$file_path" == *"/Backup Data Chromebook/"* ]]; then
        return 0  # Exclude
    fi
    
    if [[ "$file_path" == *"/.cache/"* ]]; then
        return 0  # Exclude
    fi
    
    # Exclude Games directory (ROMs and emulator files)
    if [[ "$file_path" == *"/Games for Fatima Computer/"* ]]; then
        return 0  # Exclude
    fi
    
    # Exclude ALL zip and rar files
    if [[ "$file_name" == *.zip ]] || [[ "$file_name" == *.rar ]] || [[ "$file_name" == *.7z ]]; then
        return 0  # Exclude
    fi
    
    # Exclude GitHub thumbnails and system files
    if [[ "$file_name" == *"github"* ]]; then
        return 0  # Exclude
    fi
    
    # Exclude common system/cache file patterns
    if [[ "$file_path" == *"/snap/"* ]]; then
        return 0  # Exclude
    fi
    
    if [[ "$file_path" == *"/.mozilla/"* ]]; then
        return 0  # Exclude
    fi
    
    if [[ "$file_path" == *"/gnome-software/"* ]]; then
        return 0  # Exclude
    fi
    
    return 1  # Don't exclude
}

# Function to determine project category from filename and path
get_project_category() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    local dir_path=$(dirname "$file_path")
    
    # Check filename first
    if [[ "$file_name" == *"NHSD"* ]]; then
        echo "NHSD"
        return
    elif [[ "$file_name" == *"KKO"* ]]; then
        echo "KKO"
        return
    elif [[ "$file_name" == *"La Compte"* ]]; then
        echo "La Compte"
        return
    elif [[ "$file_name" == *"Reach to be heard"* ]] || [[ "$file_name" == *"Reach to be Heard"* ]]; then
        echo "Reach to be Heard"
        return
    fi
    
    # Check directory path
    if [[ "$dir_path" == *"/NHSD"* ]]; then
        echo "NHSD"
        return
    elif [[ "$dir_path" == *"/KKO"* ]]; then
        echo "KKO"
        return
    elif [[ "$dir_path" == *"/La Compte"* ]]; then
        echo "La Compte"
        return
    elif [[ "$dir_path" == *"/Reach to be heard"* ]] || [[ "$dir_path" == *"/Reach to be Heard"* ]]; then
        echo "Reach to be Heard"
        return
    fi
    
    # Default category
    echo "Other Projects"
}

# Process files by category
process_files() {
    local source_dir=$1
    
    if [ ! -d "$source_dir" ]; then
        echo "$source_dir directory not found!" | tee -a "$LOG_FILE"
        return
    fi
    
    echo "Processing files from $source_dir..." | tee -a "$LOG_FILE"
    
    # Word files
    echo "Processing Word files..." | tee -a "$LOG_FILE"
    find "$source_dir" -type f \( -name "*.doc" -o -name "*.docx" \) -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | while read file; do
        if should_exclude_file "$file"; then
            echo "Excluding $(basename "$file") (system/cache file)" | tee -a "$LOG_FILE"
            continue
        fi
        
        if ! check_if_processed "$file"; then
            project_category=$(get_project_category "$file")
            if [[ "$project_category" != "Other Projects" ]]; then
                echo "Copying $(basename "$file") to Project Files/$project_category..." | tee -a "$LOG_FILE"
                rclone copy "$file" "onedrive:${FOLDER_NAME}/Project Files/$project_category/" --progress
            else
                echo "Copying $(basename "$file") to Word Files..." | tee -a "$LOG_FILE"
                rclone copy "$file" onedrive:${FOLDER_NAME}/"Documents (sorting required)/Word Files/" --progress
            fi
            record_processed_file "$file"
        else
            echo "Skipping $(basename "$file") (already processed)" | tee -a "$LOG_FILE"
        fi
    done
    
    # Excel files
    echo "Processing Excel files..." | tee -a "$LOG_FILE"
    find "$source_dir" -type f -name "*.xls*" -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | while read file; do
        if should_exclude_file "$file"; then
            echo "Excluding $(basename "$file") (system/cache file)" | tee -a "$LOG_FILE"
            continue
        fi
        
        if ! check_if_processed "$file"; then
            project_category=$(get_project_category "$file")
            if [[ "$project_category" != "Other Projects" ]]; then
                echo "Copying $(basename "$file") to Project Files/$project_category..." | tee -a "$LOG_FILE"
                rclone copy "$file" "onedrive:${FOLDER_NAME}/Project Files/$project_category/" --progress
            else
                echo "Copying $(basename "$file") to Excel Files..." | tee -a "$LOG_FILE"
                rclone copy "$file" onedrive:${FOLDER_NAME}/"Documents (sorting required)/Excel Files/" --progress
            fi
            record_processed_file "$file"
        else
            echo "Skipping $(basename "$file") (already processed)" | tee -a "$LOG_FILE"
        fi
    done
    
    # PowerPoint files
    echo "Processing PowerPoint files..." | tee -a "$LOG_FILE"
    find "$source_dir" -type f \( -name "*.ppt" -o -name "*.pptx" \) -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | while read file; do
        if should_exclude_file "$file"; then
            echo "Excluding $(basename "$file") (system/cache file)" | tee -a "$LOG_FILE"
            continue
        fi
        
        if ! check_if_processed "$file"; then
            project_category=$(get_project_category "$file")
            if [[ "$project_category" != "Other Projects" ]]; then
                echo "Copying $(basename "$file") to Project Files/$project_category..." | tee -a "$LOG_FILE"
                rclone copy "$file" "onedrive:${FOLDER_NAME}/Project Files/$project_category/" --progress
            else
                echo "Copying $(basename "$file") to PowerPoint Files..." | tee -a "$LOG_FILE"
                rclone copy "$file" onedrive:${FOLDER_NAME}/"Documents (sorting required)/PowerPoint Files/" --progress
            fi
            record_processed_file "$file"
        else
            echo "Skipping $(basename "$file") (already processed)" | tee -a "$LOG_FILE"
        fi
    done
    
    # Image files (excluding GitHub thumbnails and cache files)
    echo "Processing Image files..." | tee -a "$LOG_FILE"
    find "$source_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | while read file; do
        if should_exclude_file "$file"; then
            echo "Excluding $(basename "$file") (system/cache/GitHub file)" | tee -a "$LOG_FILE"
            continue
        fi
        
        if ! check_if_processed "$file"; then
            project_category=$(get_project_category "$file")
            if [[ "$project_category" != "Other Projects" ]]; then
                echo "Copying $(basename "$file") to Project Files/$project_category..." | tee -a "$LOG_FILE"
                rclone copy "$file" "onedrive:${FOLDER_NAME}/Project Files/$project_category/" --progress
            else
                echo "Copying $(basename "$file") to Image Files..." | tee -a "$LOG_FILE"
                rclone copy "$file" onedrive:${FOLDER_NAME}/"Documents (sorting required)/Image Files/" --progress
            fi
            record_processed_file "$file"
        else
            echo "Skipping $(basename "$file") (already processed)" | tee -a "$LOG_FILE"
        fi
    done
    
    # Graphic Design files
    echo "Processing Graphic Design files..." | tee -a "$LOG_FILE"
    find "$source_dir" -type f \( -name "*.dwg" -o -name "*.ai" -o -name "*.cdr" \) -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | while read file; do
        if should_exclude_file "$file"; then
            echo "Excluding $(basename "$file") (system/cache file)" | tee -a "$LOG_FILE"
            continue
        fi
        
        if ! check_if_processed "$file"; then
            project_category=$(get_project_category "$file")
            if [[ "$project_category" != "Other Projects" ]]; then
                echo "Copying $(basename "$file") to Project Files/$project_category..." | tee -a "$LOG_FILE"
                rclone copy "$file" "onedrive:${FOLDER_NAME}/Project Files/$project_category/" --progress
            else
                echo "Copying $(basename "$file") to Graphic Designing Files..." | tee -a "$LOG_FILE"
                rclone copy "$file" onedrive:${FOLDER_NAME}/"Documents (sorting required)/Graphic Designing Files/" --progress
            fi
            record_processed_file "$file"
        else
            echo "Skipping $(basename "$file") (already processed)" | tee -a "$LOG_FILE"
        fi
    done
    
    # Print documents
    echo "Processing Print documents..." | tee -a "$LOG_FILE"
    find "$source_dir" -type f \( -name "*.pdf" -o -name "*.epub" \) -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | while read file; do
        if should_exclude_file "$file"; then
            echo "Excluding $(basename "$file") (system/cache file)" | tee -a "$LOG_FILE"
            continue
        fi
        
        if ! check_if_processed "$file"; then
            project_category=$(get_project_category "$file")
            if [[ "$project_category" != "Other Projects" ]]; then
                echo "Copying $(basename "$file") to Project Files/$project_category..." | tee -a "$LOG_FILE"
                rclone copy "$file" "onedrive:${FOLDER_NAME}/Project Files/$project_category/" --progress
            else
                echo "Copying $(basename "$file") to Print Docs..." | tee -a "$LOG_FILE"
                rclone copy "$file" onedrive:${FOLDER_NAME}/"Documents (sorting required)/Print Docs/" --progress
            fi
            record_processed_file "$file"
        else
            echo "Skipping $(basename "$file") (already processed)" | tee -a "$LOG_FILE"
        fi
    done
    
    # Zip and RAR files - DISABLED (all zip files are now excluded in should_exclude_file function)
    # echo "Processing Zip and RAR files under 30MB..." | tee -a "$LOG_FILE"
    # find "$source_dir" -type f \( -name "*.zip" -o -name "*.rar" \) -size -30M -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | while read file; do
    #     if should_exclude_file "$file"; then
    #         echo "Excluding $(basename "$file") (system/cache file)" | tee -a "$LOG_FILE"
    #         continue
    #     fi
    #     
    #     if ! check_if_processed "$file"; then
    #         project_category=$(get_project_category "$file")
    #         if [[ "$project_category" != "Other Projects" ]]; then
    #             echo "Copying $(basename "$file") to Project Files/$project_category..." | tee -a "$LOG_FILE"
    #             rclone copy "$file" "onedrive:${FOLDER_NAME}/Project Files/$project_category/" --progress
    #         else
    #             echo "Copying $(basename "$file") to Zip Files..." | tee -a "$LOG_FILE"
    #             rclone copy "$file" onedrive:${FOLDER_NAME}/"Zip Files (sorting required)/" --progress
    #         fi
    #         record_processed_file "$file"
    #     else
    #         echo "Skipping $(basename "$file") (already processed)" | tee -a "$LOG_FILE"
    #     fi
    # done
}

# Process files from all directories
process_files ~/Documents
process_files ~/rescued_files/Documents
process_files ~/shared_folder_Win7

echo "Backup completed on $(date)" | tee -a "$LOG_FILE"
echo "=== Backup process completed on $(date) ===" >> "$LOG_FILE"
echo "All files copied to OneDrive ${FOLDER_NAME} folder!"
echo "Project files have been organized by category in the Project Files folder."
