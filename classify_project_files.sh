#!/bin/bash

# Project File Classifier Script
# This script helps classify files that don't have clear project indicators in their names

LOG_FILE=~/project_classification_log.txt
CLASSIFIED_DIR=~/classified_project_files

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Project classification log created on $(date)" > "$LOG_FILE"
fi

echo "=== Starting project classification on $(date) ===" >> "$LOG_FILE"

# Create classified directory structure
mkdir -p "$CLASSIFIED_DIR"/{NHSD,KKO,"La Compte","Reach to be Heard","Unknown Projects"}

# Function to analyze file content for project keywords
analyze_file_content() {
    local file_path=$1
    local file_type=${1##*.}
    local keywords_found=""
    
    case "$file_type" in
        pdf|txt|doc|docx)
            # For text-based files, try to extract some content
            if command -v pdftotext >/dev/null 2>&1 && [[ "$file_type" == "pdf" ]]; then
                content=$(pdftotext "$file_path" - 2>/dev/null | head -20)
            elif command -v strings >/dev/null 2>&1; then
                content=$(strings "$file_path" 2>/dev/null | head -20)
            else
                content=""
            fi
            
            if [[ -n "$content" ]]; then
                if echo "$content" | grep -qi "NHSD\|National Humanitarian Society for Development"; then
                    keywords_found="NHSD"
                elif echo "$content" | grep -qi "KKO\|Khubaib Khalil Organization"; then
                    keywords_found="KKO"
                elif echo "$content" | grep -qi "La Compte"; then
                    keywords_found="La Compte"
                elif echo "$content" | grep -qi "Reach to be heard\|Reach to be Heard"; then
                    keywords_found="Reach to be Heard"
                fi
            fi
            ;;
    esac
    
    echo "$keywords_found"
}

# Function to get user input for classification
classify_interactively() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    
    echo "=========================================="
    echo "File: $file_name"
    echo "Path: $file_path"
    echo "Size: $(stat -c %s "$file_path" | numfmt --to=iec)"
    echo "Modified: $(stat -c %y "$file_path")"
    
    # Try automated analysis first
    auto_classification=$(analyze_file_content "$file_path")
    if [[ -n "$auto_classification" ]]; then
        echo "Suggested classification: $auto_classification"
        read -p "Accept suggestion? (y/n/skip): " accept
        if [[ "$accept" == "y" ]]; then
            echo "$auto_classification"
            return
        fi
    fi
    
    echo "Choose project category:"
    echo "1) NHSD"
    echo "2) KKO" 
    echo "3) La Compte"
    echo "4) Reach to be Heard"
    echo "5) Unknown Projects"
    echo "6) Skip this file"
    
    read -p "Enter choice (1-6): " choice
    
    case $choice in
        1) echo "NHSD" ;;
        2) echo "KKO" ;;
        3) echo "La Compte" ;;
        4) echo "Reach to be Heard" ;;
        5) echo "Unknown Projects" ;;
        6) echo "SKIP" ;;
        *) echo "Unknown Projects" ;;
    esac
}

# Function to process unclassified files
process_unclassified_files() {
    local source_dir=$1
    
    echo "Processing unclassified files from $source_dir..." | tee -a "$LOG_FILE"
    
    # Find files that don't have obvious project indicators
    find "$source_dir" -type f \( \
        -name "*.doc" -o -name "*.docx" -o \
        -name "*.xls*" -o \
        -name "*.ppt" -o -name "*.pptx" -o \
        -name "*.pdf" -o \
        -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \
    \) ! -path "*/Backup Data Chromebook/*" \
      ! -path "*/.cache/*" \
      ! -name "*github*" \
      ! -name "*NHSD*" \
      ! -name "*KKO*" \
      ! -name "*La Compte*" \
      ! -name "*Reach to be heard*" \
      ! -name "*Reach to be Heard*" \
      ! -path "*/NHSD/*" \
      ! -path "*/KKO/*" \
      ! -path "*/La Compte/*" \
      ! -path "*/Reach to be heard/*" \
      ! -path "*/Reach to be Heard/*" \
    | while read file; do
        
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        classification=$(classify_interactively "$file")
        
        if [[ "$classification" != "SKIP" ]]; then
            target_dir="$CLASSIFIED_DIR/$classification"
            file_name=$(basename "$file")
            
            # Create unique filename if it already exists
            counter=1
            original_name="$file_name"
            while [[ -f "$target_dir/$file_name" ]]; do
                name_without_ext="${original_name%.*}"
                extension="${original_name##*.}"
                if [[ "$name_without_ext" == "$extension" ]]; then
                    file_name="${original_name}_${counter}"
                else
                    file_name="${name_without_ext}_${counter}.${extension}"
                fi
                counter=$((counter + 1))
            done
            
            cp "$file" "$target_dir/$file_name"
            echo "Classified: $file -> $classification/$file_name" | tee -a "$LOG_FILE"
        else
            echo "Skipped: $file" | tee -a "$LOG_FILE"
        fi
    done
}

# Function to remove unwanted zip files
remove_unwanted_zip_files() {
    local search_dirs=("$HOME/Documents" "$HOME/rescued_files/Documents" "$HOME/shared_folder_Win7")
    
    echo "Scanning for zip/rar files in all directories..." | tee -a "$LOG_FILE"
    
    # Find all zip/rar files
    local zip_files_found=0
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            zip_files_found=$((zip_files_found + $(find "$dir" -type f \( -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) | wc -l)))
        fi
    done
    
    if [[ $zip_files_found -eq 0 ]]; then
        echo "No zip/rar files found to remove." | tee -a "$LOG_FILE"
        return
    fi
    
    echo "Found $zip_files_found zip/rar files." | tee -a "$LOG_FILE"
    echo "Sample of files to be removed:"
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type f \( -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) | head -5
        fi
    done
    
    echo ""
    echo "This will remove ALL zip, rar, and 7z files from:"
    echo "- ~/Documents"
    echo "- ~/rescued_files/Documents" 
    echo "- ~/shared_folder_Win7"
    echo ""
    read -p "Remove all zip/rar files? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Removing zip/rar files..." | tee -a "$LOG_FILE"
        
        local removed_count=0
        for dir in "${search_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                find "$dir" -type f \( -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) | while read file; do
                    echo "Removing: $(basename "$file")" | tee -a "$LOG_FILE"
                    rm "$file"
                    removed_count=$((removed_count + 1))
                done
            fi
        done
        
        echo "Zip/rar file removal completed." | tee -a "$LOG_FILE"
        
        # Remove empty directories
        for dir in "${search_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                find "$dir" -type d -empty -delete 2>/dev/null
            fi
        done
        
        echo "Empty directories also removed." | tee -a "$LOG_FILE"
    else
        echo "Zip/rar file removal cancelled." | tee -a "$LOG_FILE"
    fi
}

# Interactive mode selection
echo "Project File Classifier & ROM Cleaner"
echo "====================================="
echo "This script will help you classify files and clean up ROM files."
echo ""
echo "Choose mode:"
echo "1) Classify files from ~/Documents"
echo "2) Classify files from ~/rescued_files/Documents" 
echo "3) Classify files from ~/shared_folder_Win7"
echo "4) Classify files from all directories"
echo "5) Show classification statistics"
echo "6) Remove ALL zip/rar files from all directories"
echo "7) Show disk space usage by directory"
echo ""

read -p "Enter choice (1-7): " mode_choice

case $mode_choice in
    1)
        process_unclassified_files ~/Documents
        ;;
    2)
        process_unclassified_files ~/rescued_files/Documents
        ;;
    3)
        process_unclassified_files ~/shared_folder_Win7
        ;;
    4)
        process_unclassified_files ~/Documents
        process_unclassified_files ~/rescued_files/Documents
        process_unclassified_files ~/shared_folder_Win7
        ;;
    5)
        echo "Classification Statistics:"
        echo "=========================="
        for project in "NHSD" "KKO" "La Compte" "Reach to be Heard" "Unknown Projects"; do
            count=$(find "$CLASSIFIED_DIR/$project" -type f 2>/dev/null | wc -l)
            echo "$project: $count files"
        done
        ;;
    6)
        remove_unwanted_zip_files
        ;;
    7)
        echo "Disk Space Usage by Directory:"
        echo "=============================="
        echo "Games folder:"
        du -sh "$HOME/Documents/Games for Fatima Computer" 2>/dev/null || echo "Games folder not found"
        echo ""
        echo "Main directories:"
        du -sh ~/Documents ~/rescued_files/Documents ~/shared_folder_Win7 2>/dev/null
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "=== Classification completed on $(date) ===" >> "$LOG_FILE"
echo "Classified files are stored in: $CLASSIFIED_DIR"
