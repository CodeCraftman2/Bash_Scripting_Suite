#!/bin/bash

# AUTOBACKUP LAUNCHER SCRIPT
# Usage: ./autobackup_launcher.sh [/full/path/to/maintenance_suite.sh]
# Configure: set EMAIL inside this script or export before running.

# CONFIGURATION
EMAIL="${EMAIL:-admin@localhost}"  # Set your email here or export EMAIL variable
DEFAULT_SUITE="./maintenance_suite.sh"
LOG_FILE="/home/$USER/maintenance_logs/autobackup_launcher.log"
CRON_LOG="/home/$USER/maintenance_logs/cron.log"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# SETUP
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$CRON_LOG")"

# HELPER FUNCTIONS
timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

log_message() {
    echo "[$(timestamp)] $1" | tee -a "$LOG_FILE"
}

send_email() {
    local subject="$1"
    local body="$2"

    # Check if email is configured
    if [[ "$EMAIL" == "admin@localhost" ]] || [[ -z "$EMAIL" ]]; then
        log_message "WARNING: Email not configured. Skipping email notification."
        log_message "Set EMAIL variable to receive notifications."
        return 1
    fi

    # Try mail command first (mailutils package)
    if command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "$subject" "$EMAIL"
        if [ $? -eq 0 ]; then
            log_message "Email sent successfully via 'mail' to $EMAIL"
            return 0
        fi
    fi

    # Try sendmail as fallback
    if command -v sendmail >/dev/null 2>&1; then
        printf "To: %s\nSubject: %s\n\n%s\n" "$EMAIL" "$subject" "$body" | sendmail -t
        if [ $? -eq 0 ]; then
            log_message "Email sent successfully via 'sendmail' to $EMAIL"
            return 0
        fi
    fi

    # No mail system available
    log_message "ERROR: No mail/sendmail command found. Install mailutils or sendmail."
    log_message "Install with: sudo apt install mailutils"
    return 1
}

check_mail_setup() {
    if ! command -v mail >/dev/null 2>&1 && ! command -v sendmail >/dev/null 2>&1; then
        echo ""
        echo "WARNING: No mail system detected!"
        echo "Install mailutils to enable email notifications:"
        echo "  sudo apt install mailutils"
        echo ""
        read -p "Continue without email notifications? [y/N] " continue_no_mail
        if [[ ! "$continue_no_mail" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

display_banner() {
    echo ""
    echo "AUTOBACKUP LAUNCHER & SCHEDULER"
    echo ""
    echo "Date: $(date)"
    echo "Suite: $SUITE_PATH"
    echo "Email: $EMAIL"
    echo "Log: $LOG_FILE"
    echo ""
}

# RESOLVE SUITE PATH
SUITE_PATH="${1:-$DEFAULT_SUITE}"

# Get absolute path
if [ -f "$SUITE_PATH" ]; then
    SUITE_PATH="$(cd "$(dirname "$SUITE_PATH")" && pwd)/$(basename "$SUITE_PATH")"
else
    # Try to find in current directory
    CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ -f "$CURRENT_DIR/maintenance_suite.sh" ]; then
        SUITE_PATH="$CURRENT_DIR/maintenance_suite.sh"
    else
        echo "ERROR: Suite script not found at '$SUITE_PATH'"
        echo "Usage: $0 [/full/path/to/maintenance_suite.sh]"
        exit 1
    fi
fi

# MAIN PROGRAM
display_banner
check_mail_setup

log_message "Autobackup Launcher started"
log_message "Suite path: $SUITE_PATH"

# OPTION 1: RUN BACKUP NOW
echo ""
echo "Option 1: Run Maintenance Suite Now"
echo ""
read -p "Run auto-backup now? [Y/n] " run_now
run_now=${run_now:-Y}

if [[ "$run_now" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Choose execution mode:"
    echo "1. Interactive (with prompts)"
    echo "2. Automated with sudo (recommended for full features)"
    echo "3. Automated without sudo (limited features)"
    read -p "Enter your choice [1-3, default: 1]: " exec_mode
    exec_mode=${exec_mode:-1}

    case $exec_mode in
        1)
            EXEC_CMD="/bin/bash \"$SUITE_PATH\""
            log_message "Running in interactive mode..."
            ;;
        2)
            EXEC_CMD="sudo /bin/bash \"$SUITE_PATH\""
            log_message "Running in automated mode with sudo..."
            ;;
        3)
            EXEC_CMD="/bin/bash \"$SUITE_PATH\""
            log_message "Running in automated mode without sudo..."
            ;;
        *)
            echo "Invalid choice. Using interactive mode."
            EXEC_CMD="/bin/bash \"$SUITE_PATH\""
            ;;
    esac

    echo ""
    echo "Starting maintenance suite..."
    log_message "Executing: $EXEC_CMD"

    start_time="$(timestamp)"
    START_EPOCH=$(date +%s)

    # Run the suite
    if eval $EXEC_CMD; then
        status="SUCCESS"
        exit_code=0
    else
        status="FAILED"
        exit_code=$?
    fi

    END_EPOCH=$(date +%s)
    DURATION=$((END_EPOCH - START_EPOCH))
    end_time="$(timestamp)"

    log_message "Execution completed with status: $status (exit code: $exit_code)"
    log_message "Duration: ${DURATION}s"

    # Prepare email report
    EMAIL_BODY="Autobackup Maintenance Report
Host: $(hostname)
User: $USER
Started: $start_time
Finished: $end_time
Duration: ${DURATION}s
Status: $status
Exit Code: $exit_code

EXECUTION DETAILS:
Command: $EXEC_CMD
Suite Path: $SUITE_PATH

RECENT LOG ENTRIES (Last 50 lines):
$(tail -n 50 "$LOG_FILE" 2>/dev/null || echo 'No log available')

BACKUP STATUS:
$(ls -lh /home/$USER/Backups/ 2>/dev/null | tail -10 || echo 'No backups found')

DISK USAGE:
$(df -h /home 2>/dev/null || echo 'Cannot retrieve disk usage')

This is an automated report from the Autobackup Launcher.
Log file: $LOG_FILE
"

    EMAIL_SUBJECT="[Autobackup] $status on $(hostname) - $(date +'%Y-%m-%d %H:%M')"

    # Send email notification
    echo ""
    read -p "Send email notification? [Y/n] " send_mail
    send_mail=${send_mail:-Y}

    if [[ "$send_mail" =~ ^[Yy]$ ]]; then
        send_email "$EMAIL_SUBJECT" "$EMAIL_BODY"
    fi

    echo ""
    echo "Execution Summary:"
    echo "  Status: $status"
    echo "  Duration: ${DURATION}s"
    echo "  Log: $LOG_FILE"
    echo ""
fi

# OPTION 2: SCHEDULE WITH CRON
echo ""
echo "Option 2: Schedule Automated Backups"
echo ""
echo "Available schedules:"
echo "1. Daily at 2:00 AM"
echo "2. Weekly (Sunday at 2:00 AM)"
echo "3. Weekly (Friday at 11:00 PM)"
echo "4. Monthly (1st of month at 3:00 AM)"
echo "5. Custom schedule"
echo "6. Remove existing cron jobs"
echo "7. Skip scheduling"

read -p "Enter your choice [1-7, default: 7]: " cron_choice
cron_choice=${cron_choice:-7}

case $cron_choice in
    1)
        CRON_SCHEDULE="0 2 * * *"
        CRON_DESC="Daily at 2:00 AM"
        ;;
    2)
        CRON_SCHEDULE="0 2 * * 0"
        CRON_DESC="Weekly on Sunday at 2:00 AM"
        ;;
    3)
        CRON_SCHEDULE="0 23 * * 5"
        CRON_DESC="Weekly on Friday at 11:00 PM"
        ;;
    4)
        CRON_SCHEDULE="0 3 1 * *"
        CRON_DESC="Monthly on 1st at 3:00 AM"
        ;;
    5)
        echo ""
        echo "Enter custom cron schedule (e.g., '0 2 * * *' for daily at 2am):"
        read -p "Schedule: " CRON_SCHEDULE
        CRON_DESC="Custom: $CRON_SCHEDULE"
        ;;
    6)
        # Remove existing cron jobs
        log_message "Removing existing autobackup cron jobs..."
        (crontab -l 2>/dev/null | grep -v "$SUITE_PATH") | crontab -
        echo "Removed all cron jobs for $SUITE_PATH"
        log_message "Removed cron jobs for $SUITE_PATH"
        cron_choice=7  # Skip to end
        ;;
    7)
        echo "Skipping cron scheduling."
        ;;
    *)
        echo "Invalid choice. Skipping cron scheduling."
        cron_choice=7
        ;;
esac

if [[ "$cron_choice" != "6" ]] && [[ "$cron_choice" != "7" ]]; then
    echo ""
    echo "Schedule: $CRON_DESC"
    echo "This will run: $SUITE_PATH"
    read -p "Confirm installation? [y/N] " confirm_cron

    if [[ "$confirm_cron" =~ ^[Yy]$ ]]; then
        # Email notification option for cron
        read -p "Send email after each scheduled run? [Y/n] " cron_email
        cron_email=${cron_email:-Y}

        if [[ "$cron_email" =~ ^[Yy]$ ]]; then
            # Cron with email notification
            CRON_CMD="$CRON_SCHEDULE EMAIL=$EMAIL /bin/bash \"$SUITE_PATH\" >> \"$CRON_LOG\" 2>&1 && echo \"Backup completed at \$(date)\" | mail -s \"Autobackup Success on \$(hostname)\" $EMAIL"
        else
            # Cron without email
            CRON_CMD="$CRON_SCHEDULE /bin/bash \"$SUITE_PATH\" >> \"$CRON_LOG\" 2>&1"
        fi

        # Install cron job (remove old ones first)
        (crontab -l 2>/dev/null | grep -v "$SUITE_PATH"; echo "$CRON_CMD") | crontab -

        log_message "Installed cron job: $CRON_DESC"
        log_message "Cron command: $CRON_CMD"

        echo ""
        echo "Cron job installed successfully!"
        echo "  Schedule: $CRON_DESC"
        echo "  Cron log: $CRON_LOG"
        echo ""
        echo "To view your cron jobs: crontab -l"
        echo "To edit cron jobs: crontab -e"
        echo "To view cron logs: tail -f $CRON_LOG"
    fi
fi

# DISPLAY CURRENT CRON JOBS
echo ""
echo "Current Cron Jobs"
echo ""
if crontab -l 2>/dev/null | grep -q "$SUITE_PATH"; then
    echo "Active autobackup schedules:"
    crontab -l 2>/dev/null | grep "$SUITE_PATH"
else
    echo "No autobackup cron jobs installed."
fi

# FINAL SUMMARY
echo ""
echo "LAUNCHER COMPLETE"
echo ""
echo "Log file: $LOG_FILE"
echo "Cron log: $CRON_LOG"
echo "Email: $EMAIL"
echo ""

log_message "Autobackup Launcher finished"
