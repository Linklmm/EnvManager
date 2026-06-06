# EnvManager

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos)

一款 macOS 原生菜单栏应用，用于管理和切换多套开发环境配置。

## 功能特性

### 🎯 核心功能

- **环境分组管理** - 创建/编辑/删除环境分组，每个分组可包含多个配置项
- **一键切换** - 激活分组后自动写入 Shell 配置文件，切换分组时自动清理旧配置
- **菜单栏快速访问** - 状态栏常驻图标，点击即可快速切换环境

### 📦 支持的配置类型

| 类型 | 说明 | Shell 写入格式 |
|------|------|----------------|
| 环境变量 | 标准 export 变量 | `export KEY="value"` |
| Shell 配置 | 非 export 的 Shell 变量 | `KEY="value"` |
| PATH | 迥加到 PATH 环境变量 | `export PATH=/path:$PATH` |
| Alias | 命令别名 | `alias name='command'` |
| launchctl | 系统级环境变量 | `launchctl setenv KEY value` |

### 🐚 Shell 支持

- **zsh** - 写入 `~/.zshrc`
- **bash** - 写入 `~/.bashrc`
- **通用** - 同时写入两个配置文件

### 🔐 安全特性

- **敏感信息加密** - AES-GCM 加密存储敏感值，显示为星号 `********`
- **Keychain 密钥管理** - 加密密钥安全存储在 macOS Keychain

### 📋 其他功能

- **操作历史** - SQLite 记录所有操作，支持回滚
- **内置模板** - Python / Java / Node.js / Go / System 五套预设模板
- **配置导入导出** - JSON 格式备份和恢复
- **45 个技术图标** - 15 种语言 + 20 个框架 + 10 个通用图标

## 界面预览

### 主窗口 - 分组列表

![分组列表](screenshots/groups-list.png)

显示所有环境分组，每个分组包含：
- 可自定义的技术图标
- 分组名称和颜色
- 变量数量统计
- 激活状态开关

### 主窗口 - 分组详情

![分组详情](screenshots/group-detail.png)

查看分组内的所有配置项：
- 配置类型图标标识
- 变量名和值（敏感值显示为星号）
- Shell 类型标签
- 快速编辑和删除

### 菜单栏弹出视图

![菜单栏](screenshots/menu-bar.png)

快速切换环境：
- 点击状态栏齿轮图标弹出
- 一键激活/取消分组
- 显示当前激活状态

### 编辑弹窗

![编辑弹窗](screenshots/edit-sheet.png)

创建和编辑配置项：
- 两级配置类型选择器
- 动态表单（根据类型显示不同字段）
- Shell 类型选择

## 系统要求

- macOS 12.0 (Monterey) 或更高版本
- Xcode 14.0+ (用于编译)

## 安装

### 方式一：下载 DMG 安装包（推荐）

从 [GitHub Releases](https://github.com/Linklmm/EnvManager/releases) 下载最新的 DMG 安装包。

```bash
# 1. 下载 DMG 并安装
# 打开 DMG，将 EnvManager 拖到 Applications 文件夹

# 2. 重要：移除隔离属性（ macOS 会标记未签名应用为"已损坏"）
xattr -cr /Applications/EnvManager.app

# 3. 打开应用
open /Applications/EnvManager.app
```

> **注意**：由于应用未签名，macOS Gatekeeper 会阻止运行。使用 `xattr -cr` 命令移除隔离属性后即可正常使用。

### 方式二：从源码编译

```bash
# 克隆仓库
git clone https://github.com/Linklmm/EnvManager.git
cd EnvManager

# 使用 Xcode 打开项目
open EnvManager.xcodeproj

# 或使用命令行编译
xcodebuild build -scheme EnvManager -configuration Release
```

编译完成后，应用会出现在 `build/Release/` 目录中，双击即可运行。

## 数据存储位置

| 数据 | 位置 |
|------|------|
| 分组配置 | `~/Library/Application Support/EnvManager/config.json` |
| 操作历史 | `~/Library/Application Support/EnvManager/history.db` |
| 加密密钥 | macOS Keychain (Tag: `EnvManagerCryptoKey`) |
| Shell 配置 | `~/.zshrc` / `~/.bashrc` (使用标记包裹) |

## Shell 配置写入方式

EnvManager 使用标记包裹写入的内容：

```bash
# === EnvManager Begin ===
# EnvManager Group: 分组名称
export JAVA_HOME="/path/to/java"
export PATH=/path/to/bin:$PATH
alias jrun='java -jar'
# === EnvManager End ===
```

切换分组时会自动移除旧配置块，不会影响用户的其他配置。

## 技术架构

- **UI**: SwiftUI + MVVM 架构
- **并发**: Swift Actor 模型确保线程安全
- **数据同步**: Combine 响应式数据流
- **加密**: AES-GCM + Keychain

## 许可证

本项目采用 [Apache License 2.0](LICENSE) 许可证。

```
Copyright 2024 Linklmm

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 作者

Linklmm - [GitHub](https://github.com/Linklmm)