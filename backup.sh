#!/bin/bash

# ENHANCED BACKUP SCRIPT WITH USER INTERACTION

# Default Configuration
DEFAULT_SRC_DIR="/home/$USER/Documents"
DEFAULT_BACKUP_DIR="/home/$USER/Backups"
RETENTION_DAYS=7  # Keep backups for 7 days (modify as needed)
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="/home/$USER/maintenance_logs/backup.log"

# Setup
mkdir -p "$DEFAULT_BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# User Interaction
echo ""
echo "BACKUP CONFIGURATION"
echo ""

# Show available directories in Documents folder
echo "Available directories in /home/$USER/Documents:"
echo ""

# Build array of directories
DIRS=()
DIR_COUNT=0

# Add option to backup entire Documents folder
DIRS[0]="/home/$USER/Documents (Entire Documents folder)"
DIR_COUNT=$((DIR_COUNT + 1))

# List subdirectories in Documents
if [ -d "/home/$USER/Documents" ]; then
    while IFS= read -r dir; do
        if [ -d "$dir" ]; then
            DIRS[$DIR_COUNT]="$dir"
            DIR_COUNT=$((DIR_COUNT + 1))
        fi
    done < <(find "/home/$USER/Documents" -mindepth 1 -maxdepth 1 -type d | sort)
fi

# Display menu
if [ ${#DIRS[@]} -eq 1 ]; then
    echo "  1. ${DIRS[0]}"
    echo ""
    echo "  (No subdirectories found in Documents)"
else
    for i in "${!DIRS[@]}"; do
        echo "  $((i+1)). ${DIRS[$i]}"
    done
fi

echo "  $((DIR_COUNT+1)). Custom path (enter manually)"
echo "  $((DIR_COUNT+2)). Backup /home/$USER (Entire home directory)"
echo ""

# Ask user to choose
read -p "Select directory to backup [1-$((DIR_COUNT+2)), default: 1]: " dir_choice
dir_choice=${dir_choice:-1}

# Validate and set source directory
if [[ "$dir_choice" =~ ^[0-9]+$ ]] && [ "$dir_choice" -ge 1 ] && [ "$dir_choice" -le $DIR_COUNT ]; then
    # User selected from list
    SELECTED_INDEX=$((dir_choice - 1))
    if [ $SELECTED_INDEX -eq 0 ]; then
        SRC_DIR="/home/$USER/Documents"
    else
        SRC_DIR="${DIRS[$SELECTED_INDEX]}"
    fi
elif [ "$dir_choice" -eq $((DIR_COUNT+1)) ]; then
    # Custom path
    read -p "Enter custom directory path: " SRC_DIR
elif [ "$dir_choice" -eq $((DIR_COUNT+2)) ]; then
    # Entire home directory
    SRC_DIR="/home/$USER"
else
    echo "Invalid choice. Using default: /home/$USER/Documents"
    SRC_DIR="/home/$USER/Documents"
fi

# Validate source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Source directory '$SRC_DIR' does not exist!"
    echo "$(date): ERROR - Source directory '$SRC_DIR' does not exist!" >> "$LOG_FILE"
    exit 1
fi

echo "Selected: $SRC_DIR"

# Ask for backup destination
echo ""
read -p "Enter backup destination [default: $DEFAULT_BACKUP_DIR]: " BACKUP_DIR
BACKUP_DIR="${BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Ask for compression format
echo ""
echo "Select compression format:"
echo "1. tar.gz (gzip - fast, good compression)"
echo "2. tar.bz2 (bzip2 - slower, better compression)"
echo "3. tar.xz (xz - slowest, best compression)"
echo "4. zip (cross-platform compatible)"
read -p "Enter your choice [1-4, default: 1]: " format_choice
format_choice="${format_choice:-1}"

case $format_choice in
    1)
        FORMAT="tar.gz"
        TAR_CMD="tar -czf"
        ;;
    2)
        FORMAT="tar.bz2"
        TAR_CMD="tar -cjf"
        ;;
    3)
        FORMAT="tar.xz"
        TAR_CMD="tar -cJf"
        ;;
    4)
        FORMAT="zip"
        TAR_CMD="zip -r"
        ;;
    *)
        echo "Invalid choice. Using default (tar.gz)"
        FORMAT="tar.gz"
        TAR_CMD="tar -czf"
        ;;
esac

BACKUP_NAME="backup_$DATE.$FORMAT"

# Ask for retention policy
read -p "Keep backups for how many days? [default: $RETENTION_DAYS]: " user_retention
RETENTION_DAYS="${user_retention:-$RETENTION_DAYS}"

# Validate retention days is a number
if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Invalid retention days. Using default: 7"
    RETENTION_DAYS=7
fi

# Confirmation
echo ""
echo "BACKUP SUMMARY"
echo ""
echo "Source:      $SRC_DIR"
echo "Destination: $BACKUP_DIR/$BACKUP_NAME"
echo "Format:      $FORMAT"
echo "Retention:   $RETENTION_DAYS days"
echo ""
read -p "Proceed with backup? [Y/n]: " confirm
confirm="${confirm:-Y}"

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Backup cancelled by user."
    echo "$(date): Backup cancelled by user." >> "$LOG_FILE"
    exit 0
fi

# Start Backup Process
echo ""
echo "$(date): Starting backup of $SRC_DIR to $BACKUP_DIR/$BACKUP_NAME" | tee -a "$LOG_FILE"
echo "$(date): --------------------------------------------------------" >> "$LOG_FILE"

# Calculate source size
SRC_SIZE=$(du -sh "$SRC_DIR" 2>/dev/null | cut -f1)
echo "Source size: $SRC_SIZE" | tee -a "$LOG_FILE"

# Create backup
if [ "$FORMAT" = "zip" ]; then
    # Zip command has different syntax
    (cd "$(dirname "$SRC_DIR")" && zip -r "$BACKUP_DIR/$BACKUP_NAME" "$(basename "$SRC_DIR")") 2>>"$LOG_FILE"
else
    # Tar commands
    $TAR_CMD "$BACKUP_DIR/$BACKUP_NAME" "$SRC_DIR" 2>>"$LOG_FILE"
fi

# Check backup success
if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_NAME" 2>/dev/null | cut -f1)
    echo "$(date): Backup successful - $BACKUP_NAME (Size: $BACKUP_SIZE)" | tee -a "$LOG_FILE"

    # Cleanup/Rotation
    echo "$(date): Starting cleanup (deleting backups older than $RETENTION_DAYS days)..." >> "$LOG_FILE"

    # Find and delete old backups
    DELETED_COUNT=0
    while IFS= read -r old_backup; do
        if [ -n "$old_backup" ]; then
            echo "  Deleting old backup: $(basename "$old_backup")" | tee -a "$LOG_FILE"
            rm -f "$old_backup"
            ((DELETED_COUNT++))
        fi
    done < <(find "$BACKUP_DIR" -type f \( -name 'backup_*.tar.gz' -o -name 'backup_*.tar.bz2' -o -name 'backup_*.tar.xz' -o -name 'backup_*.zip' \) -mtime +"$RETENTION_DAYS" 2>>"$LOG_FILE")

    if [ $DELETED_COUNT -gt 0 ]; then
        echo "$(date): Cleanup successful. Deleted $DELETED_COUNT old backup(s)." | tee -a "$LOG_FILE"
    else
        echo "$(date): Cleanup successful. No old backups to delete." | tee -a "$LOG_FILE"
    fi

    # Display current backups
    CURRENT_COUNT=$(find "$BACKUP_DIR" -type f \( -name 'backup_*.tar.gz' -o -name 'backup_*.tar.bz2' -o -name 'backup_*.tar.xz' -o -name 'backup_*.zip' \) 2>/dev/null | wc -l)
    echo "$(date): Current backup count: $CURRENT_COUNT" >> "$LOG_FILE"

else
    # Backup failed
    echo "$(date): Backup failed for $BACKUP_NAME. Check preceding entries for errors." | tee -a "$LOG_FILE"
    # Remove incomplete archive to save space
    if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
        echo "$(date): Removing incomplete backup file..." | tee -a "$LOG_FILE"
        rm -f "$BACKUP_DIR/$BACKUP_NAME"
    fi
    echo "$(date): --------------------------------------------------------" >> "$LOG_FILE"
    exit 1
fi

echo "$(date): --------------------------------------------------------" >> "$LOG_FILE"
echo ""
echo "Backup completed successfully!"
echo "Log file: $LOG_FILE"
