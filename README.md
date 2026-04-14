# OpenClaw Gateway Monitor

[![PowerShell](https://img.shields.io/badge/PowerShell-5+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078d4.svg)](https://www.microsoft.com/windows/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md) | [简体中文](README_zh.md)

---

Automated monitoring script for OpenClaw Gateway with auto-restart and troubleshooting capabilities.

## 🚀 Quick Start

### One-line Install (Recommended)

Run this command **directly from GitHub** — no download required:

```powershell
powershell -ExecutionPolicy Bypass -Command "`$temp=[System.IO.Path]::GetTempFileName()+'.ps1'; Invoke-WebRequest 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile `$temp; & `$temp -RunNow; Remove-Item `$temp"
```

### Manual Install

1. Download scripts from [GitHub](https://github.com/18146706992-sketch/openclaw-gateway-monitor/tree/main/scripts)
2. Open PowerShell in the scripts directory
3. Run:
```powershell
.\install-openclaw-monitor.ps1 -RunNow
```

## 🛠️ Management Commands

### Check Status
```powershell
Get-ScheduledTask -TaskName 'OpenClawGatewayMonitor' | Get-ScheduledTaskInfo
```

### View Logs (Real-time)
```powershell
Get-Content 'D:\.openclaw\logs\openclaw-monitor\openclaw-monitor-20260415.log' -Tail 20 -Wait
```

### Stop Monitor
```powershell
Stop-ScheduledTask -TaskName 'OpenClawGatewayMonitor'
```

### Restart Monitor
```powershell
Start-ScheduledTask -TaskName 'OpenClawGatewayMonitor'
```

### Uninstall
```powershell
powershell -ExecutionPolicy Bypass -Command "`$temp=[System.IO.Path]::GetTempFileName()+'.ps1'; Invoke-WebRequest 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile `$temp; & `$temp -Uninstall; Remove-Item `$temp"
```

---

## ✨ Features

- **Auto-start at boot**: Windows Scheduled Task integration for hands-free operation
- **Health monitoring**: Uses `openclaw health` and `gateway status` for reliable detection
- **Auto-repair**: Automatic restart with retry mechanism (3 attempts, 60s interval)
- **Troubleshooting**: Auto-generates diagnostic reports when repair fails
- **Logging**: Logs saved to `openclaw-monitor\` under your OpenClaw state directory

## 📡 Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-CheckInterval` | 60 | Detection interval in seconds |
| `-MaxRetries` | 3 | Maximum restart retry attempts |
| `-RetryWait` | 60 | Wait time between retries (seconds) |
| `-Once` | false | Run single check and exit |
| `-LogDir` | auto | Log directory (auto-detected) |

## 📁 Log Directory

Logs are automatically saved to your OpenClaw state directory:

```
<OPENCLAW_STATE_DIR>\logs\openclaw-monitor\
├── openclaw-monitor-YYYYMMDD.log    # Daily monitor logs
└── diagnostics\                      # Diagnostic reports
    └── diagnostic-YYYYMMDD-HHmmss.txt
```

## 🔄 Workflow

```
Gateway Status Check
        │
   Normal → No action
        │
   Abnormal → Start/Restart Gateway
        │
   Wait 60s → Check again
        │
   Still down → Retry (max 3 times)
        │
   All failed → Run diagnostics
        │
   Generate report → Save to diagnostics\
```

## ✅ Health Criteria

Gateway is considered **healthy** if ANY of:

- `Feishu: ok` in `openclaw health` output
- `Runtime: running` in `openclaw gateway status` output
- `RPC probe: ok` in `openclaw gateway status` output

## 🔧 Troubleshooting

When auto-repair fails, the script runs:

1. `openclaw status`
2. `openclaw gateway status`
3. `openclaw doctor`
4. `openclaw channels status --probe`

Diagnostic reports are saved to the `diagnostics\` subdirectory.

Official docs: https://docs.openclaw.ai/troubleshooting

## 📄 License

MIT
