# ============================================================
# OpenClaw Gateway Monitor Script
# Monitor OpenClaw Gateway status, auto-restart and troubleshoot
# Usage: powershell -ExecutionPolicy Bypass -File openclaw-monitor.ps1
# ============================================================

param(
    [int]$CheckInterval = 60,
    [int]$MaxRetries = 3,
    [int]$RetryWait = 60,
    [switch]$Once,
    [string]$LogDir = "D:\.openclaw\logs"
)

# ============================================================
# Helper Functions
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if (!(Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
    $logFile = Join-Path $LogDir "openclaw-monitor-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
}

function Get-GatewayStatus {
    $status = @{
        IsHealthy = $false
        Runtime = $null
        RPCProbe = $null
        ErrorMessage = $null
        RawOutput = $null
        HealthCheck = $null
    }
    
    try {
        # Primary check: use openclaw health (most reliable)
        $healthOutput = & openclaw health 2>&1 | Out-String
        $status.HealthCheck = $healthOutput
        
        # Check if Feishu: ok appears in health output
        if ($healthOutput -match 'Feishu:\s*(\w+)') {
            $feishuStatus = $Matches[1]
            $status.IsHealthy = ($feishuStatus -eq "ok")
        }
        
        # Secondary check: gateway status
        $output = & openclaw gateway status 2>&1 | Out-String
        $status.RawOutput = $output
        
        if ($output -match 'Runtime:\s*(\w+)') {
            $status.Runtime = $Matches[1]
        }
        
        if ($output -match 'RPC probe:\s*(\w+)') {
            $status.RPCProbe = $Matches[1]
        }
        
        # Consider healthy if:
        # 1. Feishu: ok in health check, OR
        # 2. Runtime = running AND RPC probe = ok, OR
        # 3. RPC probe = ok (Gateway is responding)
        if (!$status.IsHealthy) {
            $status.IsHealthy = ($status.Runtime -eq "running") -or ($status.RPCProbe -eq "ok")
        }
    }
    catch {
        $status.ErrorMessage = $_.Exception.Message
        Write-Log "Failed to execute health check: $($_.Exception.Message)" "ERROR"
    }
    
    return $status
}

function Start-GatewayService {
    try {
        Write-Log "Attempting to start Gateway service..."
        & openclaw gateway start 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Gateway start command executed" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Gateway start returned non-zero exit code: $LASTEXITCODE" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Failed to start Gateway: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restart-GatewayService {
    try {
        Write-Log "Attempting to restart Gateway service..."
        & openclaw gateway restart 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Gateway restart command executed" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Gateway restart returned non-zero exit code: $LASTEXITCODE" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Failed to restart Gateway: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-Troubleshooting {
    Write-Log "========== Entering Troubleshooting ==========" "WARN"
    
    $steps = @(
        @{
            Name = "Step 1: openclaw status"
            Cmd = { & openclaw status 2>&1 | Out-String }
        },
        @{
            Name = "Step 2: openclaw gateway status"
            Cmd = { & openclaw gateway status 2>&1 | Out-String }
        },
        @{
            Name = "Step 3: openclaw doctor"
            Cmd = { & openclaw doctor 2>&1 | Out-String }
        },
        @{
            Name = "Step 4: openclaw channels status --probe"
            Cmd = { & openclaw channels status --probe 2>&1 | Out-String }
        }
    )
    
    $diagnosticResult = @()
    
    foreach ($step in $steps) {
        Write-Log "Executing: $($step.Name)" "WARN"
        try {
            $output = & $step.Cmd
            $diagnosticResult += "[$($step.Name)]`n$output`n"
            Write-Log "$($step.Name) completed" "SUCCESS"
        }
        catch {
            $diagnosticResult += "[$($step.Name)] Failed: $($_.Exception.Message)`n"
            Write-Log "$($step.Name) Failed: $($_.Exception.Message)" "ERROR"
        }
    }
    
    $reportDir = Join-Path $LogDir "diagnostics"
    if (!(Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $reportFile = Join-Path $reportDir "diagnostic-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $diagnosticResult | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Log "Diagnostic report saved: $reportFile" "INFO"
    
    # Check for common issues
    Write-Log "========== Common Issue Checks ==========" "WARN"
    
    $gatewayOutput = & openclaw gateway status 2>&1 | Out-String
    
    if ($gatewayOutput -match 'EADDRINUSE|already listening') {
        Write-Log "[Port Conflict] Port is already in use, trying to resolve..." "ERROR"
        $port = if ($gatewayOutput -match 'port (\d+)') { $Matches[1] } else { "18789" }
        $procId = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
        if ($procId) {
            $procName = (Get-Process -Id $procId -ErrorAction SilentlyContinue).ProcessName
            Write-Log "Port $port is used by process ID $procId ($procName)" "ERROR"
        }
    }
    
    if ($gatewayOutput -match 'Gateway start blocked|set gateway\.mode') {
        Write-Log "[Config Error] Gateway start blocked, check gateway.mode config" "ERROR"
        Write-Log "Hint: Run openclaw configure or set gateway.mode=local" "WARN"
    }
    
    if ($gatewayOutput -match 'refusing to bind|without auth') {
        Write-Log "[Auth Error] Non-loopback bind requires auth config" "ERROR"
    }
    
    Write-Log "========== Troubleshooting Complete ==========" "WARN"
    Write-Log "Please check diagnostic report: $reportFile" "INFO"
    Write-Log "Official troubleshooting docs: https://docs.openclaw.ai/troubleshooting" "INFO"
    
    return $reportFile
}

# ============================================================
# Main Monitoring Loop
# ============================================================

function Start-Monitoring {
    Write-Log "=========================================="
    Write-Log "OpenClaw Gateway Monitor Started"
    Write-Log "Check Interval: ${CheckInterval} seconds"
    Write-Log "Max Retries: ${MaxRetries}"
    Write-Log "Retry Wait: ${RetryWait} seconds"
    Write-Log "=========================================="
    
    $runCount = 0
    
    while ($true) {
        $runCount++
        Write-Log "========== Check Cycle #$runCount =========="
        
        $gatewayStatus = Get-GatewayStatus
        
        Write-Log "Gateway Status Check Result:"
        Write-Log "  - Runtime: $($gatewayStatus.Runtime)"
        Write-Log "  - RPC Probe: $($gatewayStatus.RPCProbe)"
        Write-Log "  - Healthy: $($gatewayStatus.IsHealthy)"
        
        if ($gatewayStatus.IsHealthy) {
            Write-Log "Gateway is running normally" "SUCCESS"
        }
        else {
            Write-Log "Gateway status abnormal, starting repair flow..." "WARN"
            
            $retryCount = 0
            $repairSuccess = $false
            
            while ($retryCount -lt $MaxRetries -and !$repairSuccess) {
                $retryCount++
                Write-Log "========== Repair Attempt #$retryCount/$MaxRetries =========="
                
                if ($retryCount -eq 1) {
                    $started = Start-GatewayService
                }
                else {
                    $started = Restart-GatewayService
                }
                
                if ($started) {
                    Write-Log "Waiting ${RetryWait} seconds before checking status..."
                    Start-Sleep -Seconds $RetryWait
                    
                    $gatewayStatus = Get-GatewayStatus
                    
                    if ($gatewayStatus.IsHealthy) {
                        Write-Log "Repair successful! Gateway restored" "SUCCESS"
                        $repairSuccess = $true
                    }
                    else {
                        Write-Log "Status still unhealthy after repair (Runtime: $($gatewayStatus.Runtime), RPC: $($gatewayStatus.RPCProbe))" "WARN"
                    }
                }
                else {
                    Write-Log "Start/restart command failed" "ERROR"
                }
                
                if (!$repairSuccess -and $retryCount -lt $MaxRetries) {
                    Write-Log "Will retry in ${RetryWait} seconds..." "WARN"
                }
            }
            
            if (!$repairSuccess) {
                Write-Log "========== All retries failed, entering troubleshooting ==========" "ERROR"
                $reportFile = Invoke-Troubleshooting
            }
        }
        
        if ($Once) {
            Write-Log "Single check completed, exiting"
            break
        }
        
        Write-Log "Waiting ${CheckInterval} seconds for next check..."
        Start-Sleep -Seconds $CheckInterval
    }
}

# ============================================================
# Entry Point
# ============================================================

try {
    Start-Monitoring
}
catch {
    Write-Log "Monitor service error exit: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
