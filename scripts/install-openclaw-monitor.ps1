# ============================================================
# OpenClaw Gateway Monitor - Install/Uninstall Script
# Create Windows Scheduled Task for auto-start at boot
# Usage: 
#   Install: powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1
#   Uninstall: powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -Uninstall
# ============================================================

param(
    [string]$TaskName = "OpenClawGatewayMonitor",
    [string]$ScriptPath = "D:\.openclaw\workspace-main\scripts\openclaw-monitor.ps1",
    [int]$CheckInterval = 60,
    [int]$MaxRetries = 3,
    [int]$RetryWait = 60,
    [switch]$Uninstall,
    [switch]$RunNow
)

$ErrorActionPreference = "Stop"

function Write-Info($Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success($Message) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Err($Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warn($Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

# ============================================================
# Uninstall
# ============================================================

if ($Uninstall) {
    Write-Info "Uninstalling OpenClaw Gateway Monitor..."
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Success "Scheduled task removed: $TaskName"
        }
        else {
            Write-Warn "Scheduled task does not exist"
        }
        
        $monitorProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
            Where-Object { $_.CommandLine -match "openclaw-monitor" }
        if ($monitorProcess) {
            $monitorProcess | Stop-Process -Force
            Write-Info "Stopped running monitor process"
        }
        
        Write-Success "Uninstall complete"
    }
    catch {
        Write-Err "Uninstall failed: $($_.Exception.Message)"
        exit 1
    }
    
    exit 0
}

# ============================================================
# Install
# ============================================================

Write-Info "=========================================="
Write-Info "OpenClaw Gateway Monitor Installer"
Write-Info "=========================================="
Write-Info ""

# Verify script exists
if (!(Test-Path $ScriptPath)) {
    Write-Err "Monitor script not found: $ScriptPath"
    exit 1
}

# Verify OpenClaw is installed
try {
    $openclawVersion = & openclaw --version 2>&1 | Select-Object -First 1
    Write-Info "Detected OpenClaw: $openclawVersion"
}
catch {
    Write-Err "OpenClaw not detected, please install first"
    exit 1
}

# Create log directory
$logDir = "D:\.openclaw\logs"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Info "Created log directory: $logDir"
}

# Build task arguments
$scriptArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-NoProfile",
    "-File", "`"$ScriptPath`"",
    "-CheckInterval", "$CheckInterval",
    "-MaxRetries", "$MaxRetries",
    "-RetryWait", "$RetryWait"
)

# Remove existing task if present
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Info "Existing scheduled task found, removing..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create scheduled task action
$taskAction = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument ($scriptArgs -join " ")

# Create trigger (at system startup)
$taskTrigger = New-ScheduledTaskTrigger `
    -AtStartup

# Create settings
$taskSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -DontStopOnIdleEnd

# Create principal
$taskPrincipal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

# Register scheduled task
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $taskAction `
        -Trigger $taskTrigger `
        -Settings $taskSettings `
        -Principal $taskPrincipal `
        -Description "OpenClaw Gateway Monitor - Auto-detect and repair Gateway issues" `
        -Force
    
    Write-Success "Scheduled task created: $TaskName"
}
catch {
    Write-Err "Failed to create scheduled task: $($_.Exception.Message)"
    Write-Info "Try running as administrator"
    exit 1
}

# Show task info
Write-Info ""
Write-Info "=========================================="
Write-Info "Installation Complete!"
Write-Info "=========================================="
Write-Info ""
Write-Info "Task Name: $TaskName"
Write-Info "Trigger: System startup"
Write-Info "Check Interval: ${CheckInterval} seconds"
Write-Info "Max Retries: ${MaxRetries} (wait ${RetryWait}s between retries)"
Write-Info "Log Location: $logDir\openclaw-monitor-YYYYMMDD.log"
Write-Info "Diagnostic Reports: $logDir\diagnostics\"
Write-Info ""

# Run now if requested
if ($RunNow) {
    Write-Info "Starting monitor service..."
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 2
    
    $taskState = (Get-ScheduledTask -TaskName $TaskName).State
    Write-Info "Task State: $taskState"
}

# Common commands
Write-Info "=========================================="
Write-Info "Common Commands:"
Write-Info "  Check task status: Get-ScheduledTask -TaskName '$TaskName' | Get-ScheduledTaskInfo"
Write-Info "  Start manually: Start-ScheduledTask -TaskName '$TaskName'"
Write-Info "  Stop: Stop-ScheduledTask -TaskName '$TaskName'"
Write-Info "  View logs: Get-Content '$logDir\openclaw-monitor-$(Get-Date -Format 'yyyyMMdd').log' -Tail 20 -Wait"
Write-Info "  Uninstall: .\install-openclaw-monitor.ps1 -Uninstall"
Write-Info "=========================================="
