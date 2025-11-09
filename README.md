# Bash Script Suite - Complete Guide

## Table of Contents
1. [Installation & Setup](#installation--setup)
2. [Running the Scripts](#running-the-scripts)
3. [Email Configuration](#email-configuration)
4. [Scheduling Automated Backups](#scheduling-automated-backups)
5. [Troubleshooting](#troubleshooting)
6. [Screenshots](#screenshots)

---

## Screenshots

Below are the screenshots you uploaded to the repository. If the files are in the repository root use the paths shown (spaces URL-encoded as %20). If you move them into an `images/` folder, update the paths accordingly.

![Auto Backup](./auto%20backup.png)

![Scheduled Automate Backup](./scheduled%20automate%20backup.png)

![System Log](./system%20log.png)

![Default Run](./Default%20run.png)

![Scheduling Auto Backups](./scheduling%20auto%20backups.png)

![System Update](./System%20update.png)

![Email Not Notify](./Email%20not%20notify.png)

![System Log Ends](./system%20log%20ends.png)

---

## Installation & Setup

### Step 1: Open Terminal
Press `Ctrl + Alt + T` or search for "Terminal" in your Ubuntu applications.

### Step 2: Navigate to the Script Directory
```bash
cd /path/to/your/script/folder
```

**Example:**
```bash
cd "/home/$USER/Documents/MyScripts"
```

### Step 3: Verify All Scripts Are Present
```bash
ls -lh *.sh
```

You should see:
- `autobackup_launcher.sh`
- `backup.sh`
- `log_monitoring.sh`
- `maintenance_suite.sh`
- `system_update.sh`

### Step 4: Make All Scripts Executable
```bash
chmod +x *.sh
```

### Step 5: Verify Permissions
```bash
ls -lh *.sh
```

All scripts should now show `-rwxr-xr-x` (executable).

---

## Running the Scripts

### Option A: Run the Complete Launcher (RECOMMENDED)

#### 1. Basic Run (Interactive Mode)
```bash
./autobackup_launcher.sh
```

This will:
- Show a menu with options
- Ask if you want to run backup now
- Ask if you want to schedule automated backups
- Guide you through the process

#### 2. Run with Custom Suite Path
```bash
./autobackup_launcher.sh /full/path/to/maintenance_suite.sh
```

---

### Option B: Run Individual Scripts

#### Run Backup Script Only
```bash
./backup.sh
```

This will ask you:
- Which directory to backup (shows list of folders in /home/$USER/Documents)
- Where to save the backup
- What compression format (tar.gz, tar.bz2, tar.xz, zip)
- How many days to keep old backups

#### Run Log Monitoring (Requires sudo)
```bash
sudo ./log_monitoring.sh
```

This will:
- Scan system logs for errors
- Backup security logs
- Check folder permissions for vulnerabilities
- Auto-fix insecure permissions (only if confirmed)

#### Run System Update (Requires sudo)
```bash
sudo ./system_update.sh
```

This will:
- Update package lists
- Upgrade all packages
- Remove unnecessary packages
- Clean package cache

#### Run Maintenance Suite Menu
```bash
./maintenance_suite.sh
```

This shows an interactive menu to run any of the above scripts.

---

## Email Configuration

### Step 1: Install Mail Utilities
```bash
sudo apt update
sudo apt install mailutils -y
```

### Step 2: Configure Your Email in the Launcher

#### Method 1: Edit the Script
```bash
nano autobackup_launcher.sh
```

Find this line (around line 11):
```bash
EMAIL="${EMAIL:-admin@localhost}"
```

Change it to:
```bash
EMAIL="${EMAIL:-your.email@gmail.com}"
```

Save with `Ctrl + O`, then `Enter`, then `Ctrl + X`

#### Method 2: Use Environment Variable
```bash
export EMAIL="your.email@gmail.com"
./autobackup_launcher.sh
```

### Step 3: Test Email Functionality
```bash
echo "Test email from Bash Script Suite" | mail -s "Test Email" your.email@gmail.com
```

---

## Scheduling Automated Backups

### Method 1: Using the Launcher (Easy)

1. Run the launcher:
```bash
./autobackup_launcher.sh
```

2. When asked "Run auto-backup now?", choose `n` (or run it first)

3. At "Schedule Automated Backups", select your preferred schedule:
   - `1` = Daily at 2:00 AM
   - `2` = Weekly on Sunday at 2:00 AM
   - `3` = Weekly on Friday at 11:00 PM
   - `4` = Monthly on 1st at 3:00 AM
   - `5` = Custom schedule
   - `6` = Remove existing cron jobs
   - `7` = Skip scheduling

4. Confirm the installation

5. Choose whether to send email after each run

### Method 2: Manual Cron Setup

1. Open crontab editor:
```bash
crontab -e
```

2. Add one of these lines at the bottom (replace `/path/to/your/script/folder` with actual path):

**Daily at 2:00 AM:**
```cron
0 2 * * * /bin/bash "/path/to/your/script/folder/maintenance_suite.sh" >> /home/$USER/maintenance_logs/cron.log 2>&1
```

**Weekly (Sunday at 2:00 AM):**
```cron
0 2 * * 0 /bin/bash "/path/to/your/script/folder/maintenance_suite.sh" >> /home/$USER/maintenance_logs/cron.log 2>&1
```

**With Email Notification:**
```cron
0 2 * * 0 EMAIL=your.email@gmail.com /bin/bash "/path/to/your/script/folder/maintenance_suite.sh" >> /home/$USER/maintenance_logs/cron.log 2>&1 && echo "Backup completed" | mail -s "Backup Success" your.email@gmail.com
```

3. Save and exit:
   - Press `Ctrl + O` to save
   - Press `Enter` to confirm
   - Press `Ctrl + X` to exit

### View Scheduled Jobs
```bash
crontab -l
```

### View Cron Logs
```bash
tail -f /home/$USER/maintenance_logs/cron.log
```

---

## Checking Logs and Results

### View Launcher Logs
```bash
cat /home/$USER/maintenance_logs/autobackup_launcher.log
```

### View Backup Logs
```bash
cat /home/$USER/maintenance_logs/backup.log
```

### View Log Monitoring Alerts
```bash
cat /home/$USER/maintenance_logs/log_alerts.log
```

### View System Update Logs
```bash
cat /home/$USER/maintenance_logs/update.log
```

### View Cron Job Logs
```bash
tail -n 100 /home/$USER/maintenance_logs/cron.log
```

### Check Your Backups
```bash
ls -lh /home/$USER/Backups/
```

### Check Security Log Backups (requires sudo)
```bash
sudo ls -lh /var/security_logs/
```

---

## Troubleshooting

### Issue: "Permission denied" Error
**Solution:**
```bash
cd /path/to/your/script/folder
chmod +x *.sh
```

### Issue: "mail: command not found"
**Solution:**
```bash
sudo apt update
sudo apt install mailutils -y
```

### Issue: Can't Access System Logs
**Solution:** Run with sudo:
```bash
sudo ./log_monitoring.sh
```

### Issue: Cron Job Not Running
**Check if cron is running:**
```bash
sudo systemctl status cron
```

**Start cron if stopped:**
```bash
sudo systemctl start cron
sudo systemctl enable cron
```

**Check cron logs:**
```bash
grep CRON /var/log/syslog | tail -20
```

### Issue: Email Not Sending
**1. Check if mailutils is installed:**
```bash
dpkg -l | grep mailutils
```

**2. Test email manually:**
```bash
echo "Test" | mail -s "Test Subject" your.email@gmail.com
```

**3. Check mail logs:**
```bash
tail -f /var/log/mail.log
```

### Issue: Script Can't Find maintenance_suite.sh
**Solution:** Use absolute path:
```bash
/path/to/your/script/folder/autobackup_launcher.sh /path/to/your/script/folder/maintenance_suite.sh
```

---

## Quick Reference Commands

### Run Everything (Full Interactive Experience)
```bash
cd /path/to/your/script/folder
./autobackup_launcher.sh
```

### Run Quick Backup (Interactive - Choose from Directory List)
```bash
cd /path/to/your/script/folder
./backup.sh
```

### Run System Maintenance with Sudo
```bash
cd /path/to/your/script/folder
sudo ./maintenance_suite.sh
```

### Check All Logs
```bash
cat /home/$USER/maintenance_logs/*.log
```

### Remove All Cron Jobs for This Suite
```bash
crontab -l | grep -v "maintenance_suite.sh" | crontab -
```

---

## Cron Schedule Format Reference

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, Sunday=0 or 7)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

### Examples:
- `0 2 * * *` = Every day at 2:00 AM
- `0 2 * * 0` = Every Sunday at 2:00 AM
- `0 */6 * * *` = Every 6 hours
- `30 1 1 * *` = 1:30 AM on the 1st of every month
- `0 0 * * 1-5` = Midnight, Monday through Friday

---

## Notes

- **Backup Location**: `/home/$USER/Backups/`
- **Security Logs**: `/var/security_logs/` (requires sudo)
- **Log Files**: `/home/$USER/maintenance_logs/`
- **Default Retention**: 7 days for backups, 30 days for security logs
- **Supported Formats**: tar.gz, tar.bz2, tar.xz, zip

---

## Security Best Practices

1. Keep backup folder permissions at `700` (only owner access)
2. Regularly check `/home/$USER/maintenance_logs/log_alerts.log`
3. Review security log backups monthly
4. Use strong passwords for email accounts
5. Monitor disk space: `df -h`
6. Test restore from backups periodically

---

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review log files in `/home/$USER/maintenance_logs/`
3. Verify cron jobs with `crontab -l`
4. Check system logs with `sudo tail -f /var/log/syslog`

---

**Last Updated:** November 9, 2025
**Version:** 1.0
**Compatible With:** Ubuntu 20.04+, Debian-based Linux distributions
