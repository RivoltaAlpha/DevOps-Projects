#!/bin/bash

echo "  Large Files Finder (>100MB)"
echo ""

# Set search directory - use argument or current directory
SEARCH_DIR="${1:-.}"

# Check if directory exists
if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: Directory '$SEARCH_DIR' does not exist"
    exit 1
fi

echo "Searching in: $(realpath "$SEARCH_DIR")"
echo "Looking for files larger than 100MB..."
echo ""

# Find files larger than 100MB and display with size
# -type f: only files (not directories)
# -size +100M: files larger than 100MB
echo "Size (MB)  | File Path"
echo "-----------|------------------------------------------------------------"

find "$SEARCH_DIR" -type f -size +100M -exec du -h {} \; 2>/dev/null | \
    sort -rh | \
    awk '{printf "%-10s | %s\n", $1, $2}'

# Count total files found
FILE_COUNT=$(find "$SEARCH_DIR" -type f -size +100M 2>/dev/null | wc -l)

echo ""
echo "Total files found: $FILE_COUNT"
echo ""

read -p "Press Enter to close..."
echo ""