# OpenClaw Gateway Monitor

[![PowerShell](https://img.shields.io/badge/PowerShell-5+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078d4.svg)](https://www.microsoft.com/windows/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md) | [简体中文](README_zh.md)

---

OpenClaw Gateway 自动化监控脚本，支持自动重启和故障排除。

## 🚀 快速开始

### 一键安装（推荐）

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile \"$env:TEMP\install-ocm.ps1\"; & \"$env:TEMP\install-ocm.ps1\" -RunNow"
```

> 如果报错，请等待 2-3 分钟后重试（GitHub CDN 可能需要时间更新）。

### 手动安装

1. 从 [GitHub](https://github.com/18146706992-sketch/openclaw-gateway-monitor/tree/main/scripts) 下载脚本
2. 在脚本所在目录打开 PowerShell
3. 运行：
```powershell
.\install-openclaw-monitor.ps1 -RunNow
```

## 🛠️ 管理命令

### 查看状态
```powershell
Get-ScheduledTask -TaskName 'OpenClawGatewayMonitor' | Get-ScheduledTaskInfo
```

### 查看日志
```powershell
Get-Content "$env:OPENCLAW_STATE_DIR\logs\openclaw-monitor\openclaw-monitor-$(Get-Date -Format 'yyyyMMdd').log" -Tail 20 -Wait
```

### 停止监控
```powershell
powershell -ExecutionPolicy Bypass -Command "iwr 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile \"$env:TEMP\stop-ocm.ps1\"; & \"$env:TEMP\stop-ocm.ps1\" -Stop"
```

### 重新启动监控
```powershell
Start-ScheduledTask -TaskName 'OpenClawGatewayMonitor'
```

### 卸载
```powershell
powershell -ExecutionPolicy Bypass -Command "iwr 'https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1' -OutFile \"$env:TEMP\uninstall-ocm.ps1\"; & \"$env:TEMP\uninstall-ocm.ps1\" -Uninstall"
```

---

## ✨ 功能特性

- **开机自启动**：Windows 计划任务
- **健康监控**：`openclaw health` 和 `gateway status`
- **自动修复**：3 次重试，间隔 60 秒
- **故障排除**：自动生成诊断报告
- **日志记录**：保存在 OpenClaw 状态目录的 `openclaw-monitor\` 下

## 📁 日志目录

```
<OPENCLAW_STATE_DIR>\logs\openclaw-monitor\
├── openclaw-monitor-YYYYMMDD.log
└── diagnostics\diagnostic-YYYYMMDD-HHmmss.txt
```

## 📄 开源协议

MIT
