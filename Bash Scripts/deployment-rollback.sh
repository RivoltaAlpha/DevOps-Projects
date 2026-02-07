#!/bin/bash

# Deployment script with rollback capability
# Usage: ./deployment-rollback.sh [deploy|rollback|list]

DEPLOY_DIR="/var/www/app"
BACKUP_DIR="/var/backups/deployments"
LOG_FILE="/var/log/deployment.log"
MAX_BACKUPS=5

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

init_directories() {
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
}

create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="backup_${timestamp}"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    log_message "Creating backup: $backup_name"
    
    if [ -d "$DEPLOY_DIR" ]; then
        if tar -czf "${backup_path}.tar.gz" -C "$(dirname "$DEPLOY_DIR")" "$(basename "$DEPLOY_DIR")" 2>&1 | tee -a "$LOG_FILE"; then
            echo "$timestamp" > "${BACKUP_DIR}/latest_backup.txt"
            log_message "Backup created successfully: ${backup_path}.tar.gz"
            cleanup_old_backups
            return 0
        else
            log_message "ERROR: Backup creation failed"
            return 1
        fi
    else
        log_message "WARNING: Deploy directory does not exist, skipping backup"
        return 0
    fi
}

cleanup_old_backups() {
    local backup_count=$(ls -1 "${BACKUP_DIR}"/backup_*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        log_message "Cleaning up old backups (keeping last $MAX_BACKUPS)"
        ls -1t "${BACKUP_DIR}"/backup_*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f
    fi
}

deploy_application() {
    local source_path="$1"
    
    if [ -z "$source_path" ]; then
        log_message "ERROR: Source path not provided"
        echo "Usage: $0 deploy <source_path>"
        return 1
    fi
    
    if [ ! -e "$source_path" ]; then
        log_message "ERROR: Source path does not exist: $source_path"
        return 1
    fi
    
    log_message "Starting deployment from: $source_path"
    
    # Create backup before deployment
    if ! create_backup; then
        log_message "ERROR: Pre-deployment backup failed, aborting deployment"
        return 1
    fi
    
    # Remove old deployment
    if [ -d "$DEPLOY_DIR" ]; then
        log_message "Removing old deployment"
        rm -rf "$DEPLOY_DIR"
    fi
    
    # Deploy new version
    log_message "Deploying new version"
    if [ -d "$source_path" ]; then
        cp -r "$source_path" "$DEPLOY_DIR"
    elif [ -f "$source_path" ] && [[ "$source_path" == *.tar.gz ]]; then
        mkdir -p "$DEPLOY_DIR"
        tar -xzf "$source_path" -C "$DEPLOY_DIR" --strip-components=1
    else
        log_message "ERROR: Unsupported source format"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Deployment completed successfully"
        
        # Run health check
        if health_check; then
            log_message "Health check passed"
            return 0
        else
            log_message "WARNING: Health check failed, consider rollback"
            return 1
        fi
    else
        log_message "ERROR: Deployment failed"
        return 1
    fi
}

health_check() {
    # Add your health check logic here
    # Example: check if critical files exist
    if [ -d "$DEPLOY_DIR" ]; then
        log_message "Basic health check: Deploy directory exists"
        return 0
    else
        log_message "Health check failed: Deploy directory missing"
        return 1
    fi
}

rollback() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        # Get latest backup
        backup_file=$(ls -1t "${BACKUP_DIR}"/backup_*.tar.gz 2>/dev/null | head -n 1)
    fi
    
    if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
        log_message "ERROR: No backup file found for rollback"
        return 1
    fi
    
    log_message "Starting rollback from: $backup_file"
    
    # Remove current deployment
    if [ -d "$DEPLOY_DIR" ]; then
        log_message "Removing current deployment"
        rm -rf "$DEPLOY_DIR"
    fi
    
    # Restore from backup
    log_message "Restoring from backup"
    mkdir -p "$(dirname "$DEPLOY_DIR")"
    
    if tar -xzf "$backup_file" -C "$(dirname "$DEPLOY_DIR")" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "Rollback completed successfully"
        
        if health_check; then
            log_message "Health check passed after rollback"
            return 0
        else
            log_message "WARNING: Health check failed after rollback"
            return 1
        fi
    else
        log_message "ERROR: Rollback failed"
        return 1
    fi
}

list_backups() {
    echo "Available backups:"
    echo "=================="
    
    if [ -d "$BACKUP_DIR" ]; then
        ls -lh "${BACKUP_DIR}"/backup_*.tar.gz 2>/dev/null | awk '{print $9, "(" $5 ")", $6, $7, $8}'
        
        if [ -f "${BACKUP_DIR}/latest_backup.txt" ]; then
            echo ""
            echo "Latest backup: $(cat "${BACKUP_DIR}/latest_backup.txt")"
        fi
    else
        echo "No backups found"
    fi
}

show_usage() {
    cat << EOF
Deployment Script with Rollback Capability

Usage:
    $0 deploy <source_path>    - Deploy application from source path
    $0 rollback [backup_file]  - Rollback to previous version
    $0 list                    - List available backups
    $0 help                    - Show this help message

Examples:
    $0 deploy /path/to/new/version
    $0 deploy /path/to/app.tar.gz
    $0 rollback
    $0 rollback /var/backups/deployments/backup_20260206_143022.tar.gz

Configuration:
    Deploy Directory: $DEPLOY_DIR
    Backup Directory: $BACKUP_DIR
    Log File: $LOG_FILE
    Max Backups: $MAX_BACKUPS
EOF
}

# Main execution
init_directories

case "$1" in
    deploy)
        deploy_application "$2"
        exit $?
        ;;
    rollback)
        rollback "$2"
        exit $?
        ;;
    list)
        list_backups
        exit 0
        ;;
    help|--help|-h)
        show_usage
        exit 0
        ;;
    *)
        echo "ERROR: Invalid command"
        echo ""
        show_usage
        exit 1
        ;;
esac