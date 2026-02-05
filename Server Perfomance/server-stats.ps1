# Goal of this project is to write a script to analyse server performance stats.
# Windows PowerShell version - works on Windows systems
# Analyzes: CPU usage, Memory usage, Disk usage, Top processes, Network, and more

# Function to print section headers
function Print-Header {
    param($title)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $title -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}

# Display banner
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "     SERVER PERFORMANCE ANALYZER        " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nAnalysis Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"

# 1. System Information
Print-Header "SYSTEM INFORMATION"
$computerInfo = Get-ComputerInfo
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "Hostname: $env:COMPUTERNAME"
Write-Host "OS: $($computerInfo.OsName)"
Write-Host "Version: $($computerInfo.OsVersion)"
Write-Host "Build: $($computerInfo.OsBuildNumber)"
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"

# 2. Total CPU Usage
Print-Header "CPU USAGE"
$cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 2 | 
Select-Object -ExpandProperty CounterSamples | 
Select-Object -Last 1 -ExpandProperty CookedValue
$cpuUsageRounded = [math]::Round($cpuUsage, 2)
$cpuIdle = [math]::Round(100 - $cpuUsage, 2)

Write-Host "CPU Usage: $cpuUsageRounded%"
Write-Host "CPU Idle: $cpuIdle%"

# Number of CPU cores
$cpuCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
Write-Host "CPU Cores: $cpuCores"

# CPU Details
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if ($cpu -and $cpu.Name) {
    Write-Host "CPU Model: $($cpu.Name.Trim())"
}

# 3. Memory Usage
Print-Header "MEMORY USAGE"
$totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMemoryGB = [math]::Round($totalMemoryGB - $freeMemoryGB, 2)
$memoryPercentage = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)

$totalMemoryMB = [math]::Round($os.TotalVisibleMemorySize / 1KB, 0)
$freeMemoryMB = [math]::Round($os.FreePhysicalMemory / 1KB, 0)
$usedMemoryMB = $totalMemoryMB - $freeMemoryMB

Write-Host "Total Memory: $totalMemoryMB MB / $totalMemoryGB GiB"
Write-Host "Used Memory: $usedMemoryMB MB / $usedMemoryGB GiB - $memoryPercentage%"
Write-Host "Free Memory: $freeMemoryMB MB / $freeMemoryGB GiB"

# Memory usage bar
$usedBars = [math]::Round($memoryPercentage / 2, 0)
$freeBars = 50 - $usedBars
Write-Host "`nMemory Usage Bar: [" -NoNewline
Write-Host ("█" * $usedBars) -NoNewline -ForegroundColor Red
Write-Host ("░" * $freeBars) -NoNewline -ForegroundColor Green
Write-Host "] $memoryPercentage%"

# 4. Disk Usage
Print-Header "DISK USAGE"
Write-Host "Filesystem Usage:"
Write-Host ("{0,-15} {1,10} {2,10} {3,10} {4,8}" -f "Drive", "Size (GB)", "Used (GB)", "Free (GB)", "Use%")
Write-Host "------------------------------------------------------------"

Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
    $sizeGB = [math]::Round($_.Size / 1GB, 2)
    $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round($sizeGB - $freeGB, 2)
    $usedPercent = [math]::Round(($usedGB / $sizeGB) * 100, 1)
    Write-Host ("{0,-15} {1,10} {2,10} {3,10} {4,7}%" -f $_.DeviceID, $sizeGB, $usedGB, $freeGB, $usedPercent)
}

# Root filesystem (C:) summary
$rootDisk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
if ($rootDisk) {
    $rootSizeGB = [math]::Round($rootDisk.Size / 1GB, 2)
    $rootFreeGB = [math]::Round($rootDisk.FreeSpace / 1GB, 2)
    $rootUsedGB = [math]::Round($rootSizeGB - $rootFreeGB, 2)
    $rootUsedPercent = [math]::Round(($rootUsedGB / $rootSizeGB) * 100, 1)
    Write-Host "`nRoot Filesystem (C:) Summary:"
    Write-Host "  Total: $rootSizeGB GB | Used: $rootUsedGB GB | Free: $rootFreeGB GB | Usage: $rootUsedPercent%"
}

# 5. Top 5 Processes by CPU Usage
Print-Header "TOP 5 PROCESSES BY CPU USAGE"
Write-Host ("{0,-10} {1,-25} {2,12} {3,12}" -f "PID", "Process Name", "CPU (s)", "Memory (MB)")
Write-Host "------------------------------------------------------------"

Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | ForEach-Object {
    $memMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
    $cpuSeconds = [math]::Round($_.CPU, 2)
    Write-Host ("{0,-10} {1,-25} {2,12} {3,12}" -f $_.Id, $_.ProcessName, $cpuSeconds, $memMB)
}

# 6. Top 5 Processes by Memory Usage
Print-Header "TOP 5 PROCESSES BY MEMORY USAGE"
Write-Host ("{0,-10} {1,-25} {2,12} {3,12}" -f "PID", "Process Name", "CPU (s)", "Memory (MB)")
Write-Host "------------------------------------------------------------"

Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 | ForEach-Object {
    $memMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
    $cpuSeconds = [math]::Round($_.CPU, 2)
    Write-Host ("{0,-10} {1,-25} {2,12} {3,12}" -f $_.Id, $_.ProcessName, $cpuSeconds, $memMB)
}

# 7. Additional Stats
Print-Header "NETWORK STATISTICS"
$establishedConnections = (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue).Count
Write-Host "Established TCP Connections: $establishedConnections"

Write-Host "`nNetwork Interfaces:"
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $ipAddress = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    if ($ipAddress) {
        Write-Host "  $($_.Name): $ipAddress (Status: $($_.Status))"
    }
}

Print-Header "USER ACTIVITY"
Write-Host "Currently Logged In Users:"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "  $currentUser"

# Get all logged in users via query user (if available)
try {
    $users = query user 2>$null
    if ($users) {
        Write-Host "`nAll Active Sessions:"
        $users
    }
}
catch {
    # Command not available
}

Print-Header "SYSTEM PROCESSES"
$allProcesses = Get-Process
$totalProcesses = $allProcesses.Count
$respondingProcesses = ($allProcesses | Where-Object { $_.Responding }).Count
$notRespondingProcesses = $totalProcesses - $respondingProcesses

Write-Host "Total Processes: $totalProcesses"
Write-Host "Responding: $respondingProcesses"
Write-Host "Not Responding: $notRespondingProcesses"

# Windows Services
$runningServices = (Get-Service | Where-Object { $_.Status -eq 'Running' }).Count
$stoppedServices = (Get-Service | Where-Object { $_.Status -eq 'Stopped' }).Count
Write-Host "`nWindows Services:"
Write-Host "  Running: $runningServices"
Write-Host "  Stopped: $stoppedServices"

Print-Header "SYSTEM HEALTH"
# Check Windows Update
$updateSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue
if ($updateSession) {
    Write-Host "Windows Update Service: Available"
}

# Event Log Errors (last 24 hours)
try {
    $criticalErrors = (Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue).Count
    Write-Host "System Errors (Last 24h): $criticalErrors"
}
catch {
    Write-Host "System Errors: Unable to retrieve"
}

# Summary Footer
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "     Analysis Complete!                 " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ("`nReport Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "`n")

Write-Host ""
Read-Host "Press Enter to close"
Write-Host ""
