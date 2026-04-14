# ============================================================
# OpenClaw Gateway Monitor - Install/Uninstall Script
# Create Windows Scheduled Task for auto-start at boot
# Usage: 
#   Install: powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -RunNow
#   Uninstall: powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -Uninstall
# ============================================================

param(
    [string]$TaskName = "OpenClawGatewayMonitor",
    [string]$ScriptPath = "",
    [int]$CheckInterval = 60,
    [int]$MaxRetries = 3,
    [int]$RetryWait = 60,
    [switch]$Uninstall,
    [switch]$RunNow,
    [switch]$Stop
)

# Auto-detect script path if not provided
if ($ScriptPath -eq "") {
    $ScriptPath = Join-Path (Split-Path $PSCommandPath -Parent) "openclaw-monitor.ps1"
}

# Determine log directory based on OPENCLAW_STATE_DIR
$logBaseDir = if ($env:OPENCLAW_STATE_DIR) {
    Join-Path $env:OPENCLAW_STATE_DIR "logs"
} else {
    Join-Path (Split-Path $PSCommandPath -Parent) "logs"
}

$ErrorActionPreference = "Continue"

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
# Stop Monitor (keep scheduled task, just stop the process)
# ============================================================

if ($Stop) {
    Write-Info "Stopping OpenClaw Gateway Monitor..."
    
    # Stop scheduled task first
    try {
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Write-Info "Scheduled task stopped"
    } catch {
        Write-Warn "Could not stop scheduled task: $($_.Exception.Message)"
    }
    
    # Stop running monitor processes
    $processes = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match "openclaw-monitor" }
    
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Info "Stopped monitor process (PID: $($proc.Id))"
            } catch {
                Write-Warn "Could not stop process $($proc.Id): $($_.Exception.Message)"
            }
        }
    } else {
        Write-Info "No running monitor process found"
    }
    
    Write-Success "Monitor stopped"
    exit 0
}

# ============================================================
# Uninstall
# ============================================================

if ($Uninstall) {
    Write-Info "Uninstalling OpenClaw Gateway Monitor..."
    
    # Step 1: Stop all monitor processes first
    $processes = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match "openclaw-monitor" }
    
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Info "Stopped monitor process (PID: $($proc.Id))"
            } catch {
                # Ignore errors here
            }
        }
        Start-Sleep -Seconds 1
    } else {
        Write-Info "No running monitor process found"
    }
    
    # Step 2: Try to remove scheduled task
    $taskRemoved = $false
    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            # Try to stop first
            try {
                Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            } catch {
                # Ignore if stop fails
            }
            
            # Try to unregister
            try {
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
                Write-Success "Scheduled task removed"
                $taskRemoved = $true
            } catch {
                # Unregister failed - likely permission issue
                Write-Warn "Could not remove scheduled task automatically"
            }
        } else {
            Write-Info "No scheduled task found"
            $taskRemoved = $true
        }
    } catch {
        Write-Warn "Error checking scheduled task: $($_.Exception.Message)"
    }
    
    # Final status
    $verifyProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match "openclaw-monitor" }
    
    if (-not $verifyProcess) {
        Write-Success "Monitor process stopped"
    }
    
    if ($taskRemoved) {
        Write-Success "Uninstall complete"
    } else {
        Write-Info ""
        Write-Info "=========================================="
        Write-Info "Manual cleanup required:"
        Write-Info "  1. Open Task Scheduler (taskschd.msc)"
        Write-Info "  2. Find task: $TaskName"
        Write-Info "  3. Right-click -> Delete"
        Write-Info "=========================================="
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
if (!(Test-Path $logBaseDir)) {
    New-Item -ItemType Directory -Path $logBaseDir -Force | Out-Null
    Write-Info "Created log directory: $logBaseDir"
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
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    } catch {
        Write-Warn "Could not remove existing task: $($_.Exception.Message)"
    }
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
Write-Info "Log Location: $logBaseDir\openclaw-monitor\"
Write-Info "Diagnostic Reports: $logBaseDir\openclaw-monitor\diagnostics\"
Write-Info ""

# Run now if requested
if ($RunNow) {
    Write-Info "Starting monitor service..."
    Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    $taskState = (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue).State
    Write-Info "Task State: $taskState"
}

# Common commands
Write-Info "=========================================="
Write-Info "Common Commands:"
Write-Info "  Check status: Get-ScheduledTask -TaskName '$TaskName' | Get-ScheduledTaskInfo"
Write-Info "  Start: Start-ScheduledTask -TaskName '$TaskName'"
Write-Info "  Stop: powershell -ExecutionPolicy Bypass -File '$PWD\install-openclaw-monitor.ps1' -Stop"
Write-Info "  View logs: Get-Content '$logBaseDir\openclaw-monitor\openclaw-monitor-$(Get-Date -Format 'yyyyMMdd').log' -Tail 20 -Wait"
Write-Info "  Uninstall: powershell -ExecutionPolicy Bypass -File '$PWD\install-openclaw-monitor.ps1' -Uninstall"
Write-Info "=========================================="
