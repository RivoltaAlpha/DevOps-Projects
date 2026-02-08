#!/bin/bash

# Distributed Log Analyzer - Process logs from multiple servers
# Usage: ./distributed-log-analyzer.sh <config_file>

CONFIG_FILE="${1:-servers.conf}"
OUTPUT_DIR="./log_analysis_$(date +%Y%m%d_%H%M%S)"
TEMP_DIR="/tmp/log_analyzer_$$"
LOG_FILE="${OUTPUT_DIR}/analyzer.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

init_environment() {
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$TEMP_DIR"
    log_message "Initialized analysis environment"
    log_message "Output directory: $OUTPUT_DIR"
}

cleanup() {
    log_message "Cleaning up temporary files"
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_message "ERROR: Configuration file not found: $CONFIG_FILE"
        echo "Please create a configuration file with the following format:"
        echo "server1:/var/log/app.log"
        echo "server2:/var/log/app.log"
        echo "user@server3:/opt/logs/*.log"
        exit 1
    fi
}

fetch_logs() {
    local server_spec="$1"
    local server=$(echo "$server_spec" | cut -d: -f1)
    local log_path=$(echo "$server_spec" | cut -d: -f2)
    local server_dir="${TEMP_DIR}/${server}"
    
    mkdir -p "$server_dir"
    
    log_message "Fetching logs from $server:$log_path"
    
    if [[ "$server" == "localhost" ]] || [[ "$server" == "127.0.0.1" ]]; then
        # Local logs
        cp $log_path "$server_dir/" 2>/dev/null
    else
        # Remote logs via SCP
        scp -q "$server:$log_path" "$server_dir/" 2>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Successfully fetched logs from $server"
        return 0
    else
        log_message "WARNING: Failed to fetch logs from $server"
        return 1
    fi
}

analyze_errors() {
    local log_file="$1"
    local server="$2"
    
    if [ ! -f "$log_file" ]; then
        return
    fi
    
    # Extract ERROR lines
    grep -i "error" "$log_file" > "${TEMP_DIR}/${server}_errors.txt" 2>/dev/null
    
    # Count errors by hour
    grep -i "error" "$log_file" | \
        sed -E 's/.*([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}):[0-9]{2}:[0-9]{2}.*/\1:00/' | \
        sort | uniq -c | \
        awk -v server="$server" '{print server "," $2 "," $1}' \
        >> "${TEMP_DIR}/errors_by_hour.csv"
}

analyze_warnings() {
    local log_file="$1"
    local server="$2"
    
    if [ ! -f "$log_file" ]; then
        return
    fi
    
    # Count warnings
    local warning_count=$(grep -ic "warning" "$log_file")
    echo "$server,$warning_count" >> "${TEMP_DIR}/warnings_count.csv"
}

analyze_response_times() {
    local log_file="$1"
    local server="$2"
    
    if [ ! -f "$log_file" ]; then
        return
    fi
    
    # Extract response times (assumes format like "response_time: 123ms")
    grep -oP "response_time:\s*\K[0-9]+" "$log_file" | \
        awk -v server="$server" '{sum+=$1; count++} END {
            if (count > 0) {
                print server "," count "," sum/count "," (sum/count > 1000 ? "SLOW" : "OK")
            }
        }' >> "${TEMP_DIR}/response_times.csv"
}

generate_summary() {
    local summary_file="${OUTPUT_DIR}/analysis_summary.txt"
    
    log_message "Generating analysis summary"
    
    cat > "$summary_file" << EOF
================================================================================
                    DISTRIBUTED LOG ANALYSIS SUMMARY
================================================================================
Analysis Date: $(date '+%Y-%m-%d %H:%M:%S')
Configuration: $CONFIG_FILE
--------------------------------------------------------------------------------

ERRORS BY HOUR AND SERVER
--------------------------------------------------------------------------------
EOF
    
    if [ -f "${TEMP_DIR}/errors_by_hour.csv" ]; then
        echo "Server, Hour, Error Count" >> "$summary_file"
        sort -t, -k1,1 -k2,2 "${TEMP_DIR}/errors_by_hour.csv" >> "$summary_file"
    else
        echo "No error data found" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << EOF

--------------------------------------------------------------------------------
WARNING COUNTS BY SERVER
--------------------------------------------------------------------------------
EOF
    
    if [ -f "${TEMP_DIR}/warnings_count.csv" ]; then
        echo "Server, Warning Count" >> "$summary_file"
        sort -t, -k2,2nr "${TEMP_DIR}/warnings_count.csv" >> "$summary_file"
    else
        echo "No warning data found" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << EOF

--------------------------------------------------------------------------------
RESPONSE TIME ANALYSIS
--------------------------------------------------------------------------------
EOF
    
    if [ -f "${TEMP_DIR}/response_times.csv" ]; then
        echo "Server, Request Count, Avg Response Time (ms), Status" >> "$summary_file"
        cat "${TEMP_DIR}/response_times.csv" >> "$summary_file"
    else
        echo "No response time data found" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << EOF

--------------------------------------------------------------------------------
TOP ERROR MESSAGES (Across All Servers)
--------------------------------------------------------------------------------
EOF
    
    if compgen -G "${TEMP_DIR}/*_errors.txt" > /dev/null; then
        cat ${TEMP_DIR}/*_errors.txt | \
            grep -oP "ERROR:?\s*\K.*" | \
            sort | uniq -c | sort -rn | head -20 >> "$summary_file"
    else
        echo "No error messages found" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << EOF

================================================================================
                            END OF REPORT
================================================================================
EOF
    
    log_message "Summary generated: $summary_file"
    cat "$summary_file"
}

generate_html_report() {
    local html_file="${OUTPUT_DIR}/analysis_report.html"
    
    log_message "Generating HTML report"
    
    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Distributed Log Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; border-bottom: 1px solid #ddd; padding-bottom: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #007bff; color: white; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        .error { color: #dc3545; font-weight: bold; }
        .warning { color: #ffc107; }
        .ok { color: #28a745; }
        .slow { color: #dc3545; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Distributed Log Analysis Report</h1>
        <p class="timestamp">Generated: TIMESTAMP</p>
        
        <h2>Errors by Hour and Server</h2>
        <table id="errors-table">
            <tr><th>Server</th><th>Hour</th><th>Error Count</th></tr>
        </table>
        
        <h2>Warning Counts by Server</h2>
        <table id="warnings-table">
            <tr><th>Server</th><th>Warning Count</th></tr>
        </table>
        
        <h2>Response Time Analysis</h2>
        <table id="response-table">
            <tr><th>Server</th><th>Request Count</th><th>Avg Response (ms)</th><th>Status</th></tr>
        </table>
    </div>
</body>
</html>
EOF
    
    sed -i "s/TIMESTAMP/$(date '+%Y-%m-%d %H:%M:%S')/" "$html_file"
    
    log_message "HTML report generated: $html_file"
}

# Main execution
log_message "Starting distributed log analysis"

validate_config
init_environment

# Initialize CSV headers
echo "Server,Hour,ErrorCount" > "${TEMP_DIR}/errors_by_hour.csv"
echo "Server,WarningCount" > "${TEMP_DIR}/warnings_count.csv"
echo "Server,RequestCount,AvgResponseTime,Status" > "${TEMP_DIR}/response_times.csv"

# Process each server
while IFS= read -r server_spec; do
    # Skip empty lines and comments
    [[ -z "$server_spec" ]] || [[ "$server_spec" =~ ^# ]] && continue
    
    server=$(echo "$server_spec" | cut -d: -f1)
    
    if fetch_logs "$server_spec"; then
        # Analyze all fetched log files for this server
        for log_file in ${TEMP_DIR}/${server}/*; do
            if [ -f "$log_file" ]; then
                log_message "Analyzing $log_file"
                analyze_errors "$log_file" "$server"
                analyze_warnings "$log_file" "$server"
                analyze_response_times "$log_file" "$server"
            fi
        done
    fi
done < "$CONFIG_FILE"

# Generate reports
generate_summary
generate_html_report

log_message "Analysis complete. Results in: $OUTPUT_DIR"
echo ""
echo "Analysis complete!"
echo "Summary: ${OUTPUT_DIR}/analysis_summary.txt"
echo "HTML Report: ${OUTPUT_DIR}/analysis_report.html"