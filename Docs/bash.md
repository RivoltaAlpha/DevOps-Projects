# Shell Mastery: From Beginner to Advanced

I'll guide you through these concepts with practical examples you can try yourself. Let's build your skills progressively.

---

## 1. Shell Fundamentals

### Navigation Basics

**Current location and moving around:**
```bash
# Where am I?
pwd                    # Print working directory
# /home/yourname

# What's here?
ls                     # List files
ls -l                  # Long format (permissions, size, date)
ls -lh                 # Human-readable sizes
ls -la                 # Include hidden files (those starting with .)

# Moving around
cd /home              # Absolute path
cd Documents          # Relative path
cd ..                 # Up one level
cd ~                  # Home directory
cd -                  # Previous directory
```

**Creating structure:**
```bash
# Make directories
mkdir projects
mkdir -p dev/python/app1    # Create nested dirs

# Create files
touch newfile.txt
touch file{1,2,3}.txt       # Creates file1.txt, file2.txt, file3.txt
```

### File Operations

```bash
# Copying
cp source.txt dest.txt
cp -r folder1/ folder2/     # Recursive (for directories)

# Moving/Renaming
mv oldname.txt newname.txt
mv file.txt ~/Documents/

# Deleting (careful!)
rm file.txt
rm -r directory/            # Remove directory
rm -rf directory/           # Force remove (dangerous!)

# Viewing files
cat file.txt               # Print entire file
less file.txt              # Paginated viewer (q to quit)
head -n 5 file.txt         # First 5 lines
tail -n 10 file.txt        # Last 10 lines
tail -f logfile.log        # Follow file (watch updates)
```

### Permissions

Every file has permissions for **owner**, **group**, and **others**.

```bash
# Understanding ls -l output:
# -rw-r--r-- 1 user group 1234 Feb 06 10:00 file.txt
# │││││││││
# │└┬┘└┬┘└┬┘
# │ │  │  └─ others: read only
# │ │  └──── group: read only  
# │ └─────── owner: read, write
# └───────── type: - (file), d (directory), l (link)

# r=read(4), w=write(2), x=execute(1)

# Changing permissions
chmod 755 script.sh        # rwxr-xr-x (owner: all, others: read+execute)
chmod +x script.sh         # Add execute permission
chmod u+w file.txt         # User gets write
chmod go-r file.txt        # Group and others lose read

# Changing ownership
chown user:group file.txt
```

**Practical example:**
```bash
# Create a script
echo '#!/bin/bash' > hello.sh
echo 'echo "Hello World"' >> hello.sh

# Try to run it
./hello.sh                 # Permission denied!

# Make it executable
chmod +x hello.sh
./hello.sh                 # Hello World
```

---

## 2. Files & Text Processing

### grep - Searching Text

```bash
# Basic search
grep "error" logfile.txt
grep "TODO" *.py                    # Search in multiple files

# Useful options
grep -i "error" log.txt             # Case-insensitive
grep -n "error" log.txt             # Show line numbers
grep -r "function" .                # Recursive search in directory
grep -v "debug" log.txt             # Invert match (exclude lines)
grep -c "error" log.txt             # Count matches
grep -A 3 "error" log.txt           # Show 3 lines After match
grep -B 2 "error" log.txt           # Show 2 lines Before
grep -C 2 "error" log.txt           # Show 2 lines of Context

# Regular expressions
grep "^Error" log.txt               # Lines starting with "Error"
grep "failed$" log.txt              # Lines ending with "failed"
grep "error\|warning" log.txt       # OR pattern
grep -E "error|warning" log.txt     # Extended regex (easier OR)
```

### sed - Stream Editor

```bash
# Substitution
sed 's/old/new/' file.txt           # Replace first occurrence per line
sed 's/old/new/g' file.txt          # Replace all occurrences (global)
sed 's/old/new/2' file.txt          # Replace 2nd occurrence per line

# In-place editing
sed -i 's/old/new/g' file.txt       # Modify file directly
sed -i.bak 's/old/new/g' file.txt   # Keep backup as file.txt.bak

# Delete lines
sed '5d' file.txt                   # Delete line 5
sed '/pattern/d' file.txt           # Delete lines matching pattern
sed '/^$/d' file.txt                # Delete empty lines

# Print specific lines
sed -n '10,20p' file.txt            # Print lines 10-20
sed -n '/start/,/end/p' file.txt    # Print between patterns

# Multiple operations
sed -e 's/foo/bar/' -e 's/baz/qux/' file.txt
```

**Practical example - Log cleanup:**
```bash
# Remove timestamps and empty lines from a log
sed 's/^\[.*\] //' logfile.txt | sed '/^$/d'
```

### awk - Pattern Scanning and Processing

```bash
# Print columns (default separator: whitespace)
awk '{print $1}' file.txt           # Print first column
awk '{print $1, $3}' file.txt       # Print columns 1 and 3
awk '{print $NF}' file.txt          # Print last column

# Custom separator
awk -F: '{print $1}' /etc/passwd    # Use : as separator
awk -F, '{print $2}' data.csv       # CSV processing

# Conditions
awk '$3 > 100' file.txt             # Lines where column 3 > 100
awk '/error/ {print $0}' log.txt    # Lines matching pattern
awk 'NR > 1' file.txt               # Skip header (row number > 1)
awk 'NF > 0' file.txt               # Non-empty lines

# Calculations
awk '{sum += $1} END {print sum}' numbers.txt
awk '{print $1, $2, $1+$2}' data.txt

# Built-in variables
awk '{print NR, $0}' file.txt       # NR = line number
awk '{print NF, $0}' file.txt       # NF = number of fields
```

**Practical example - Analyzing access logs:**
```bash
# Count requests per IP
awk '{print $1}' access.log | sort | uniq -c | sort -rn

# Calculate average response time (assuming column 10)
awk '{sum += $10; count++} END {print sum/count}' access.log
```

### Compression

```bash
# gzip - Good compression, fast
gzip file.txt                       # Creates file.txt.gz, removes original
gzip -k file.txt                    # Keep original
gunzip file.txt.gz                  # Decompress
gzip -c file.txt > file.txt.gz      # Compress to stdout

# tar - Archive (not compression)
tar -cf archive.tar files/          # Create archive
tar -xf archive.tar                 # Extract
tar -tf archive.tar                 # List contents

# tar + gzip (most common)
tar -czf archive.tar.gz files/      # Create compressed archive
tar -xzf archive.tar.gz             # Extract
tar -xzf archive.tar.gz -C /dest/   # Extract to destination

# bzip2 - Better compression, slower
bzip2 file.txt                      # Creates file.txt.bz2
bunzip2 file.txt.bz2
tar -cjf archive.tar.bz2 files/     # tar + bzip2

# zip - Cross-platform
zip -r archive.zip folder/
unzip archive.zip
```

---

## 3. Redirects & Pipes

### Understanding Streams

Every process has three streams:
- **stdin (0)**: Standard input
- **stdout (1)**: Standard output  
- **stderr (2)**: Standard error

### Redirection

```bash
# Output redirection
command > file.txt                  # Redirect stdout (overwrite)
command >> file.txt                 # Redirect stdout (append)
command 2> errors.txt               # Redirect stderr
command > output.txt 2>&1           # Redirect both to same file
command &> all.txt                  # Shorthand for above

# Input redirection
command < input.txt                 # Read from file
wc -l < file.txt                    # Count lines

# Here documents
cat << EOF > config.txt
line 1
line 2
EOF

# Here strings
grep "pattern" <<< "some text string"
```

### Pipes

Pipes connect stdout of one command to stdin of another.

```bash
# Basic piping
ls -l | grep "txt"
cat file.txt | wc -l

# Chaining multiple commands
cat access.log | grep "404" | wc -l
ps aux | grep python | awk '{print $2}'

# tee - Write to file AND stdout
ls -l | tee listing.txt | grep "txt"

# Process substitution (advanced)
diff <(sort file1.txt) <(sort file2.txt)
```

**Practical pipeline examples:**

```bash
# Find largest files in current directory
du -ah . | sort -rh | head -20

# Count unique IPs in log
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn

# Monitor growing log file
tail -f app.log | grep --line-buffered "ERROR" | tee errors.log

# Find and compress old logs
find /var/log -name "*.log" -mtime +30 | xargs gzip
```

---

## 4. Bash Scripting

### Variables

```bash
#!/bin/bash

# Assignment (no spaces around =)
name="John"
age=30
today=$(date +%Y-%m-%d)

# Using variables
echo "Hello, $name"
echo "Hello, ${name}!"               # Safer with braces

# Command substitution
files=$(ls | wc -l)
now=`date`                           # Old style, prefer $()

# Arrays
fruits=("apple" "banana" "orange")
echo ${fruits[0]}                    # apple
echo ${fruits[@]}                    # All elements
echo ${#fruits[@]}                   # Array length

# Special variables
echo $0                              # Script name
echo $1 $2 $3                        # Positional parameters
echo $@                              # All arguments
echo $#                              # Number of arguments
echo $?                              # Exit status of last command
echo $$                              # Process ID
```

### Conditionals

```bash
#!/bin/bash

# If statement
if [ "$1" = "hello" ]; then
    echo "You said hello"
elif [ "$1" = "bye" ]; then
    echo "Goodbye"
else
    echo "Unknown command"
fi

# Test operators
# Strings: =, !=, -z (empty), -n (not empty)
# Numbers: -eq, -ne, -lt, -le, -gt, -ge
# Files: -f (exists), -d (directory), -r (readable), -w (writable), -x (executable)

if [ -f "file.txt" ]; then
    echo "File exists"
fi

if [ $age -ge 18 ]; then
    echo "Adult"
fi

# Modern [[ ]] syntax (recommended)
if [[ $name == "John" && $age -gt 25 ]]; then
    echo "John is over 25"
fi

# Case statement
case $1 in
    start)
        echo "Starting..."
        ;;
    stop)
        echo "Stopping..."
        ;;
    restart)
        echo "Restarting..."
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
```

### Loops
**Structure of bash conditionals:**

```bash
if [ condition ]; then
    # commands to run if condition is true
fi  # End of if block
```

`fi` is the **closing keyword for an `if` statement** in bash (it's "if" spelled backwards). It indicates the end of the conditional block. Every `if` must be closed with a corresponding `fi`.

**With else:**
```bash
if [ condition ]; then
    # run if true
else
    # run if false
fi
```

**With elif (else-if):**
```bash
if [ condition1 ]; then
    # run if condition1 is true
elif [ condition2 ]; then
    # run if condition2 is true
else
    # run if neither is true
fi
```

**Why "fi"?**
Bash uses reversed keywords to close blocks:
- `if` ... `fi`
- `case` ... `esac`
- `do` ... `done` (for loops)

Every `if` statement must have a matching `fi` to mark where it ends.

```bash
#!/bin/bash

# For loop - iterate over list
for fruit in apple banana orange; do
    echo "I like $fruit"
done

# For loop - C-style
for ((i=1; i<=5; i++)); do
    echo "Count: $i"
done

# For loop - files
for file in *.txt; do
    echo "Processing $file"
    wc -l "$file"
done

# While loop
count=1
while [ $count -le 5 ]; do
    echo $count
    ((count++))
done

# Read file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < file.txt

# Until loop
until [ $count -gt 5 ]; do
    echo $count
    ((count++))
done

# Break and continue
for i in {1..10}; do
    if [ $i -eq 3 ]; then
        continue  # Skip 3
    fi
    if [ $i -eq 8 ]; then
        break     # Stop at 8
    fi
    echo $i
done
```

### Functions

```bash
#!/bin/bash

# Basic function
greet() {
    echo "Hello, $1!"
}

greet "Alice"

# Function with return value
add() {
    local result=$(($1 + $2))
    echo $result
}

sum=$(add 5 3)
echo "Sum: $sum"

# Return status
is_even() {
    if [ $(($1 % 2)) -eq 0 ]; then
        return 0  # Success (true)
    else
        return 1  # Failure (false)
    fi
}

if is_even 4; then
    echo "4 is even"
fi

# Local variables
calculate() {
    local temp=100  # Only exists in function
    echo $temp
}
```

**Complete script example:**

```bash
#!/bin/bash
# backup.sh - Backup script with logging

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
```

---

## 5. Advanced Topics

### Error Handling

```bash
#!/bin/bash

# Exit on error
set -e                    # Exit if any command fails
set -u                    # Exit if undefined variable used
set -o pipefail           # Exit if any command in pipeline fails
set -euo pipefail         # Combine all three

# Trap errors
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/tempfile
}

trap cleanup EXIT         # Run cleanup on script exit
trap 'echo "Error on line $LINENO"' ERR

# Check command success
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found"
    exit 1
fi

# Or syntax
command || { echo "Failed"; exit 1; }
command && echo "Success"

# Default values
output_dir=${1:-/tmp}     # Use $1 or /tmp if not provided

# Error messages to stderr
echo "Error: Something went wrong" >&2
```

### Debugging

```bash
# Debug options
set -x                    # Print each command before executing
set +x                    # Turn off

# Run script in debug mode
bash -x script.sh

# Conditional debugging
DEBUG=true
debug() {
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: $@" >&2
    fi
}

debug "Variable value: $var"

# Logging levels
log_error() { echo "[ERROR] $@" >&2; }
log_warn()  { echo "[WARN]  $@" >&2; }
log_info()  { echo "[INFO]  $@"; }
```

### String Operations

```bash
#!/bin/bash

text="Hello World"

# Length
echo ${#text}                          # 11

# Substring
echo ${text:0:5}                       # Hello
echo ${text:6}                         # World

# Replacement
echo ${text/World/Universe}            # Hello Universe (first match)
echo ${text//o/0}                      # Hell0 W0rld (all matches)

# Remove prefix/suffix
filename="document.txt"
echo ${filename%.txt}                  # document
echo ${filename#*.}                    # txt

path="/home/user/file.txt"
echo ${path##*/}                       # file.txt (basename)
echo ${path%/*}                        # /home/user (dirname)

# Case conversion
echo ${text^^}                         # HELLO WORLD
echo ${text,,}                         # hello world

# Default/alternative values
echo ${var:-default}                   # Use default if var unset
echo ${var:=default}                   # Set var to default if unset
echo ${var:?error message}             # Error if var unset

# Pattern matching
[[ $filename == *.txt ]] && echo "Text file"
[[ $text =~ ^[0-9]+$ ]] && echo "Number"  # Regex
```

### Advanced Scripting Patterns

```bash
#!/bin/bash

# Argument parsing
while getopts "f:o:vh" opt; do
    case $opt in
        f) input_file="$OPTARG" ;;
        o) output_file="$OPTARG" ;;
        v) verbose=true ;;
        h) show_help; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Process remaining arguments
shift $((OPTIND-1))
remaining_args=("$@")

# Parallel execution
for file in *.txt; do
    process_file "$file" &  # Run in background
done
wait                        # Wait for all background jobs

# Lock file pattern
LOCKFILE="/var/lock/myscript.lock"
if ! mkdir "$LOCKFILE" 2>/dev/null; then
    echo "Script already running"
    exit 1
fi
trap "rmdir $LOCKFILE" EXIT

# Configuration file
if [ -f ~/.myscriptrc ]; then
    source ~/.myscriptrc
fi
```

---

## 6. System Administration

### System Monitoring

```bash
# Disk usage
df -h                                  # Disk free space
du -sh /path/to/dir                    # Directory size
du -h --max-depth=1 | sort -rh         # Largest directories

# Memory
free -h                                # Memory usage
top                                    # Interactive process viewer
htop                                   # Better top (if installed)

# Processes
ps aux                                 # All processes
ps aux | grep nginx                    # Find specific process
pgrep -fl nginx                        # Find by name
pkill nginx                            # Kill by name

# System load
uptime                                 # System uptime and load
w                                      # Who's logged in

# CPU info
lscpu
cat /proc/cpuinfo

# Monitor resources
watch -n 1 'df -h'                     # Update every second
watch -n 5 'ps aux --sort=-%mem | head -10'
```

### Networking

```bash
# Network interfaces
ip addr show                           # Show IP addresses
ifconfig                               # Older alternative

# Connectivity
ping -c 4 google.com                   # Send 4 packets
traceroute google.com                  # Route to host
mtr google.com                         # Combined ping/traceroute

# Ports and connections
netstat -tuln                          # Listening ports
ss -tuln                               # Modern alternative
lsof -i :80                            # What's using port 80
nc -zv hostname 80                     # Test port connectivity

# DNS
nslookup google.com
dig google.com
host google.com

# HTTP requests
curl https://api.example.com           # Fetch URL
curl -I https://example.com            # Headers only
wget https://example.com/file.zip      # Download file

# Network statistics
iftop                                  # Bandwidth by connection
nethogs                                # Bandwidth by process
```

### Scheduling (Cron)

```bash
# Edit crontab
crontab -e                             # Edit your cron jobs
crontab -l                             # List cron jobs
crontab -r                             # Remove all cron jobs

# Cron syntax: minute hour day month weekday command
# * * * * * command
# │ │ │ │ │
# │ │ │ │ └─── Day of week (0-7, both 0 and 7 are Sunday)
# │ │ │ └───── Month (1-12)
# │ │ └─────── Day of month (1-31)
# │ └───────── Hour (0-23)
# └─────────── Minute (0-59)

# Examples:
# 0 2 * * * /path/to/backup.sh                    # Daily at 2 AM
# */15 * * * * /path/to/check.sh                  # Every 15 minutes
# 0 0 * * 0 /path/to/weekly.sh                    # Weekly on Sunday
# 30 1 1 * * /path/to/monthly.sh                  # Monthly at 1:30 AM
# 0 9-17 * * 1-5 /path/to/workday.sh              # Weekdays 9 AM - 5 PM

# Special strings
@reboot /path/to/startup.sh
@daily /path/to/daily.sh
@hourly /path/to/hourly.sh

# at - one-time scheduling
echo "/path/to/script.sh" | at 14:30
at now + 1 hour < script.sh
atq                                    # List scheduled jobs
atrm 5                                 # Remove job #5
```

### Log Management

```bash
# System logs
journalctl                             # Systemd logs
journalctl -u nginx                    # Service-specific logs
journalctl -f                          # Follow logs
journalctl --since "1 hour ago"
journalctl -p err                      # Only errors

# Traditional logs
tail -f /var/log/syslog
grep -i error /var/log/apache2/error.log

# Log rotation (logrotate config example)
cat > /etc/logrotate.d/myapp << EOF
/var/log/myapp/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload myapp
    endscript
}
EOF
```

### User & Permission Management

```bash
# Users
useradd -m -s /bin/bash newuser        # Create user with home
passwd newuser                         # Set password
usermod -aG sudo newuser               # Add to sudo group
userdel -r olduser                     # Delete with home directory

# Groups
groupadd developers
usermod -aG developers username
groups username                        # Show user's groups

# File permissions (numeric)
chmod 644 file.txt    # rw-r--r--
chmod 755 script.sh   # rwxr-xr-x
chmod 600 secret.key  # rw-------

# ACLs (advanced permissions)
setfacl -m u:alice:rw file.txt
getfacl file.txt
```

### Practical Admin Script

```bash
#!/bin/bash
# system_health_check.sh - Daily system health report

REPORT_FILE="/var/log/health_$(date +%Y%m%d).log"

{
    echo "====== System Health Report ======"
    echo "Generated: $(date)"
    echo
    
    echo "--- Disk Usage ---"
    df -h | awk '$5+0 > 80 {print "WARNING: " $0}'
    echo
    
    echo "--- Memory Usage ---"
    free -h
    echo
    
    echo "--- Top 5 CPU Processes ---"
    ps aux --sort=-%cpu | head -6
    echo
    
    echo "--- Top 5 Memory Processes ---"
    ps aux --sort=-%mem | head -6
    echo
    
    echo "--- Failed Login Attempts ---"
    grep "Failed password" /var/log/auth.log | tail -10
    echo
    
    echo "--- System Load ---"
    uptime
    echo
    
    echo "--- Recent Errors in Syslog ---"
    journalctl -p err --since "24 hours ago" --no-pager | tail -20
    
} | tee "$REPORT_FILE"

# Email if critical issues
if df -h | awk '$5+0 > 90 {exit 1}'; then
    echo "CRITICAL: Disk usage above 90%" | mail -s "Server Alert" admin@example.com
fi
```
