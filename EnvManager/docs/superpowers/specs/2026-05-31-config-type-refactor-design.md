# 配置类型重构设计

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构配置类型系统，区分 Shell 配置和系统配置，支持 zsh/bash 选择，提供动态表单界面。

**Architecture:** 将 EnvSource 替换为 ConfigType + ShellType 组合，实现动态表单，根据配置类型显示不同字段，Shell 配置类可选择目标 Shell。

**Tech Stack:** SwiftUI, Swift

---

## 背景

当前 EnvSource 的四种类型（手动添加、shell配置、系统级、应用级）功能相似，用户无法区分。实际开发场景需要：
- 区分 zsh 和 bash 配置文件
- 区分环境变量（export）和 Shell 配置（非 export）
- 支持 PATH 路径智能拼接
- 支持 Alias 别名配置

---

## 配置类型分类

### Shell 配置类（需要选择目标 Shell）

| 类型 | 表单字段 | 生成语句 | 写入文件 |
|------|----------|----------|----------|
| 环境变量 | key + value | `export KEY=value` | .zshrc / .bashrc |
| Shell 配置 | key + value | `KEY="value"` | .zshrc / .bashrc |
| PATH 路径 | 路径（单字段） | `export PATH=$PATH:/path` | .zshrc / .bashrc |
| Alias 别名 | 别名名 + 命令 | `alias name='command'` | .zshrc / .bashrc |

**Shell 选择器选项：**
- **zsh** - 写入 ~/.zshrc
- **bash** - 写入 ~/.bashrc
- **通用** - 同时写入两者

### 系统配置类（不需要 Shell 选择）

| 类型 | 表单字段 | 执行命令 | 影响范围 |
|------|----------|----------|----------|
| launchctl 环境变量 | key + value | `launchctl setenv KEY value` | 全局系统 |

---

## 界面布局

```
┌─────────────────────────────────────┐
│  配置类型: [下拉选择]                │
│  ├─ Shell 配置                       │
│  │   ├─ 环境变量                     │
│  │   ├─ Shell 配置                   │
│  │   ├─ PATH 路径                    │
│  │   └─ Alias 别名                   │
│  └─ 系统配置                         │
│      └─ launchctl 环境变量           │
│                                      │
│  [Shell 选择器] (仅 Shell 配置显示)  │
│  zsh / bash / 通用                   │
│                                      │
│  [动态表单区域]                       │
│  ├─ 环境变量: key + value + 描述     │
│  ├─ Shell配置: key + value + 描述    │
│  ├─ PATH路径: 路径 + 描述             │
│  ├─ Alias别名: 别名 + 命令 + 描述    │
│  └─ launchctl: key + value + 描述    │
│                                      │
│  [保存] [取消]                        │
└─────────────────────────────────────┘
```

### 动态表单逻辑

- 选择 **Shell 配置类** → 显示 Shell 选择器 + 对应表单字段
- 选择 **系统配置类** → 不显示 Shell 选择器，显示 key/value 表单

---

## 数据模型

### ConfigType 枚举

```swift
/// 配置类型
enum ConfigType: String, Codable, CaseIterable {
    /// 环境变量 - export KEY=value
    case envVariable
    /// Shell 配置 - KEY="value" (非 export)
    case shellConfig
    /// PATH 路径 - export PATH=$PATH:/path
    case path
    /// Alias 别名 - alias name='command'
    case alias
    /// 系统级环境变量 - launchctl setenv KEY value
    case launchctl

    /// 是否为 Shell 配置类
    var isShellConfig: Bool {
        switch self {
        case .envVariable, .shellConfig, .path, .alias:
            return true
        case .launchctl:
            return false
        }
    }

    /// 显示名称
    var displayName: String {
        switch self {
        case .envVariable: return "环境变量"
        case .shellConfig: return "Shell 配置"
        case .path: return "PATH 路径"
        case .alias: return "Alias 别名"
        case .launchctl: return "系统级环境变量"
        }
    }

    /// 分组显示
    var groupName: String {
        return isShellConfig ? "Shell 配置" : "系统配置"
    }
}
```

### ShellType 枚举

```swift
/// Shell 类型
enum ShellType: String, Codable, CaseIterable {
    case zsh
    case bash
    case both  // 通用，两者都写

    /// 显示名称
    var displayName: String {
        switch self {
        case .zsh: return "zsh"
        case .bash: return "bash"
        case .both: return "通用"
        }
    }

    /// 配置文件路径
    var configFilePaths: [String] {
        switch self {
        case .zsh:
            return ["~/.zshrc"]
        case .bash:
            return ["~/.bashrc"]
        case .both:
            return ["~/.zshrc", "~/.bashrc"]
        }
    }
}
```

### EnvVariable 模型修改

```swift
/// 环境变量模型
struct EnvVariable: Identifiable, Codable, Hashable {
    let id: UUID
    var configType: ConfigType      // 替换原 source 字段
    var shellType: ShellType?       // Shell 配置类才有
    var key: String?                // env/shell/launchctl 有，path/alias 无
    var value: String               // 所有类型都有（PATH 用 path 字段，alias 用别名名）
    var aliasCommand: String?       // alias 类型专用
    var isSensitive: Bool
    var encryptedValue: String?
    var description: String?
    let createdAt: Date

    /// 生成实际配置语句
    func generateConfigStatement() -> String {
        switch configType {
        case .envVariable:
            return "export \(key ?? "")=\(value)"
        case .shellConfig:
            return "\(key ?? "")=\"\(value)\""
        case .path:
            return "export PATH=$PATH:\(value)"
        case .alias:
            return "alias \(value)='\(aliasCommand ?? "")'"
        case .launchctl:
            return "launchctl setenv \(key ?? "") \(value)"
        }
    }
}
```

---

## 界面组件

### ConfigTypePicker 组件

选择配置类型的下拉菜单，分组显示：

```swift
struct ConfigTypePicker: View {
    @Binding var selectedType: ConfigType

    var body: some View {
        Menu {
            // Shell 配置组
            Menu("Shell 配置") {
                ForEach([ConfigType.envVariable, .shellConfig, .path, .alias], id: \.self) { type in
                    Button(type.displayName) { selectedType = type }
                }
            }
            Divider()
            // 系统配置组
            Menu("系统配置") {
                Button(ConfigType.launchctl.displayName) { selectedType = .launchctl }
            }
        } label: {
            HStack {
                Text(selectedType.displayName)
                Image(systemName: "chevron.down")
            }
        }
    }
}
```

### ShellTypePicker 组件

Shell 选择器，仅在 Shell 配置类显示：

```swift
struct ShellTypePicker: View {
    @Binding var selectedShell: ShellType

    var body: some View {
        HStack(spacing: 12) {
            Text("目标 Shell:")
            ForEach(ShellType.allCases, id: \.self) { shell in
                Button(shell.displayName) {
                    selectedShell = shell
                }
                .buttonStyle(selectedShell == shell ? .borderedProminent : .bordered)
            }
        }
    }
}
```

### DynamicConfigForm 组件

根据配置类型动态显示表单字段：

```swift
struct DynamicConfigForm: View {
    @Binding var configType: ConfigType
    @Binding var shellType: ShellType
    @Binding var key: String
    @Binding var value: String
    @Binding var aliasCommand: String
    @Binding var description: String

    var body: Some View {
        VStack(spacing: 12) {
            // 根据类型显示不同字段
            switch configType {
            case .envVariable, .shellConfig, .launchctl:
                FormField(label: "变量名", binding: $key)
                FormField(label: "变量值", binding: $value)
            case .path:
                FormField(label: "路径", binding: $value)
            case .alias:
                FormField(label: "别名", binding: $value)
                FormField(label: "命令", binding: $aliasCommand)
            }

            // 描述字段（所有类型都有）
            FormField(label: "描述（可选）", binding: $description)
        }
    }
}
```

---

## 实现要求

1. 替换 EnvSource 为 ConfigType + ShellType
2. 修改 EnvVariable 模型结构
3. 创建 ConfigTypePicker、ShellTypePicker、DynamicConfigForm 组件
4. 修改 AddVariableSheet 使用新组件
5. 修改 EditVariableSheet 使用新组件
6. 更新 VariableListRow 显示逻辑
7. 更新 EnvService 写入逻辑，根据类型和 Shell 写入对应文件
8. 处理旧数据迁移（EnvSource → ConfigType）

---

## 测试要点

- 各配置类型生成正确的配置语句
- Shell 选择器正确显示/隐藏
- 动态表单字段正确切换
- 写入操作写入正确的配置文件
- launchctl 命令正确执行
- 旧数据正确迁移