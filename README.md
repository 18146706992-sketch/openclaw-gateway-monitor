# OpenClaw Gateway Monitor

[![PowerShell](https://img.shields.io/badge/PowerShell-5+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078d4.svg)](https://www.microsoft.com/windows/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README_en.md) | [简体中文](README_zh.md)

---

OpenClaw Gateway 自动化监控脚本，支持自动重启和故障排除。

## ✨ 功能特性

- **开机自启动**：通过 Windows 计划任务实现开机自动运行
- **健康监控**：使用 `openclaw health` 和 `gateway status` 命令检测状态
- **自动修复**：重启失败时自动重试（默认 3 次，间隔 60 秒）
- **故障排除**：修复失败时自动执行诊断并生成报告
- **日志记录**：日志保存到 `D:\.openclaw\logs\`

## 🚀 快速开始

### 安装（自动开机自启动）

```powershell
powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -RunNow
```

### 常用命令

```powershell
# 单次检测模式
powershell -ExecutionPolicy Bypass -File openclaw-monitor.ps1 -Once

# 持续监控模式（默认 60 秒检测一次）
powershell -ExecutionPolicy Bypass -File openclaw-monitor.ps1

# 自定义参数
powershell -ExecutionPolicy Bypass -File openclaw-monitor.ps1 -CheckInterval 30 -MaxRetries 5 -RetryWait 120

# 卸载
powershell -ExecutionPolicy Bypass -File install-openclaw-monitor.ps1 -Uninstall
```

## 📡 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-CheckInterval` | 60 | 检测间隔（秒） |
| `-MaxRetries` | 3 | 最大重启重试次数 |
| `-RetryWait` | 60 | 重试间隔（秒） |
| `-Once` | false | 单次检测后退出 |
| `-LogDir` | `D:\.openclaw\logs` | 日志目录 |

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

## 📁 日志文件

| 文件 | 说明 |
|------|------|
| `D:\.openclaw\logs\openclaw-monitor-YYYYMMDD.log` | 每日监控日志 |
| `D:\.openclaw\logs\diagnostics\diagnostic-YYYYMMDD-HHmmss.txt` | 诊断报告 |

## 🛠️ 常用管理命令

```powershell
# 查看计划任务状态
Get-ScheduledTask -TaskName 'OpenClawGatewayMonitor' | Get-ScheduledTaskInfo

# 查看实时日志
Get-Content 'D:\.openclaw\logs\openclaw-monitor-20260415.log' -Tail 20 -Wait

# 停止监控
Stop-ScheduledTask -TaskName 'OpenClawGatewayMonitor'

# 手动启动监控
Start-ScheduledTask -TaskName 'OpenClawGatewayMonitor'
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

诊断报告保存在 `D:\.openclaw\logs\diagnostics\` 目录。

官方故障排除文档：https://docs.openclaw.ai/troubleshooting

## 📄 开源协议

MIT
