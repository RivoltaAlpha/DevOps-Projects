# BASH/SHELL SCRIPTING GUIDE

---
# 1. INTRODUCTION TO SHELL AND BASH

## What is a Shell?
A shell is a command-line interpreter that provides a user interface for accessing an operating system's services.

**CLI vs GUI:**
- CLI (Command Line Interface): Text-based, type commands
- GUI (Graphical User Interface): Visual, click icons
- CLI provides more power, automation, and precision

## What is Bash?
Bash (Bourne Again Shell) is the most widely used shell on Linux and macOS.
- Default on most Linux distributions
- Enhanced version of original Bourne shell
- Powerful scripting capabilities

## Popular Shells
- bash - Most common
- zsh - Feature-rich, macOS default
- fish - User-friendly
- dash - Lightweight
- tcsh, ksh - Legacy shells
- PowerShell - Windows shell

---

# 2. SHELL FUNDAMENTALS

## Navigation Commands

### pwd - Print Working Directory
Shows current directory.
```
pwd
→ /home/username
```

### cd - Change Directory
```
cd /path/to/directory    # Absolute path
cd Documents             # Relative path
cd ..                    # Parent directory
cd ~                     # Home directory
cd -                     # Previous directory
```

### ls - List Contents
```
ls           # Basic list
ls -l        # Long format
ls -a        # Include hidden files
ls -lh       # Human-readable sizes
ls -lt       # Sort by time
ls -lS       # Sort by size
ls -R        # Recursive
```

## File Operations

### mkdir - Create Directories
```
mkdir folder
mkdir -p path/to/nested/folder    # Create parent dirs
mkdir dir1 dir2 dir3               # Multiple
```

### touch - Create Files
```
touch file.txt
touch file1.txt file2.txt
```

### cp - Copy
```
cp source.txt dest.txt
cp -r folder1 folder2      # Recursive (directories)
cp -i file.txt dest.txt    # Interactive (ask before overwrite)
cp *.txt backup/           # Wildcards
```

### mv - Move/Rename
```
mv old.txt new.txt          # Rename
mv file.txt /path/to/dir/   # Move
mv -i source dest           # Interactive
```

### rm - Remove
⚠️ WARNING: Cannot be undone!
```
rm file.txt
rm -r directory/            # Recursive
rm -i file.txt              # Interactive
rm -f file.txt              # Force (no prompt)
```

### rmdir - Remove Empty Directories
```
rmdir empty_folder
```

## File Permissions

### Understanding rwx
Every file has permissions for:
- **Owner (u)**
- **Group (g)**  
- **Others (o)**

Permissions:
- **r (4)** - Read
- **w (2)** - Write
- **x (1)** - Execute

Example: `-rwxr-xr--`
- First character: `-` (file) or `d` (directory)
- Next 3: Owner permissions (rwx)
- Next 3: Group permissions (r-x)
- Last 3: Other permissions (r--)

### chmod - Change Permissions
```
# Symbolic
chmod u+x script.sh         # Add execute for owner
chmod g-w file.txt          # Remove write from group
chmod o+r file.txt          # Add read for others
chmod a+x script.sh         # Add execute for all

# Numeric (octal)
chmod 755 script.sh         # rwxr-xr-x
chmod 644 file.txt          # rw-r--r--
chmod 700 private.sh        # rwx------
chmod 777 public.txt        # rwxrwxrwx
```

### chown - Change Owner
```
sudo chown user file.txt
sudo chown user:group file.txt
sudo chown -R user directory/
```

---

# 3. VIEWING AND SEARCHING

## cat - Display Files
```
cat file.txt
cat file1.txt file2.txt          # Multiple files
cat file1.txt file2.txt > combined.txt
cat -n file.txt                  # With line numbers
```

## less/more - Page Through Files
```
less large_file.txt

Navigation:
  Space    - Next page
  b        - Previous page
  /text    - Search forward
  ?text    - Search backward
  n        - Next match
  q        - Quit
```

## head/tail - File Portions
```
head file.txt               # First 10 lines
head -n 20 file.txt         # First 20 lines

tail file.txt               # Last 10 lines
tail -n 50 file.txt         # Last 50 lines
tail -f logfile.txt         # Follow updates (real-time)
```

## grep - Search Patterns
```
grep 'pattern' file.txt
grep -i 'pattern' file.txt      # Case-insensitive
grep -r 'pattern' directory/    # Recursive
grep -n 'pattern' file.txt      # Show line numbers
grep -v 'pattern' file.txt      # Invert (show non-matches)
grep -c 'pattern' file.txt      # Count matches
grep -w 'word' file.txt         # Match whole word
grep -E 'pat1|pat2' file.txt    # Extended regex (OR)
```

## find - Locate Files
```
find . -name 'file.txt'
find . -name '*.txt'            # Wildcard
find . -type f                  # Files only
find . -type d                  # Directories only
find . -mtime -7                # Modified last 7 days
find . -size +10M               # Larger than 10MB
find . -name '*.log' -delete    # Find and delete
find . -name '*.txt' -exec wc -l {} \;  # Execute command
```

---

# 4. REDIRECTS AND PIPELINES

## Standard Streams
- **stdin (0)** - Standard input (keyboard)
- **stdout (1)** - Standard output (screen)
- **stderr (2)** - Standard error (screen)

## Output Redirection
```
command > file.txt          # Redirect stdout (overwrite)
command >> file.txt         # Redirect stdout (append)
command 2> error.log        # Redirect stderr
command > out.txt 2>&1      # Both to same file
command &> all.txt          # Both (modern syntax)
command > /dev/null 2>&1    # Discard all output
```

## Input Redirection
```
command < input.txt
sort < unsorted.txt > sorted.txt
```

## Pipes |
Chain commands together:
```
command1 | command2 | command3

# Examples:
ls -l | grep '.txt'
cat file.txt | wc -l
ps aux | grep python
cat log.txt | grep 'ERROR' | wc -l
```

## Command Substitution
```
$(command)                  # Modern (preferred)
`command`                   # Old style

echo "Today is $(date)"
CURRENT_USER=$(whoami)
FILE_COUNT=$(ls | wc -l)
```

## Here Documents
```
cat << EOF
Multiple lines
of text
EOF

# In scripts:
mysql << EOF
CREATE DATABASE mydb;
USE mydb;
EOF
```

## Here Strings
```
grep 'pattern' <<< "search this text"
bc <<< "scale=2; 10/3"
```

## tee - Split Output
```
command | tee output.txt        # To file AND screen
command | tee -a output.txt     # Append
./script.sh | tee deploy.log
```

---

# 5. TEXT PROCESSING

## wc - Word Count
```
wc file.txt                 # Lines, words, characters
wc -l file.txt              # Lines only
wc -w file.txt              # Words only
wc -c file.txt              # Characters only
```

## sort - Sort Lines
```
sort file.txt
sort -r file.txt            # Reverse
sort -n numbers.txt         # Numeric
sort -u file.txt            # Remove duplicates
sort -k2 file.txt           # Sort by field 2
sort -t',' -k3 data.csv     # Custom delimiter
```

## uniq - Remove Duplicates
Must be sorted first!
```
sort file.txt | uniq
sort file.txt | uniq -c     # Count occurrences
sort file.txt | uniq -d     # Show only duplicates
sort file.txt | uniq -u     # Show only unique
```

## cut - Extract Columns
```
cut -d',' -f1 data.csv      # Field 1 (comma delimiter)
cut -d':' -f1,3 /etc/passwd # Fields 1 and 3
cut -c1-5 file.txt          # Characters 1-5
```

## tr - Translate Characters
```
echo 'hello' | tr 'a-z' 'A-Z'       # Uppercase
echo 'HELLO' | tr 'A-Z' 'a-z'       # Lowercase
echo 'hello world' | tr -d ' '      # Delete spaces
echo 'hello   world' | tr -s ' '    # Squeeze spaces
```

## sed - Stream Editor
```
# Find and replace
sed 's/old/new/' file.txt               # First occurrence
sed 's/old/new/g' file.txt              # All occurrences
sed -i 's/old/new/g' file.txt           # Edit in-place

# Delete lines
sed '/pattern/d' file.txt               # Delete matching
sed '1d' file.txt                       # Delete line 1
sed '1,5d' file.txt                     # Delete lines 1-5
sed '/^$/d' file.txt                    # Delete empty lines

# Print lines
sed -n '5p' file.txt                    # Print line 5
sed -n '10,20p' file.txt                # Print lines 10-20
```

## awk - Text Processing Language
```
# Print fields
awk '{print $1}' file.txt               # Field 1
awk '{print $1, $3}' file.txt           # Fields 1 and 3
awk '{print $NF}' file.txt              # Last field

# Custom separator
awk -F',' '{print $1}' data.csv
awk -F':' '{print $1}' /etc/passwd

# Pattern matching
awk '/ERROR/ {print $0}' log.txt
awk '$3 > 100 {print $1}' file.txt

# Calculations
awk '{sum += $1} END {print sum}' numbers.txt
awk '{sum += $1; count++} END {print sum/count}' numbers.txt

# Built-in variables
NR - Line number
NF - Number of fields
FS - Field separator
```

---

# 6. BASH SCRIPTING BASICS

## Creating a Script

### Step 1: Create File
```bash
#!/bin/bash
# My first script

echo 'Hello, World!'
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
```

### Step 2: Make Executable
```
chmod +x script.sh
```

### Step 3: Run It
```
./script.sh
# OR
bash script.sh
```

## Comments
```bash
# This is a comment
echo "This runs"  # Inline comment

: '
Multi-line comment
Everything here is ignored
'
```

## Variables

### Creating Variables
NO SPACES around =!
```bash
NAME="John"
AGE=30
PATH_TO_FILE="/home/user/file.txt"

# Using variables
echo $NAME
echo "Hello, $NAME"
echo "Hello, ${NAME}"     # Preferred
```

### Command Substitution
```bash
CURRENT_DATE=$(date)
FILES=$(ls -l)
LINE_COUNT=$(wc -l < file.txt)
```

### Reading User Input
```bash
read -p "Enter your name: " USERNAME
echo "Hello, $USERNAME"

# Read password (hidden)
read -sp "Enter password: " PASSWORD

# Read with default
read -p "Enter name [John]: " NAME
NAME=${NAME:-John}
```

### Special Variables
```bash
$0      # Script name
$1, $2  # First, second arguments
$@      # All arguments (as separate words)
$*      # All arguments (as single word)
$#      # Number of arguments
$?      # Exit status of last command
$$      # Current process ID
$!      # PID of last background command
```

### Environment Variables
```bash
# Shell variable (local)
MY_VAR="value"

# Environment variable (exported to child processes)
export DATABASE_URL="localhost:5432"
export PATH="$PATH:/new/path"

# Common environment variables
echo $HOME      # Home directory
echo $USER      # Current user
echo $PWD       # Current directory
echo $PATH      # Executable search path
```

## Arrays

### Indexed Arrays
```bash
# Create array
fruits=("apple" "banana" "orange")

# Access elements
echo ${fruits[0]}       # First element
echo ${fruits[@]}       # All elements
echo ${#fruits[@]}      # Array length

# Add element
fruits[3]="grape"
fruits+=("mango")

# Loop through array
for fruit in "${fruits[@]}"; do
    echo $fruit
done
```

### Associative Arrays (Bash 4+)
```bash
declare -A ages
ages[John]=30
ages[Jane]=25

echo ${ages[John]}      # 30
echo ${ages[@]}         # All values
echo ${!ages[@]}        # All keys

# Loop through
for name in "${!ages[@]}"; do
    echo "$name is ${ages[$name]}"
done
```

## Conditionals

### if Statement
```bash
if [ condition ]; then
    # commands
elif [ other_condition ]; then
    # commands
else
    # commands
fi

# Example
if [ "$AGE" -gt 18 ]; then
    echo "Adult"
else
    echo "Minor"
fi
```

### Test Operators

**Numeric:**
```
-eq     Equal
-ne     Not equal
-gt     Greater than
-ge     Greater or equal
-lt     Less than
-le     Less or equal
```

**String:**
```
=       Equal
!=      Not equal
-z      Empty string
-n      Not empty
```

**File:**
```
-f      Regular file exists
-d      Directory exists
-e      Exists (file or directory)
-r      Readable
-w      Writable
-x      Executable
-s      Not empty (size > 0)
```

### Modern [[ ]] Syntax
Preferred over [ ]:
```bash
if [[ "$NAME" == "John" ]]; then
    echo "Hello John"
fi

# Multiple conditions
if [[ "$AGE" -gt 18 && "$NAME" == "John" ]]; then
    echo "Adult named John"
fi

# Pattern matching
if [[ "$filename" == *.txt ]]; then
    echo "Text file"
fi

# Regular expressions
if [[ "$email" =~ ^[a-z]+@[a-z]+\.[a-z]+$ ]]; then
    echo "Valid email"
fi
```

### case Statement
```bash
case "$OPTION" in
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
        echo "Unknown option"
        ;;
esac
```

## Loops

### for Loop
```bash
# List iteration
for item in apple banana orange; do
    echo "I like $item"
done

# C-style
for ((i=1; i<=5; i++)); do
    echo "Number: $i"
done

# Range
for i in {1..10}; do
    echo $i
done

# Files
for file in *.txt; do
    echo "Processing $file"
done

# Array
for fruit in "${fruits[@]}"; do
    echo $fruit
done
```

### while Loop
```bash
counter=1
while [ $counter -le 5 ]; do
    echo "Count: $counter"
    ((counter++))
done

# Read file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < file.txt

# Infinite loop
while true; do
    echo "Press Ctrl+C to stop"
    sleep 1
done
```

### until Loop
```bash
counter=1
until [ $counter -gt 5 ]; do
    echo "Count: $counter"
    ((counter++))
done
```

### break and continue
```bash
for i in {1..10}; do
    if [ $i -eq 5 ]; then
        continue    # Skip 5
    fi
    if [ $i -eq 8 ]; then
        break       # Stop at 8
    fi
    echo $i
done
# Output: 1 2 3 4 6 7
```

---

# 7. FUNCTIONS

## Defining Functions
```bash
# Syntax 1
function_name() {
    # commands
}

# Syntax 2
function function_name {
    # commands
}

# Example
greet() {
    echo "Hello, $1!"
}

greet "World"       # Output: Hello, World!
```

## Function Arguments
```bash
add_numbers() {
    local num1=$1
    local num2=$2
    local sum=$((num1 + num2))
    echo $sum
}

result=$(add_numbers 5 3)
echo "5 + 3 = $result"      # Output: 5 + 3 = 8
```

## Return Values
```bash
# Return status code (0-255)
check_file() {
    if [[ -f "$1" ]]; then
        return 0    # Success
    else
        return 1    # Failure
    fi
}

if check_file "myfile.txt"; then
    echo "File exists"
fi

# Return output (via echo)
get_timestamp() {
    echo $(date +%s)
}

timestamp=$(get_timestamp)
```

## Local vs Global Variables
```bash
# Global
COUNTER=0

increment() {
    local temp=10       # Local to function
    COUNTER=$((COUNTER + 1))    # Modifies global
    echo "Temp: $temp, Counter: $COUNTER"
}
```

## Recursive Functions
```bash
factorial() {
    if [ $1 -le 1 ]; then
        echo 1
    else
        local prev=$(factorial $(( $1 - 1 )))
        echo $(( $1 * prev ))
    fi
}

result=$(factorial 5)
echo "5! = $result"     # Output: 5! = 120
```

---

# 8. ADVANCED SCRIPTING

## Error Handling

### Exit Codes
```bash
# Check last command's exit code
ls /nonexistent
echo $?     # Non-zero = failed

# Set exit code
exit 0      # Success
exit 1      # General error
exit 127    # Command not found
```

### set Options
```bash
#!/bin/bash

set -e              # Exit on any error
set -u              # Exit on undefined variable
set -o pipefail     # Fail if any pipe command fails

# Combine all (recommended)
set -euo pipefail
```

### trap - Cleanup
```bash
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/tempfile
}

trap cleanup EXIT   # Run on exit
trap cleanup ERR    # Run on error
trap cleanup INT    # Run on Ctrl+C
```

### Error Logging
```bash
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

[ -f "file.txt" ] || error_exit "File not found"

# With logging
log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> error.log
    echo "ERROR: $1" >&2
}
```

## String Manipulation

```bash
TEXT="Hello World"

# Length
echo ${#TEXT}               # 11

# Substring extraction
echo ${TEXT:0:5}            # Hello (start:length)
echo ${TEXT:6}              # World (from position 6)

# Pattern replacement
FILE="document.txt"
echo ${FILE/txt/pdf}        # document.pdf (first)
echo ${FILE//t/T}           # documenT.TxT (all)

# Remove prefix/suffix
PATH="/home/user/file.txt"
echo ${PATH##*/}            # file.txt (remove longest prefix)
echo ${PATH%.*}             # /home/user/file (remove suffix)

# Case conversion
echo ${TEXT^^}              # HELLO WORLD (uppercase)
echo ${TEXT,,}              # hello world (lowercase)
echo ${TEXT^}               # Hello World (capitalize first)

# Default values
echo ${VAR:-default}        # Use default if VAR unset
echo ${VAR:=default}        # Set VAR to default if unset
```

## Arithmetic Operations

```bash
# Using $(( ))
a=5
b=3
echo $((a + b))     # 8
echo $((a - b))     # 2
echo $((a * b))     # 15
echo $((a / b))     # 1 (integer division)
echo $((a % b))     # 2 (modulo)

# Increment/decrement
((counter++))
((counter--))
((counter += 5))

# Using let
let result=a+b
let counter++

# Floating point (bc)
echo "scale=2; 10/3" | bc           # 3.33
echo "scale=2; sqrt(16)" | bc       # 4.00
```

## Debugging

```bash
# Trace execution
set -x              # Print each command
set +x              # Stop tracing

# Run script in debug mode
bash -x script.sh

# Syntax check
bash -n script.sh

# Use shellcheck (install separately)
shellcheck script.sh
```

## Process Management

```bash
# Background jobs
command &           # Run in background
# Start a job in background
sleep 100 &         # & sends it to background

# List background jobs
jobs                # Shows: [1]+ Running  sleep 100 &

# Bring job to foreground
fg %1               # Bring job 1 to foreground
fg                  # Bring most recent job to foreground

# Resume in background
bg %1               # Resume job 1 in background

# Kill a background job
kill %1             # Kill job 1
kill %2             # Kill job 2

jobs                # List all background jobs
jobs -l             # List with process IDs
jobs -r             # Running jobs only
jobs -s             # Stopped jobs only

# Disown (keep running after logout)
nohup command &
disown %1

# Process substitution
diff <(ls dir1) <(ls dir2)
```

---

# 9. REGULAR EXPRESSIONS

## Basic Regex
```bash
# Metacharacters
.       Any single character
^       Start of line
$       End of line
*       Zero or more of previous
[]      Character class
[^]     Negated character class

# Examples with grep
grep '^Hello' file.txt      # Lines starting with Hello
grep 'world$' file.txt      # Lines ending with world
grep 'h.llo' file.txt       # h + any char + llo
grep 'hel*o' file.txt       # he + zero or more l + o
grep '[0-9]' file.txt       # Any digit
grep '[^0-9]' file.txt      # Any non-digit
```

## Extended Regex (-E)
```bash
# Additional metacharacters
+       One or more
?       Zero or one
|       Alternation (OR)
()      Grouping
{n}     Exactly n times
{n,}    n or more times
{n,m}   Between n and m times

# Examples
grep -E 'hello+' file.txt       # hell + one or more o
grep -E 'colou?r' file.txt      # color or colour
grep -E 'cat|dog' file.txt      # cat OR dog
grep -E '(ab)+' file.txt        # ab, abab, ababab, etc.
grep -E '[0-9]{3}' file.txt     # Exactly 3 digits
grep -E '[0-9]{3,5}' file.txt   # 3 to 5 digits
```

## Common Patterns
```bash
# Email
grep -E '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

# IP address (basic)
grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'

# Phone number (US)
grep -E '[0-9]{3}-[0-9]{3}-[0-9]{4}'

# URL
grep -E 'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
```

---

# 10. SYSTEM ADMINISTRATION

## System Monitoring

```bash
# Process info
ps aux                  # All processes
ps -ef                  # All processes (different format)
top                     # Real-time process viewer
htop                    # Enhanced top (if installed)
pstree                  # Process tree

# Memory
free -h                 # Memory usage (human-readable)
vmstat                  # Virtual memory stats
cat /proc/meminfo       # Detailed memory info

# Disk
df -h                   # Disk space (human-readable)
du -sh directory/       # Directory size
du -h --max-depth=1     # Size of subdirectories
iostat                  # I/O statistics

# CPU
uptime                  # System uptime and load
lscpu                   # CPU info
cat /proc/cpuinfo       # Detailed CPU info

# Network
ifconfig                # Network interfaces (old)
ip addr                 # Network interfaces (new)
ip route                # Routing table
netstat -tuln           # Network connections
ss -tuln                # Socket statistics (newer)
ping host               # Test connectivity
traceroute host         # Trace route to host
```

## Networking

```bash
# Download
wget URL                        # Download file
wget -c URL                     # Resume download
curl -O URL                     # Download file
curl URL                        # Display content

# Transfer
scp file.txt user@host:/path/   # Secure copy to remote
scp user@host:/path/file.txt .  # Copy from remote
rsync -avz source/ dest/        # Sync directories

# SSH
ssh user@host                   # Connect to remote
ssh user@host command           # Run command on remote
ssh-keygen                      # Generate SSH keys
ssh-copy-id user@host           # Copy SSH key to remote
```

## File Compression

```bash
# tar (archive)
tar -czf archive.tar.gz directory/      # Create .tar.gz
tar -xzf archive.tar.gz                 # Extract .tar.gz
tar -cjf archive.tar.bz2 directory/     # Create .tar.bz2
tar -xjf archive.tar.bz2                # Extract .tar.bz2
tar -tf archive.tar.gz                  # List contents

# gzip
gzip file.txt               # Compress (creates file.txt.gz)
gunzip file.txt.gz          # Decompress
gzip -k file.txt            # Keep original

# zip/unzip
zip archive.zip file1 file2
zip -r archive.zip directory/
unzip archive.zip
unzip -l archive.zip        # List contents

# bzip2
bzip2 file.txt
bunzip2 file.txt.bz2

# xz
xz file.txt
unxz file.txt.xz
```

## Task Scheduling

### cron
```bash
# Edit crontab
crontab -e

# List crontab
crontab -l

# Remove crontab
crontab -r

# Cron syntax
# MIN HOUR DOM MON DOW COMMAND
# *    *    *   *   *   command
# 0-59 0-23 1-31 1-12 0-6

# Examples:
# Run every day at 2:30 AM
30 2 * * * /path/to/script.sh

# Run every Monday at 9:00 AM
0 9 * * 1 /path/to/script.sh

# Run every hour
0 * * * * /path/to/script.sh

# Run every 15 minutes
*/15 * * * * /path/to/script.sh
```

### at
```bash
# Run command at specific time
echo "command" | at 10:00 PM
at 10:00 PM -f script.sh

# List scheduled jobs
atq

# Remove job
atrm job_number
```

## Package Management

### apt (Debian/Ubuntu)
```bash
sudo apt update                 # Update package list
sudo apt upgrade                # Upgrade packages
sudo apt install package        # Install
sudo apt remove package         # Remove
sudo apt search package         # Search
sudo apt show package           # Show info
```

### yum/dnf (RedHat/CentOS)
```bash
sudo yum update                 # Update all
sudo yum install package        # Install
sudo yum remove package         # Remove
sudo yum search package         # Search

# dnf (newer)
sudo dnf install package
```

### brew (macOS)
```bash
brew update                     # Update Homebrew
brew upgrade                    # Upgrade packages
brew install package            # Install
brew uninstall package          # Remove
brew search package             # Search
```

---

# BASH SCRIPTING BEST PRACTICES

1. **Always use shebang**: `#!/bin/bash`
2. **Use set options**: `set -euo pipefail`
3. **Quote variables**: `"$VAR"` not `$VAR`
4. **Use local in functions**: `local var=value`
5. **Check command exists**: `command -v cmd >/dev/null`
6. **Validate inputs**: Check arguments before using
7. **Handle errors**: Use trap and error functions
8. **Use meaningful names**: Not `x`, use `user_count`
9. **Comment your code**: Explain why, not what
10. **Test your scripts**: Use shellcheck

---

# QUICK REFERENCE CHEAT SHEET

## Navigation
```
pwd, cd, ls, mkdir, rmdir
```

## File Operations
```
touch, cp, mv, rm, cat, less, head, tail
```

## Permissions
```
chmod, chown, chgrp
```

## Search
```
grep, find, locate
```

## Redirection
```
>, >>, <, 2>, &>, |, tee
```

## Text Processing
```
wc, sort, uniq, cut, tr, sed, awk
```

## Variables
```
VAR=value
echo $VAR
export VAR
```

## Conditionals
```
if [[ condition ]]; then ... fi
case $VAR in ... esac
```

## Loops
```
for, while, until
break, continue
```

## Functions
```
func() { ... }
local var
return/echo
```

## Process
```
ps, top, kill, jobs, bg, fg
```

## Network
```
ping, ssh, scp, wget, curl
```

## System
```
df, du, free, uptime
```

---
