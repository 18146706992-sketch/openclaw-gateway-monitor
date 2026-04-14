# OpenClaw Gateway Monitor

[![PowerShell](https://img.shields.io/badge/PowerShell-5+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078d4.svg)](https://www.microsoft.com/windows/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md) | [简体中文](README_zh.md)

---

Automated monitoring script for OpenClaw Gateway with auto-restart and troubleshooting capabilities.

## 🚀 Quick Start

### One-line Install (Recommended)

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile \"$env:TEMP\install-ocm.ps1\"; & \"$env:TEMP\install-ocm.ps1\" -RunNow"
```

> If you get an error, wait 2-3 minutes and try again (GitHub CDN may need time to update).

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

### View Logs
```powershell
Get-Content "$env:OPENCLAW_STATE_DIR\logs\openclaw-monitor\openclaw-monitor-$(Get-Date -Format 'yyyyMMdd').log" -Tail 20 -Wait
```

### Stop Monitor
```powershell
powershell -ExecutionPolicy Bypass -Command "iwr 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile \"$env:TEMP\stop-ocm.ps1\"; & \"$env:TEMP\stop-ocm.ps1\" -Stop"
```

### Restart Monitor
```powershell
Start-ScheduledTask -TaskName 'OpenClawGatewayMonitor'
```

### Uninstall
```powershell
powershell -ExecutionPolicy Bypass -Command "iwr 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile \"$env:TEMP\uninstall-ocm.ps1\"; & \"$env:TEMP\uninstall-ocm.ps1\" -Uninstall"
```

---

## ✨ Features

- **Auto-start at boot**: Windows Scheduled Task integration
- **Health monitoring**: Uses `openclaw health` and `gateway status`
- **Auto-repair**: 3 retries with 60s interval
- **Troubleshooting**: Auto-generates diagnostic reports
- **Logging**: Saved to `openclaw-monitor\` under OpenClaw state directory

## 📁 Log Directory

```
<OPENCLAW_STATE_DIR>\logs\openclaw-monitor\
├── openclaw-monitor-YYYYMMDD.log
└── diagnostics\diagnostic-YYYYMMDD-HHmmss.txt
```

## 📄 License

MIT
