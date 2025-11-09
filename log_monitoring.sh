#!/bin/bash

# LOG MONITORING SCRIPT WITH SECURITY FEATURES

LOG_FILE="/var/log/syslog"
ALERT_FILE="/home/$USER/maintenance_logs/log_alerts.log"
KEYWORDS=("error" "failed" "critical" "warning")
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

mkdir -p "$(dirname "$ALERT_FILE")"

echo "$(date): Starting log monitoring..." | tee -a "$ALERT_FILE"
echo "$(date): --------------------------------------------------------" | tee -a "$ALERT_FILE"

# PART 1: Check if main log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log file '$LOG_FILE' does not exist!"
    echo "$(date): ERROR - Log file '$LOG_FILE' not found!" >> "$ALERT_FILE"
    exit 1
fi

# PART 2: Scan logs for keywords
echo ""
echo "1. Scanning System Logs for Issues" | tee -a "$ALERT_FILE"

FOUND_ISSUES=0

for keyword in "${KEYWORDS[@]}"; do
    COUNT=$(grep -ic "$keyword" "$LOG_FILE" 2>/dev/null)
    if [ "$COUNT" -gt 0 ]; then
        echo "$(date): Found $COUNT instances of '$keyword' in syslog" | tee -a "$ALERT_FILE"
        FOUND_ISSUES=$((FOUND_ISSUES + COUNT))

        # Show last 5 occurrences
        echo "  Last 5 occurrences:" >> "$ALERT_FILE"
        grep -i "$keyword" "$LOG_FILE" | tail -5 >> "$ALERT_FILE"
        echo "" >> "$ALERT_FILE"
    fi
done

if [ $FOUND_ISSUES -eq 0 ]; then
    echo "$(date): No critical issues found in logs." | tee -a "$ALERT_FILE"
else
    echo "$(date): Total issues found: $FOUND_ISSUES" | tee -a "$ALERT_FILE"
fi

# PART 3: Security Log Backup & Vulnerability Check
echo "" | tee -a "$ALERT_FILE"
echo "2. Security Log Backup & Vulnerability Check" | tee -a "$ALERT_FILE"

LOGS_TO_BACKUP="/var/log/auth.log /var/log/syslog /var/log/kern.log /var/log/ufw.log /var/log/faillog"
LOG_BACKUP_DIR="/var/security_logs"
LOG_BACKUP_NAME="system_logs_$DATE.tar.gz"

# Create the secure log storage directory (root-owned)
echo "Creating secure log backup directory..." | tee -a "$ALERT_FILE"
if sudo mkdir -p "$LOG_BACKUP_DIR" 2>>"$ALERT_FILE"; then
    echo "$(date): Log backup directory created/verified: $LOG_BACKUP_DIR" >> "$ALERT_FILE"
else
    echo "$(date): WARNING - Could not create log backup directory" | tee -a "$ALERT_FILE"
fi

echo "Archiving critical system logs to $LOG_BACKUP_DIR/$LOG_BACKUP_NAME" | tee -a "$ALERT_FILE"

# Build the tar command with only existing log files
EXISTING_LOGS=""
for log in $LOGS_TO_BACKUP; do
    if [ -f "$log" ]; then
        EXISTING_LOGS="$EXISTING_LOGS $log"
    else
        echo "  Note: $log not found, skipping..." >> "$ALERT_FILE"
    fi
done

# Use 'tar' to compress the logs
if [ -n "$EXISTING_LOGS" ]; then
    if sudo tar -czf "$LOG_BACKUP_DIR/$LOG_BACKUP_NAME" $EXISTING_LOGS 2>>"$ALERT_FILE"; then
        echo "$(date): System logs backed up successfully." | tee -a "$ALERT_FILE"

        # Set secure permissions on the backup
        sudo chmod 600 "$LOG_BACKUP_DIR/$LOG_BACKUP_NAME" 2>>"$ALERT_FILE"

        # Show backup size
        BACKUP_SIZE=$(sudo du -sh "$LOG_BACKUP_DIR/$LOG_BACKUP_NAME" 2>/dev/null | cut -f1)
        echo "  Backup size: $BACKUP_SIZE" | tee -a "$ALERT_FILE"
    else
        echo "$(date): WARNING - Failed to archive system logs. Permissions issue? Check path names." | tee -a "$ALERT_FILE"
    fi
else
    echo "$(date): WARNING - No log files found to backup." | tee -a "$ALERT_FILE"
fi

# VULNERABILITY CHECK: Backup Folder Permissions
echo "" | tee -a "$ALERT_FILE"
echo "3. Backup Folder Vulnerability Check" | tee -a "$ALERT_FILE"

# Check user's backup directory (from backup.sh)
BACKUP_DIR="/home/$USER/Backups"

# Get current permissions (numeric) of the user's backup directory
CURRENT_PERMS=$(stat -c "%a" "$BACKUP_DIR" 2>/dev/null)

# Check if the directory exists first
if [ ! -d "$BACKUP_DIR" ]; then
    echo "$(date): WARNING - Backup directory ($BACKUP_DIR) not found. Cannot check permissions." | tee -a "$ALERT_FILE"
    echo "  Creating backup directory with secure permissions..." | tee -a "$ALERT_FILE"
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
    echo "$(date): Backup directory created with permissions 700." | tee -a "$ALERT_FILE"

# Check if permissions are too open (e.g., 777 or world-writable)
elif [[ "$CURRENT_PERMS" == *7 ]]; then
    echo "$(date): VULNERABILITY ALERT - Backup folder permissions are too lax ($CURRENT_PERMS)." | tee -a "$ALERT_FILE"
    echo "  Remediation: Changing permissions to 700 (Owner only access)..." | tee -a "$ALERT_FILE"
    chmod 700 "$BACKUP_DIR"

    # Re-check to confirm change
    if [ $? -eq 0 ]; then
        NEW_PERMS=$(stat -c "%a" "$BACKUP_DIR" 2>/dev/null)
        echo "$(date): SUCCESS - Permissions changed from $CURRENT_PERMS to $NEW_PERMS." | tee -a "$ALERT_FILE"
    else
        echo "$(date): ERROR - Could not set permissions. Check user ownership." | tee -a "$ALERT_FILE"
    fi
else
    echo "$(date): SUCCESS - Backup folder permissions ($CURRENT_PERMS) look secure (not world-writable)." | tee -a "$ALERT_FILE"
fi

# Check maintenance logs directory permissions
MAINT_LOGS_DIR="/home/$USER/maintenance_logs"
if [ -d "$MAINT_LOGS_DIR" ]; then
    MAINT_PERMS=$(stat -c "%a" "$MAINT_LOGS_DIR" 2>/dev/null)
    if [[ "$MAINT_PERMS" == *7 ]]; then
        echo "$(date): WARNING - Maintenance logs directory has world-writable permissions ($MAINT_PERMS)." | tee -a "$ALERT_FILE"
        chmod 700 "$MAINT_LOGS_DIR"
        echo "$(date): Fixed maintenance logs directory permissions to 700." | tee -a "$ALERT_FILE"
    fi
fi

# CLEANUP: Remove old security log backups (keep last 30 days)
echo "" | tee -a "$ALERT_FILE"
echo "4. Cleaning Old Security Log Backups" | tee -a "$ALERT_FILE"

if [ -d "$LOG_BACKUP_DIR" ]; then
    OLD_LOG_COUNT=$(sudo find "$LOG_BACKUP_DIR" -type f -name 'system_logs_*.tar.gz' -mtime +30 2>/dev/null | wc -l)

    if [ "$OLD_LOG_COUNT" -gt 0 ]; then
        echo "$(date): Found $OLD_LOG_COUNT old security log backup(s) to delete..." | tee -a "$ALERT_FILE"
        sudo find "$LOG_BACKUP_DIR" -type f -name 'system_logs_*.tar.gz' -mtime +30 -delete 2>>"$ALERT_FILE"
        echo "$(date): Old security log backups cleaned up." | tee -a "$ALERT_FILE"
    else
        echo "$(date): No old security log backups to clean up." | tee -a "$ALERT_FILE"
    fi
fi

echo "" | tee -a "$ALERT_FILE"
echo "$(date): Log Backup & Vulnerability Check Complete." | tee -a "$ALERT_FILE"
echo "$(date): --------------------------------------------------------" >> "$ALERT_FILE"
echo ""
echo "Log monitoring completed. Check $ALERT_FILE for details."
