#!/bin/bash

# SYSTEM UPDATE SCRIPT

LOG_FILE="/home/${SUDO_USER:-$USER}/maintenance_logs/update.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
    echo "$(date): Starting System Update"

    echo "$(date): Updating package lists..."
    if sudo apt update; then
        echo "$(date): Package lists updated successfully"
    else
        echo "$(date): ERROR - Failed to update package lists"
        exit 1
    fi

    echo "$(date): Upgrading packages..."
    if sudo apt upgrade -y; then
        echo "$(date): Packages upgraded successfully"
    else
        echo "$(date): ERROR - Failed to upgrade packages"
        exit 1
    fi

    echo "$(date): Removing unnecessary packages..."
    sudo apt autoremove -y

    echo "$(date): Cleaning package cache..."
    sudo apt autoclean

    echo "$(date): System Update Completed Successfully"
} 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "System update completed successfully!"
echo "Log file: $LOG_FILE"
