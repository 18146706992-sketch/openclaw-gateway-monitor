# ============================================================
# OpenClaw Gateway Monitor - Install/Uninstall Script
# Uses Windows Startup Folder for auto-start (no admin required)
# Usage: 
#   Install: powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -RunNow
#   Uninstall: powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -Uninstall
# ============================================================

param(
    [string]$ScriptName = "OpenClawGatewayMonitor",
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

# Determine directories
$startupFolder = [Environment]::GetFolderPath("Startup")
$logBaseDir = if ($env:OPENCLAW_STATE_DIR) {
    Join-Path $env:OPENCLAW_STATE_DIR "logs"
} else {
    Join-Path (Split-Path $PSCommandPath -Parent) "logs"
}

$shortcutPath = Join-Path $startupFolder "$ScriptName.lnk"

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
# Create Shortcut Function
# ============================================================
function New-StartupShortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$Arguments,
        [string]$Description
    )
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$TargetPath`" $Arguments"
        $Shortcut.Description = $Description
        $Shortcut.WorkingDirectory = Split-Path $TargetPath -Parent
        $Shortcut.Save()
        
        return $true
    }
    catch {
        Write-Err "Failed to create shortcut: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================
# Stop Monitor
# ============================================================
if ($Stop) {
    Write-Info "Stopping OpenClaw Gateway Monitor..."
    
    # Stop running monitor processes
    $processes = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match "openclaw-monitor" }
    
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Info "Stopped monitor process (PID: $($proc.Id))"
            } catch {
                Write-Warn "Could not stop process $($proc.Id)"
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
    
    # Step 1: Stop all monitor processes
    $processes = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match "openclaw-monitor" }
    
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Info "Stopped monitor process (PID: $($proc.Id))"
            } catch { }
        }
        Start-Sleep -Milliseconds 500
    } else {
        Write-Info "No running monitor process found"
    }
    
    # Step 2: Remove startup shortcut
    if (Test-Path $shortcutPath) {
        try {
            Remove-Item $shortcutPath -Force -ErrorAction Stop
            Write-Success "Startup shortcut removed"
        } catch {
            Write-Warn "Could not remove shortcut: $($_.Exception.Message)"
        }
    } else {
        Write-Info "No startup shortcut found"
    }
    
    # Verify
    $verifyProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match "openclaw-monitor" }
    $verifyShortcut = Test-Path $shortcutPath
    
    if (-not $verifyProcess -and -not $verifyShortcut) {
        Write-Success "Uninstall complete - all components removed"
    } else {
        Write-Warn "Uninstall completed with warnings"
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

# Verify monitor script exists
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

# Build startup arguments
$startupArgs = "-CheckInterval $CheckInterval -MaxRetries $MaxRetries -RetryWait $RetryWait"

# Remove existing shortcut if present
if (Test-Path $shortcutPath) {
    Write-Info "Existing startup shortcut found, removing..."
    try {
        Remove-Item $shortcutPath -Force -ErrorAction Stop
    } catch {
        Write-Warn "Could not remove existing shortcut: $($_.Exception.Message)"
    }
}

# Create startup shortcut
Write-Info "Creating startup shortcut..."
$created = New-StartupShortcut -ShortcutPath $shortcutPath -TargetPath $ScriptPath -Arguments $startupArgs -Description "OpenClaw Gateway Monitor"

if ($created) {
    Write-Success "Startup shortcut created: $shortcutPath"
} else {
    Write-Err "Failed to create startup shortcut"
    exit 1
}

# Show info
Write-Info ""
Write-Info "=========================================="
Write-Info "Installation Complete!"
Write-Info "=========================================="
Write-Info ""
Write-Info "Startup Shortcut: $shortcutPath"
Write-Info "Monitor Script: $ScriptPath"
Write-Info "Check Interval: ${CheckInterval} seconds"
Write-Info "Max Retries: ${MaxRetries}"
Write-Info "Retry Wait: ${RetryWait} seconds"
Write-Info "Log Location: $logBaseDir\openclaw-monitor\"
Write-Info ""

# Run now if requested
if ($RunNow) {
    Write-Info "Starting monitor service..."
    $args = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ScriptPath`" $startupArgs"
    Start-Process -FilePath "powershell.exe" -ArgumentList $args
    Start-Sleep -Seconds 2
    Write-Success "Monitor started"
}

# Verify startup shortcut exists
if (Test-Path $shortcutPath) {
    Write-Success "Startup shortcut verified"
}

# Common commands
Write-Info ""
Write-Info "=========================================="
Write-Info "Management Commands:"
Write-Info "  Check status: Get-Process powershell | Where-Object {`$_.CommandLine -match 'openclaw-monitor'}"
Write-Info "  View logs: Get-Content '$logBaseDir\openclaw-monitor\openclaw-monitor-$(Get-Date -Format 'yyyyMMdd').log' -Tail 20 -Wait"
Write-Info "  Stop: powershell -ExecutionPolicy Bypass -File '$PSCommandPath' -Stop"
Write-Info "  Uninstall: powershell -ExecutionPolicy Bypass -File '$PSCommandPath' -Uninstall"
Write-Info "=========================================="
