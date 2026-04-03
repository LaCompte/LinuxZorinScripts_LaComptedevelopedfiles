#!/bin/bash

# Create log file if it doesn't exist
LOG_FILE=~/rclone_backup_log.txt

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Backup log file created on $(date)" > "$LOG_FILE"
fi

# Ask for backup details
read -p "Enter the date when backup was performed (e.g., 24042025): " BACKUP_DATE
read -p "Enter the OneDrive folder name where files were copied (e.g., ZORINOSFILES_24042025): " FOLDER_NAME

# Log the previous backup
echo "" >> "$LOG_FILE"
echo "=== MANUAL LOG ENTRY ===" >> "$LOG_FILE"
echo "Previous backup performed with destination: onedrive:$FOLDER_NAME" >> "$LOG_FILE"
echo "Files backed up from:" >> "$LOG_FILE"
echo "- ~/Documents" >> "$LOG_FILE"
echo "- ~/rescued_files/Documents" >> "$LOG_FILE"
echo "File types included:" >> "$LOG_FILE"
echo "- Documents: pdf, doc, docx, xls, cdr, ai, dwg, epub, jpg, jpeg, png" >> "$LOG_FILE"
echo "- Archives: zip and rar files under 30MB" >> "$LOG_FILE"
echo "Manual log entry created on $(date)" >> "$LOG_FILE"
echo "=== END OF MANUAL LOG ENTRY ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "Previous backup has been logged to $LOG_FILE"
echo "You can now use the enhanced backup script which will check this log."
