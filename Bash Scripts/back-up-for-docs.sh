#!/bin/bash

LOG_FILE="/var/log/backup.log"
BACKUP_DIR="/backups"
SOURCE_DIR="/home/user/documents"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_directory() {
    if [ ! -d "$1" ]; then
        log_message "ERROR: Directory $1 does not exist"
        return 1
    fi
    return 0
}

create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/backup_${timestamp}.tar.gz"
    
    log_message "Starting backup of $SOURCE_DIR"
    
    if tar -czf "$backup_file" "$SOURCE_DIR" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "Backup completed: $backup_file"
        return 0
    else
        log_message "ERROR: Backup failed"
        return 1
    fi
}

# Main execution
if check_directory "$SOURCE_DIR" && check_directory "$BACKUP_DIR"; then
    create_backup
    exit $?
else
    exit 1
fi