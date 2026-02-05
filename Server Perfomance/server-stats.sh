# Goal of this project is to write a script to analyse server performance stats.
# analyse basic server performance stats:
# Total CPU usage
# Total memory usage (Free vs Used including percentage)
# Total disk usage (Free vs Used including percentage)
# Top 5 processes by CPU usage
# Top 5 processes by memory usage
# os version, uptime, load average, logged in users, failed login attempts 

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to calculate percentage
calculate_percentage() {
    awk "BEGIN {printf \"%.2f\", ($1 / $2) * 100}"
}

# Display banner
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║     SERVER PERFORMANCE ANALYZER        ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo "Analysis Date: $(date '+%Y-%m-%d %H:%M:%S')"

# 1. System Information
print_header "SYSTEM INFORMATION"
echo "Hostname: $(hostname)"
if [ -f /etc/os-release ]; then
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
else
    echo "OS: $(uname -s)"
fi
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"

# 2. Total CPU Usage
print_header "CPU USAGE"
cpu_line=$(top -bn1 | grep "Cpu(s)" | head -1)
if [ -n "$cpu_line" ]; then
    cpu_usage=$(echo "$cpu_line" | awk '{print $2}' | sed 's/%us,//')
    cpu_idle=$(echo "$cpu_line" | awk '{print $8}' | sed 's/%id,//')
    echo "CPU Usage: ${cpu_usage}%"
    echo "CPU Idle: ${cpu_idle}%"
fi

# Number of CPU cores
cpu_cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
echo "CPU Cores: $cpu_cores"

# 3. Memory Usage
print_header "MEMORY USAGE"
mem_info=$(free -m)
mem_total=$(echo "$mem_info" | awk 'NR==2{print $2}')
mem_used=$(echo "$mem_info" | awk 'NR==2{print $3}')
mem_free=$(echo "$mem_info" | awk 'NR==2{print $4}')
mem_available=$(echo "$mem_info" | awk 'NR==2{print $7}')
mem_percentage=$(calculate_percentage $mem_used $mem_total)

echo "Total Memory: ${mem_total} MB"
echo "Used Memory: ${mem_used} MB (${mem_percentage}%)"
echo "Free Memory: ${mem_free} MB"
echo "Available Memory: ${mem_available} MB"

# Memory usage bar
used_bars=$(awk "BEGIN {printf \"%d\", $mem_percentage / 2}")
free_bars=$(awk "BEGIN {printf \"%d\", 50 - $used_bars}")
echo -ne "\nMemory Usage Bar: ["
printf "${RED}%${used_bars}s${NC}" | tr ' ' '█'
printf "${GREEN}%${free_bars}s${NC}" | tr ' ' '░'
echo "] ${mem_percentage}%"

# Swap usage
swap_total=$(echo "$mem_info" | awk 'NR==3{print $2}')
swap_used=$(echo "$mem_info" | awk 'NR==3{print $3}')
swap_free=$(echo "$mem_info" | awk 'NR==3{print $4}')
if [ "$swap_total" -gt 0 ] 2>/dev/null; then
    swap_percentage=$(calculate_percentage $swap_used $swap_total)
    echo -e "\nSwap Total: ${swap_total} MB"
    echo "Swap Used: ${swap_used} MB (${swap_percentage}%)"
    echo "Swap Free: ${swap_free} MB"
fi

# 4. Disk Usage
print_header "DISK USAGE"
echo "Filesystem Usage:"
df -h | grep -v tmpfs | grep -v devtmpfs | awk 'BEGIN {printf "%-25s %10s %10s %10s %8s  %s\n", "Filesystem", "Size", "Used", "Avail", "Use%", "Mounted"} NR==1 {next} /^\/dev\// {printf "%-25s %10s %10s %10s %8s  %s\n", $1, $2, $3, $4, $5, $6}'

echo -e "\nRoot Filesystem Summary:"
df -h / | tail -n 1 | awk '{
    printf "  Total: %s | Used: %s | Free: %s | Usage: %s\n", $2, $3, $4, $5
}'

# 5. Top 5 Processes by CPU Usage
print_header "TOP 5 PROCESSES BY CPU USAGE"
printf "%-10s %-12s %8s %8s  %-s\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
echo "------------------------------------------------------------"
ps aux --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "%-10s %-12s %7s%% %7s%%  %-s\n", $2, $1, $3, $4, $11}'

# 6. Top 5 Processes by Memory Usage
print_header "TOP 5 PROCESSES BY MEMORY USAGE"
printf "%-10s %-12s %8s %8s  %-s\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
echo "------------------------------------------------------------"
ps aux --sort=-%mem | head -n 6 | tail -n 5 | awk '{printf "%-10s %-12s %7s%% %7s%%  %-s\n", $2, $1, $3, $4, $11}'

# 7. Additional Stats (Stretch Goals)
print_header "NETWORK STATISTICS"
if command -v ss >/dev/null 2>&1; then
    established=$(ss -an 2>/dev/null | grep ESTAB | wc -l)
    echo "Established Connections: $established"
elif command -v netstat >/dev/null 2>&1; then
    established=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
    echo "Established Connections: $established"
else
    echo "Network tools not available"
fi

echo -e "\nNetwork Interfaces:"
if command -v ip >/dev/null 2>&1; then
    ip -brief addr show 2>/dev/null | head -10
else
    echo "  $(ifconfig 2>/dev/null | grep -E '^[a-z]' | awk '{print $1}' | head -5 | xargs)"
fi

print_header "USER ACTIVITY"
echo "Currently Logged In Users:"
who_output=$(who 2>/dev/null)
if [ -n "$who_output" ]; then
    echo "$who_output" | awk '{print $1}' | sort | uniq -c | awk '{printf "  %-15s (Sessions: %d)\n", $2, $1}'
    total_users=$(echo "$who_output" | wc -l)
    echo -e "\nTotal Active Sessions: $total_users"
else
    echo "  No users currently logged in"
fi

print_header "SYSTEM PROCESSES"
total_processes=$(ps aux | wc -l)
running_processes=$(ps aux | awk '$8 ~ /R/ {count++} END {print count+0}')
sleeping_processes=$(ps aux | awk '$8 ~ /S/ {count++} END {print count+0}')
zombie_processes=$(ps aux | awk '$8 ~ /Z/ {count++} END {print count+0}')
echo "Total Processes: $((total_processes - 1))"
echo "Running: $running_processes"
echo "Sleeping: $sleeping_processes"
echo "Zombie: $zombie_processes"

print_header "DISK INODE USAGE"
df -i / 2>/dev/null | tail -n 1 | awk '{printf "Root Filesystem Inodes: %s used of %s (%s)\n", $3, $2, $5}'

# Summary Footer
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Analysis Complete!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "\nReport Generated: $(date '+%Y-%m-%d %H:%M:%S')\n"

echo ""
echo ""
read -p "Press Enter to close..."
echo ""

