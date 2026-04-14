# OpenClaw Gateway Monitor

[![PowerShell](https://img.shields.io/badge/PowerShell-5+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078d4.svg)](https://www.microsoft.com/windows/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md) | [简体中文](README_zh.md)

---

OpenClaw Gateway 自动化监控脚本，支持自动重启和故障排除。

## 🚀 快速开始

### 一键安装（推荐）

**无需下载**，直接运行以下命令：

```powershell
powershell -ExecutionPolicy Bypass -Command 'iwr "https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1" -OutFile "$env:TEMP\install-openclaw-monitor.ps1" -UseBasicParsing; & "$env:TEMP\install-openclaw-monitor.ps1" -RunNow; rm "$env:TEMP\install-openclaw-monitor.ps1"'
```

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

### 实时查看日志
```powershell
Get-Content "$env:OPENCLAW_STATE_DIR\logs\openclaw-monitor\openclaw-monitor-$(Get-Date -Format 'yyyyMMdd').log" -Tail 20 -Wait
```

### 停止监控
```powershell
Stop-ScheduledTask -TaskName 'OpenClawGatewayMonitor'
```

### 重新启动监控
```powershell
Start-ScheduledTask -TaskName 'OpenClawGatewayMonitor'
```

### 卸载
```powershell
powershell -ExecutionPolicy Bypass -Command 'iwr "https://raw.githubusercontent.com/18146706992-sketch/openclaw-gateway-monitor/main/scripts/install-openclaw-monitor.ps1" -OutFile "$env:TEMP\install-openclaw-monitor.ps1" -UseBasicParsing; & "$env:TEMP\install-openclaw-monitor.ps1" -Uninstall; rm "$env:TEMP\install-openclaw-monitor.ps1"'
```

---

## ✨ 功能特性

- **开机自启动**：通过 Windows 计划任务实现开机自动运行
- **健康监控**：使用 `openclaw health` 和 `gateway status` 命令检测状态
- **自动修复**：重启失败时自动重试（默认 3 次，间隔 60 秒）
- **故障排除**：修复失败时自动执行诊断并生成报告
- **日志记录**：日志保存在 OpenClaw 状态目录下的 `openclaw-monitor\` 子目录

## 📡 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-CheckInterval` | 60 | 检测间隔（秒） |
| `-MaxRetries` | 3 | 最大重启重试次数 |
| `-RetryWait` | 60 | 重试间隔（秒） |
| `-Once` | false | 单次检测后退出 |
| `-LogDir` | auto | 日志目录（自动检测） |

## 📁 日志目录

日志自动保存在 OpenClaw 状态目录下：

```
<OPENCLAW_STATE_DIR>\logs\openclaw-monitor\
├── openclaw-monitor-YYYYMMDD.log    # 每日监控日志
└── diagnostics\                      # 诊断报告
    └── diagnostic-YYYYMMDD-HHmmss.txt
```

## 🔄 工作流程

```
检测 Gateway 状态
       │
   正常 → 不做任何操作
       │
   异常 → 启动/重启 Gateway
       │
   等待 60 秒 → 再次检测
       │
   依然异常 → 重试（最多 3 次）
       │
   全部失败 → 执行故障排除
       │
   生成诊断报告 → 保存到 diagnostics\
```

## ✅ 健康判断标准

满足以下**任一条件**即视为健康：

- `openclaw health` 输出包含 `Feishu: ok`
- `openclaw gateway status` 输出 `Runtime: running`
- `openclaw gateway status` 输出 `RPC probe: ok`

## 🔧 故障排除

当脚本无法自动修复时，会执行以下诊断命令：

1. `openclaw status`
2. `openclaw gateway status`
3. `openclaw doctor`
4. `openclaw channels status --probe`

诊断报告保存在 `diagnostics\` 子目录。

官方故障排除文档：https://docs.openclaw.ai/troubleshooting

## 📄 开源协议

MIT
