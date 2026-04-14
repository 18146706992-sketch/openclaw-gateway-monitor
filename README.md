# OpenClaw Gateway Monitor

Automated monitoring script for OpenClaw Gateway with auto-restart and troubleshooting capabilities.

## Features

- **Auto-start at system boot** via Windows Scheduled Task
- **Health monitoring** using openclaw health and gateway status commands
- **Auto-repair** with retry mechanism (3 attempts, 60s interval)
- **Troubleshooting** with diagnostic reports when repair fails
- **Logging** to D:\.openclaw\logs\\n
## Files

| File | Description |
|------|-------------|
| openclaw-monitor.ps1 | Main monitoring script |
| install-openclaw-monitor.ps1 | Installation/uninstallation script |

## Quick Start

### Installation
`powershell
powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -RunNow
`

### Usage
`powershell
# Single check mode
powershell -ExecutionPolicy Bypass -File openclaw-monitor.ps1 -Once

# Continuous monitoring (default 60s interval)
powershell -ExecutionPolicy Bypass -File openclaw-monitor.ps1

# Custom settings
powershell -ExecutionPolicy Bypass -File openclaw-monitor.ps1 -CheckInterval 30 -MaxRetries 5 -RetryWait 120
`\n
### Uninstall
`powershell
powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -Uninstall
`\n
## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| -CheckInterval | 60 | Detection interval in seconds |
| -MaxRetries | 3 | Maximum restart retry attempts |
| -RetryWait | 60 | Wait time between retries (seconds) |
| -Once | false | Run single check and exit |
| -LogDir | D:\.openclaw\logs | Log output directory |

## Troubleshooting Flow

`\nGateway Status Check
       |
   Normal -> No action
       |
   Abnormal -> Start/Restart Gateway
       |
   Wait 60s -> Check again
       |
   Still down -> Retry (max 3 times)
       |
   All failed -> Run diagnostics
       |
   Generate report -> Log to diagnostics\\n`\n
## Log Files

- D:\.openclaw\logs\openclaw-monitor-YYYYMMDD.log - Daily monitor logs
- D:\.openclaw\logs\diagnostics\diagnostic-YYYYMMDD-HHmmss.txt - Diagnostic reports

## Common Commands
\n`powershell
# Check scheduled task status
Get-ScheduledTask -TaskName 'OpenClawGatewayMonitor' | Get-ScheduledTaskInfo
\n# View real-time logs
Get-Content 'D:\.openclaw\logs\openclaw-monitor-20260415.log' -Tail 20 -Wait
\n# Stop monitor
Stop-ScheduledTask -TaskName 'OpenClawGatewayMonitor'\n\n# Start monitor manually
Start-ScheduledTask -TaskName 'OpenClawGatewayMonitor'\n`\n
## Health Criteria
\nThe monitor considers Gateway healthy if ANY of:
- Feishu: ok in openclaw health output
- Runtime: running in openclaw gateway status output
- RPC probe: ok in openclaw gateway status output
