#!/bin/bash

# SYSTEM MAINTENANCE SUITE

while true; do
    echo ""
    echo "SYSTEM MAINTENANCE SUITE"
    echo ""
    echo "1. Run System Backup"
    echo "2. Perform System Update"
    echo "3. Monitor Logs"
    echo "4. Exit"
    echo ""
    read -p "Enter your choice [1-4]: " choice

    case $choice in
        1) ./backup.sh ;;
        2) ./system_update.sh ;;
        3) ./log_monitoring.sh ;;
        4) echo "Exiting..."; break ;;
        *) echo "Invalid option! Try again." ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
done
