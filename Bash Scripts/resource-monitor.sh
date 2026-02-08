#!/bin/bash

# Resource Monitor with Threshold Alerts
# Monitors CPU, Memory, Disk, and Network usage
# Trace execution
set -x              # Print each command

# Configuration
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
ALERT_EMAIL="admin@example.com"
LOG_FILE="/var/log/resource_monitor.log"
CHECK_INTERVAL=60  # seconds
ALERT_COOLDOWN=300  # Don't send same alert within 5 minutes

# Alert tracking
declare -A LAST_ALERT_TIME

# Writes timestamped entries to log file
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Sends notifications via email, system notification, and syslog; includes cooldown logic
send_alert() {
    local alert_type="$1"
    local message="$2"
    local current_time=$(date +%s)
    
    # Check cooldown period
    if [ -n "${LAST_ALERT_TIME[$alert_type]}" ]; then # If LAST_ALERT_TIME["CPU"] exists Returns TRUE (string is not empty)
        local time_diff=$((current_time - LAST_ALERT_TIME[$alert_type]))
        if [ $time_diff -lt $ALERT_COOLDOWN ]; then # If time_diff is less than ALERT_COOLDOWN...
            log_message "Alert suppressed (cooldown): $alert_type"
            return
        fi
    fi
    
    # Update last alert time
    LAST_ALERT_TIME[$alert_type]=$current_time
    
    log_message "ALERT: $message"
    
    # Send email alert (requires mailx or similar)
    # command -v mail
    # -v is an option for the command builtin that checks if a command exists and returns its path
    # If mail exists: prints the path (e.g., /usr/bin/mail)
    # If mail doesn't exist: prints nothing and returns error code
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "Resource Alert: $alert_type - $(hostname)" "$ALERT_EMAIL"
    fi
    
    # Send system notification
    if command -v notify-send &> /dev/null; then
        notify-send "Resource Alert" "$message" -u critical
    fi
    # The &> /dev/null part suppresses any output, so the if just checks the TRUE/FALSE return status:
    # TRUE = mail command exists → send email alert
    # FALSE = mail command doesn't exist → skip this block

    # Log to syslog
    logger -t resource_monitor -p user.warning "$message"
}

# Monitors CPU usage and compares against threshold
check_cpu() {
    # Full system stats, %Cpu(s): 12.5 us, 3.2 sy, 0.0 ni, 83.5 id...,  12.5
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # If top command format differs, try alternative
    if [ -z "$cpu_usage" ]; then
        cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    fi
    
    cpu_usage=${cpu_usage%.*}  # Remove decimal
    
    log_message "CPU Usage: ${cpu_usage}%"
    
    # All processes with details, Sorted by CPU (highest first), First 6 lines (header + top 5), Remove header, keep only 5 processes, Extract: command name, CPU%
    if [ "$cpu_usage" -ge "$CPU_THRESHOLD" ]; then
        local top_processes=$(ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print $11, $3"%"}')
        send_alert "CPU" "CPU usage is at ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)
        
Top CPU processes:
$top_processes"
    fi
    
    echo "$cpu_usage"
}

check_memory() {
    local mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local mem_percent=$((used * 100 / total))
    
    log_message "Memory Usage: ${mem_percent}%"
    
    if [ "$mem_percent" -ge "$MEMORY_THRESHOLD" ]; then
        local top_processes=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{print $11, $4"%"}')
        send_alert "MEMORY" "Memory usage is at ${mem_percent}% (threshold: ${MEMORY_THRESHOLD}%)
        
Top Memory processes:
$top_processes"
    fi
    
    echo "$mem_percent"
}

check_disk() {
    log_message "Disk Usage Check:"
    
    df -h | grep -vE '^Filesystem|tmpfs|cdrom' | while read line; do
        local usage=$(echo $line | awk '{print $5}' | cut -d'%' -f1)
        local mount=$(echo $line | awk '{print $6}')
        local filesystem=$(echo $line | awk '{print $1}')
        
        log_message "  $mount: ${usage}%"
        
        if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
            local large_files=$(du -ah "$mount" 2>/dev/null | sort -rh | head -10)
            send_alert "DISK_${mount}" "Disk usage on $mount is at ${usage}% (threshold: ${DISK_THRESHOLD}%)
Filesystem: $filesystem

Top 10 largest items:
$large_files"
        fi
    done
}

check_network() {
    # Check for high number of connections
    local established=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
    local time_wait=$(netstat -an 2>/dev/null | grep TIME_WAIT | wc -l)
    
    log_message "Network Connections - Established: $established, TIME_WAIT: $time_wait"
    
    if [ "$established" -gt 1000 ]; then
        send_alert "NETWORK_CONNECTIONS" "High number of established connections: $established"
    fi
    
    if [ "$time_wait" -gt 5000 ]; then
        send_alert "NETWORK_TIME_WAIT" "High number of TIME_WAIT connections: $time_wait"
    fi
}

check_load_average() {
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local cpu_cores=$(nproc)
    local load_per_core=$(echo "$load / $cpu_cores" | bc -l | awk '{printf "%.2f", $0}')
    
    log_message "Load Average: $load ($load_per_core per core)"
    
    # Alert if load average per core > 2
    local threshold_check=$(echo "$load_per_core > 2.0" | bc -l)
    if [ "$threshold_check" -eq 1 ]; then
        send_alert "LOAD_AVERAGE" "High load average: $load on $cpu_cores cores ($load_per_core per core)"
    fi
}

check_swap() {
    local swap_info=$(free | grep Swap)
    local total=$(echo $swap_info | awk '{print $2}')
    
    if [ "$total" -gt 0 ]; then
        local used=$(echo $swap_info | awk '{print $3}')
        local swap_percent=$((used * 100 / total))
        
        log_message "Swap Usage: ${swap_percent}%"
        
        if [ "$swap_percent" -ge 50 ]; then
            send_alert "SWAP" "Swap usage is at ${swap_percent}%"
        fi
    fi
}

generate_report() {
    local report_file="/tmp/resource_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
================================================================================
                        RESOURCE MONITORING REPORT
================================================================================
Hostname: $(hostname)
Date: $(date '+%Y-%m-%d %H:%M:%S')
Uptime: $(uptime -p)

THRESHOLDS
--------------------------------------------------------------------------------
CPU: ${CPU_THRESHOLD}%
Memory: ${MEMORY_THRESHOLD}%
Disk: ${DISK_THRESHOLD}%

CURRENT STATUS
--------------------------------------------------------------------------------
CPU Usage: $(check_cpu)%
Memory Usage: $(check_memory)%
Load Average: $(uptime | awk -F'load average:' '{print $2}')

DISK USAGE
--------------------------------------------------------------------------------
$(df -h | grep -vE '^Filesystem|tmpfs|cdrom')

TOP PROCESSES BY CPU
--------------------------------------------------------------------------------
$(ps aux --sort=-%cpu | head -11)

TOP PROCESSES BY MEMORY
--------------------------------------------------------------------------------
$(ps aux --sort=-%mem | head -11)

NETWORK CONNECTIONS
--------------------------------------------------------------------------------
Established: $(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
TIME_WAIT: $(netstat -an 2>/dev/null | grep TIME_WAIT | wc -l)

================================================================================
EOF
    
    echo "$report_file"
}

show_usage() {
    cat << EOF
Resource Monitor with Threshold Alerts

Usage:
    $0 [start|check|report|status|help]

Commands:
    start   - Start continuous monitoring (default)
    check   - Perform single check
    report  - Generate detailed report
    status  - Show current resource usage
    help    - Show this help message

Configuration:
    CPU Threshold: ${CPU_THRESHOLD}%
    Memory Threshold: ${MEMORY_THRESHOLD}%
    Disk Threshold: ${DISK_THRESHOLD}%
    Check Interval: ${CHECK_INTERVAL}s
    Alert Email: ${ALERT_EMAIL}
    Log File: ${LOG_FILE}

Edit this script to modify thresholds and alert settings.
EOF
}

monitor_loop() {
    log_message "Starting resource monitoring (interval: ${CHECK_INTERVAL}s)"
    echo "Resource monitoring started. Press Ctrl+C to stop."
    echo "Logs: $LOG_FILE"
    echo ""
    
    while true; do
        log_message "=== Resource Check ==="
        check_cpu > /dev/null
        check_memory > /dev/null
        check_disk
        check_load_average
        check_swap
        check_network
        log_message "=== Check Complete ==="
        echo ""
        
        sleep $CHECK_INTERVAL
    done
}

single_check() {
    log_message "=== Single Resource Check ==="
    echo "CPU Usage: $(check_cpu)%"
    echo "Memory Usage: $(check_memory)%"
    check_disk
    check_load_average
    check_swap
    check_network
    log_message "=== Check Complete ==="
}

show_status() {
    cat << EOF
Current Resource Status
================================================================================
Hostname: $(hostname)
Time: $(date '+%Y-%m-%d %H:%M:%S')

CPU Usage: $(check_cpu)%
Memory Usage: $(check_memory)%
Load Average: $(uptime | awk -F'load average:' '{print $2}')

Disk Usage:
$(df -h / | tail -1)

Network:
  Established Connections: $(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
================================================================================
EOF
}

# Main execution
mkdir -p "$(dirname "$LOG_FILE")"

# So the case statement checks which command you typed and executes the corresponding section:
# ./resource-monitor.sh report, ./resource-monitor.sh check, ./resource-monitor.sh status, ./resource-monitor.sh
# If you typed check → runs single_check
# If you typed report → runs generate_report
# If you typed status → runs show_status
# If you typed nothing → defaults to start and runs monitor_loop

case "${1:-start}" in
    start)
        monitor_loop
        ;;
    check)
        single_check
        ;;
    report)
        report_file=$(generate_report)
        cat "$report_file"
        echo ""
        echo "Report saved to: $report_file"
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "ERROR: Invalid command"
        echo ""
        show_usage
        exit 1
        ;;
esac

set +x              # Stop tracing

echo ""
echo ""
read -p "Press Enter to close..."
echo ""