# 配置类型重构实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构配置类型系统，将 EnvSource 替换为 ConfigType + ShellType，实现动态表单界面，支持 Shell 类型选择。

**Architecture:** 新建 ConfigType 和 ShellType 枚举，修改 EnvVariable 模型，创建动态表单组件，更新 ShellService 写入逻辑，处理旧数据迁移。

**Tech Stack:** SwiftUI, Swift

---

## 文件结构

**新建文件：**
- `Models/ConfigType.swift` - 配置类型枚举
- `Models/ShellType.swift` - Shell 类型枚举
- `Views/Components/ConfigTypePicker.swift` - 配置类型选择器
- `Views/Components/ShellTypePicker.swift` - Shell 选择器
- `Views/Components/DynamicConfigForm.swift` - 动态表单组件

**修改文件：**
- `Models/EnvVariable.swift` - 替换 source，添加新字段
- `Models/EnvSource.swift` - 删除（已废弃）
- `Views/MainWindow/MainWindowView.swift` - AddVariableSheet、EditVariableSheet、VariableListRow
- `Services/ShellService.swift` - 写入逻辑
- `Services/EnvService.swift` - 变量处理逻辑

---

### Task 1: 创建 ConfigType 枚举

**Files:**
- Create: `EnvManager/Models/ConfigType.swift`

- [ ] **Step 1: 创建 ConfigType.swift 文件**

```swift
import Foundation

/// 配置类型枚举
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

    /// 是否为 Shell 配置类（需要选择 Shell）
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

    /// 分组名称
    var groupName: String {
        return isShellConfig ? "Shell 配置" : "系统配置"
    }

    /// 图标
    var icon: String {
        switch self {
        case .envVariable: return "chevron.left.forwardslash.chevron.right"
        case .shellConfig: return "terminal"
        case .path: return "folder"
        case .alias: return "arrow.right"
        case .launchctl: return "gear"
        }
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED 或无错误

---

### Task 2: 创建 ShellType 枚举

**Files:**
- Create: `EnvManager/Models/ShellType.swift`

- [ ] **Step 1: 创建 ShellType.swift 文件**

```swift
import Foundation

/// Shell 类型枚举
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

    /// 配置文件路径（展开 ~ 为实际路径）
    var configFilePaths: [String] {
        let home = NSHomeDirectory()
        switch self {
        case .zsh:
            return [home + "/.zshrc"]
        case .bash:
            return [home + "/.bashrc"]
        case .both:
            return [home + "/.zshrc", home + "/.bashrc"]
        }
    }

    /// export 命令
    var exportCommand: String {
        return "export"
    }

    /// 描述
    var description: String {
        switch self {
        case .zsh: return "写入 ~/.zshrc"
        case .bash: return "写入 ~/.bashrc"
        case .both: return "同时写入 .zshrc 和 .bashrc"
        }
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 3: 修改 EnvVariable 模型

**Files:**
- Modify: `EnvManager/Models/EnvVariable.swift`

- [ ] **Step 1: 修改 EnvVariable 结构**

将原 `source: EnvSource` 替换为 `configType: ConfigType` 和 `shellType: ShellType?`，添加 `aliasCommand` 字段。

修改后的完整文件内容：

```swift
import Foundation

/// 环境变量模型
struct EnvVariable: Identifiable, Codable, Hashable {
    let id: UUID
    var configType: ConfigType      // 替换原 source 字段
    var shellType: ShellType?       // Shell 配置类才有
    var key: String?                // env/shell/launchctl 有，path/alias 无
    var value: String               // 所有类型都有
    var aliasCommand: String?       // alias 类型专用
    var isSensitive: Bool
    var encryptedValue: String?
    var description: String?
    let createdAt: Date

    // 自定义解码键
    enum CodingKeys: String, CodingKey {
        case id, key, value, isSensitive, encryptedValue, description, createdAt
        case configType, shellType, aliasCommand
        // 保留旧字段用于迁移
        case source
    }

    // 自定义解码，处理旧数据迁移
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        // 尝试解码新字段
        if let newConfigType = try container.decodeIfPresent(ConfigType.self, forKey: .configType) {
            configType = newConfigType
            shellType = try container.decodeIfPresent(ShellType.self, forKey: .shellType)
            aliasCommand = try container.decodeIfPresent(String.self, forKey: .aliasCommand)
            key = try container.decodeIfPresent(String.self, forKey: .key)
            value = try container.decode(String.self, forKey: .value)
        } else {
            // 旧数据迁移：从 source 转换
            let oldSource = try container.decodeIfPresent(EnvSource.self, forKey: .source) ?? .shellConfig
            configType = migrateFromSource(oldSource)
            shellType = .zsh  // 默认 zsh
            aliasCommand = nil
            key = try container.decode(String.self, forKey: .key)
            value = try container.decode(String.self, forKey: .value)
        }
        
        isSensitive = try container.decodeIfPresent(Bool.self, forKey: .isSensitive) ?? false
        encryptedValue = try container.decodeIfPresent(String.self, forKey: .encryptedValue)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(configType, forKey: .configType)
        try container.encodeIfPresent(shellType, forKey: .shellType)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encode(value, forKey: .value)
        try container.encodeIfPresent(aliasCommand, forKey: .aliasCommand)
        try container.encode(isSensitive, forKey: .isSensitive)
        try container.encodeIfPresent(encryptedValue, forKey: .encryptedValue)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(createdAt, forKey: .createdAt)
    }

    /// 创建新的环境变量
    init(
        id: UUID = UUID(),
        configType: ConfigType,
        shellType: ShellType? = nil,
        key: String? = nil,
        value: String,
        aliasCommand: String? = nil,
        isSensitive: Bool = false,
        encryptedValue: String? = nil,
        description: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.configType = configType
        self.shellType = shellType
        self.key = key
        self.value = value
        self.aliasCommand = aliasCommand
        self.isSensitive = isSensitive
        self.encryptedValue = encryptedValue
        self.description = description
        self.createdAt = createdAt
    }

    /// 从旧 EnvSource 迁移
    private static func migrateFromSource(_ source: EnvSource) -> ConfigType {
        switch source {
        case .manual, .shellConfig:
            return .envVariable
        case .launchctl:
            return .launchctl
        case .application:
            return .envVariable
        }
    }

    /// 生成实际配置语句
    func generateConfigStatement() -> String {
        switch configType {
        case .envVariable:
            return "export \(key ?? "")=\"\(value)\""
        case .shellConfig:
            return "\(key ?? "")=\"\(value)\""
        case .path:
            return "export PATH=\"$PATH:\(value)\""
        case .alias:
            return "alias \(value)='\(aliasCommand ?? "")'"
        case .launchctl:
            return "launchctl setenv \(key ?? "") \(value)"
        }
    }

    /// 获取显示值（敏感信息显示为星号）
    var displayValue: String {
        if isSensitive {
            return "********"
        }
        return value
    }

    /// 获取显示标题（用于列表显示）
    var displayTitle: String {
        switch configType {
        case .envVariable, .shellConfig, .launchctl:
            return key ?? ""
        case .path:
            return "PATH"
        case .alias:
            return value
        }
    }

    /// 获取显示副标题
    var displaySubtitle: String {
        switch configType {
        case .envVariable, .shellConfig, .launchctl:
            return value
        case .path:
            return value
        case .alias:
            return aliasCommand ?? ""
        }
    }

    /// 用于哈希和相等比较的关键字段
    static func == (lhs: EnvVariable, rhs: EnvVariable) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 4: 创建 ConfigTypePicker 组件

**Files:**
- Create: `EnvManager/Views/Components/ConfigTypePicker.swift`

- [ ] **Step 1: 创建 ConfigTypePicker.swift**

```swift
import SwiftUI

/// 配置类型选择器组件
struct ConfigTypePicker: View {
    @Binding var selectedType: ConfigType

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("配置类型")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Menu {
                // Shell 配置组
                Menu("Shell 配置") {
                    ForEach([ConfigType.envVariable, .shellConfig, .path, .alias], id: \.self) { type in
                        Button(action: { selectedType = type }) {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 系统配置组
                Menu("系统配置") {
                    Button(action: { selectedType = .launchctl }) {
                        HStack {
                            Image(systemName: ConfigType.launchctl.icon)
                            Text(ConfigType.launchctl.displayName)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedType.icon)
                        .foregroundColor(.accentColor)
                    Text(selectedType.displayName)
                        .font(.system(size: 13))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }
            .menuStyle(.borderedButton)
        }
    }
}

#Preview {
    ConfigTypePicker(selectedType: .constant(.envVariable))
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 5: 创建 ShellTypePicker 组件

**Files:**
- Create: `EnvManager/Views/Components/ShellTypePicker.swift`

- [ ] **Step 1: 创建 ShellTypePicker.swift**

```swift
import SwiftUI

/// Shell 类型选择器组件
struct ShellTypePicker: View {
    @Binding var selectedShell: ShellType

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("目标 Shell")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(ShellType.allCases, id: \.self) { shell in
                    Button(action: { selectedShell = shell }) {
                        VStack(spacing: 4) {
                            Text(shell.displayName)
                                .font(.system(size: 13, weight: selectedShell == shell ? .medium : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedShell == shell ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedShell == shell ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    ShellTypePicker(selectedShell: .constant(.zsh))
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 6: 创建 DynamicConfigForm 组件

**Files:**
- Create: `EnvManager/Views/Components/DynamicConfigForm.swift`

- [ ] **Step 1: 创建 DynamicConfigForm.swift**

```swift
import SwiftUI

/// 动态配置表单组件 - 根据配置类型显示不同字段
struct DynamicConfigForm: View {
    @Binding var configType: ConfigType
    @Binding var shellType: ShellType
    @Binding var key: String
    @Binding var value: String
    @Binding var aliasCommand: String
    @Binding var description: String
    @Binding var isSensitive: Bool

    @State private var keyError: String?
    @State private var valueError: String?
    @State private var aliasCommandError: String?

    var isValid: Bool {
        switch configType {
        case .envVariable, .shellConfig, .launchctl:
            return !key.isEmpty && !value.isEmpty && keyError == nil && valueError == nil
        case .path:
            return !value.isEmpty && valueError == nil
        case .alias:
            return !value.isEmpty && !aliasCommand.isEmpty && valueError == nil && aliasCommandError == nil
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 根据配置类型显示不同字段
            switch configType {
            case .envVariable, .shellConfig, .launchctl:
                // 变量名
                FormField(
                    label: configType == .launchctl ? "变量名" : "变量名",
                    placeholder: "例如: JAVA_HOME",
                    binding: $key,
                    error: keyError,
                    onChange: validateKey
                )
                
                // 变量值
                FormField(
                    label: "变量值",
                    placeholder: configType == .launchctl ? "例如: /usr/lib/jvm/java-17" : "例如: /usr/lib/jvm/java-17",
                    binding: $value,
                    error: valueError,
                    isSecure: isSensitive,
                    onChange: validateValue
                )

            case .path:
                // PATH 路径
                FormField(
                    label: "路径",
                    placeholder: "例如: /usr/local/bin",
                    binding: $value,
                    error: valueError,
                    onChange: validatePath
                )
                Text("将添加到 PATH 环境变量")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

            case .alias:
                // 别名名
                FormField(
                    label: "别名",
                    placeholder: "例如: ll",
                    binding: $value,
                    error: valueError,
                    onChange: validateAliasName
                )
                
                // 命令
                FormField(
                    label: "命令",
                    placeholder: "例如: ls -la",
                    binding: $aliasCommand,
                    error: aliasCommandError,
                    onChange: validateAliasCommand
                )
            }

            // Shell 选择器（仅 Shell 配置类显示）
            if configType.isShellConfig {
                ShellTypePicker(selectedShell: $shellType)
            }

            // 描述（所有类型都有）
            FormField(
                label: "描述（可选）",
                placeholder: "用途说明",
                binding: $description,
                error: nil
            )

            // 敏感标记（仅环境变量和 launchctl 显示）
            if configType == .envVariable || configType == .launchctl {
                Toggle(isOn: $isSensitive) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("标记为敏感信息")
                    }
                }
                .toggleStyle(.checkbox)
            }
        }
    }

    // 验证函数
    private func validateKey(_ newKey: String) {
        if newKey.isEmpty {
            keyError = nil
        } else if newKey.contains(" ") || newKey.contains("=") {
            keyError = "变量名不能包含空格或等号"
        } else if newKey.hasPrefix("$") {
            keyError = "变量名不能以 $ 开头"
        } else {
            keyError = nil
        }
    }

    private func validateValue(_ newValue: String) {
        valueError = newValue.isEmpty ? "变量值不能为空" : nil
    }

    private func validatePath(_ newPath: String) {
        if newPath.isEmpty {
            valueError = "路径不能为空"
        } else if !newPath.hasPrefix("/") {
            valueError = "路径应以 / 开头"
        } else {
            valueError = nil
        }
    }

    private func validateAliasName(_ newName: String) {
        valueError = newName.isEmpty ? "别名不能为空" : nil
    }

    private func validateAliasCommand(_ newCommand: String) {
        aliasCommandError = newCommand.isEmpty ? "命令不能为空" : nil
    }
}

/// 表单字段组件
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var binding: String
    var error: String?
    var isSecure: Bool = false
    var onChange: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            if isSecure {
                SecureField(placeholder, text: $binding)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: binding) { _, newValue in
                        onChange?(newValue)
                    }
            } else {
                TextField(placeholder, text: $binding)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: binding) { _, newValue in
                        onChange?(newValue)
                    }
            }

            if let error = error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    DynamicConfigForm(
        configType: .constant(.envVariable),
        shellType: .constant(.zsh),
        key: .constant(""),
        value: .constant(""),
        aliasCommand: .constant(""),
        description: .constant(""),
        isSensitive: .constant(false)
    )
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 7: 修改 AddVariableSheet

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift:405-551`

- [ ] **Step 1: 替换 AddVariableSheet 使用新组件**

找到 AddVariableSheet（约第 405 行），替换为新版本：

```swift
/// 添加变量弹窗
struct AddVariableSheet: View {
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var configType: ConfigType = .envVariable
    @State private var shellType: ShellType = .zsh
    @State private var key = ""
    @State private var value = ""
    @State private var aliasCommand = ""
    @State private var description = ""
    @State private var isSensitive = false

    let onSave: (EnvVariable) -> Void

    var isValid: Bool {
        switch configType {
        case .envVariable, .shellConfig, .launchctl:
            return !key.isEmpty && !value.isEmpty
        case .path:
            return !value.isEmpty
        case .alias:
            return !value.isEmpty && !aliasCommand.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text("添加配置")
                .font(.system(size: 18, weight: .semibold))

            // 配置类型选择器
            ConfigTypePicker(selectedType: $configType)
                .onChange(of: configType) { _, newType in
                    // 切换类型时清空相关字段
                    if newType == .path {
                        key = ""
                    }
                    if newType != .alias {
                        aliasCommand = ""
                    }
                }

            // 动态表单
            DynamicConfigForm(
                configType: $configType,
                shellType: $shellType,
                key: $key,
                value: $value,
                aliasCommand: $aliasCommand,
                description: $description,
                isSensitive: $isSensitive
            )

            Divider()

            // 按钮
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("保存") {
                    if isValid {
                        let variable = EnvVariable(
                            configType: configType,
                            shellType: configType.isShellConfig ? shellType : nil,
                            key: configType == .path || configType == .alias ? nil : key,
                            value: value,
                            aliasCommand: configType == .alias ? aliasCommand : nil,
                            isSensitive: isSensitive,
                            description: description.isEmpty ? nil : description
                        )
                        onSave(variable)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 8: 修改 EditVariableSheet

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift:554-720`

- [ ] **Step 1: 替换 EditVariableSheet 使用新组件**

找到 EditVariableSheet（约第 554 行），替换为新版本：

```swift
/// 编辑变量弹窗
struct EditVariableSheet: View {
    let variable: EnvVariable
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var configType: ConfigType
    @State private var shellType: ShellType
    @State private var key: String
    @State private var value: String
    @State private var aliasCommand: String
    @State private var description: String
    @State private var isSensitive: Bool

    let onSave: (EnvVariable) -> Void

    init(variable: EnvVariable, groupId: UUID, onSave: @escaping (EnvVariable) -> Void) {
        self.variable = variable
        self.groupId = groupId
        self.onSave = onSave

        // 初始化表单值
        _configType = State(initialValue: variable.configType)
        _shellType = State(initialValue: variable.shellType ?? .zsh)
        _key = State(initialValue: variable.key ?? "")
        _value = State(initialValue: variable.value)
        _aliasCommand = State(initialValue: variable.aliasCommand ?? "")
        _description = State(initialValue: variable.description ?? "")
        _isSensitive = State(initialValue: variable.isSensitive)
    }

    var isValid: Bool {
        switch configType {
        case .envVariable, .shellConfig, .launchctl:
            return !key.isEmpty && !value.isEmpty
        case .path:
            return !value.isEmpty
        case .alias:
            return !value.isEmpty && !aliasCommand.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text("编辑配置")
                .font(.system(size: 18, weight: .semibold))

            // 配置类型选择器
            ConfigTypePicker(selectedType: $configType)
                .onChange(of: configType) { _, newType in
                    // 切换类型时调整字段
                    if newType == .path {
                        key = ""
                    }
                    if newType != .alias {
                        aliasCommand = ""
                    }
                }

            // 动态表单
            DynamicConfigForm(
                configType: $configType,
                shellType: $shellType,
                key: $key,
                value: $value,
                aliasCommand: $aliasCommand,
                description: $description,
                isSensitive: $isSensitive
            )

            Divider()

            // 按钮
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("保存") {
                    if isValid {
                        let updatedVariable = EnvVariable(
                            id: variable.id,
                            configType: configType,
                            shellType: configType.isShellConfig ? shellType : nil,
                            key: configType == .path || configType == .alias ? nil : key,
                            value: value,
                            aliasCommand: configType == .alias ? aliasCommand : nil,
                            isSensitive: isSensitive,
                            description: description.isEmpty ? nil : description,
                            createdAt: variable.createdAt
                        )
                        onSave(updatedVariable)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 9: 修改 VariableListRow 显示

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift:807-861`

- [ ] **Step 1: 更新 VariableListRow 显示逻辑**

找到 VariableListRow（约第 807 行），替换为新版本以支持新配置类型的显示：

```swift
/// 变量列表行
struct VariableListRow: View {
    let variable: EnvVariable
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 配置类型图标
            Image(systemName: variable.configType.icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            // 主标题和描述
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(variable.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    if variable.isSensitive {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }

                    // Shell 类型标签（仅 Shell 配置显示）
                    if let shell = variable.shellType {
                        Text(shell.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(3)
                    }
                }

                if let desc = variable.description {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 副标题（值）
            Text(variable.displaySubtitle)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)

            // 操作按钮
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 10: 更新 MainViewModel 和调用签名

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift` (调用 AddVariableSheet 的地方)
- Modify: `EnvManager/ViewModels/MainViewModel.swift`（如果存在）

- [ ] **Step 1: 查找并修改 AddVariableSheet 调用**

在 MainWindowView.swift 中找到调用 AddVariableSheet 的地方（约第 371-387 行），修改 onSave 参数：

```swift
.sheet(isPresented: $showAddForm) {
    AddVariableSheet(
        groupId: group.id,
        onSave: { variable in
            Task {
                await viewModel.addVariable(variable, to: group.id)
                showAddForm = false
            }
        }
    )
}
```

- [ ] **Step 2: 修改 EditVariableSheet 调用**

找到调用 EditVariableSheet 的地方（约第 389-399 行），修改 onSave 参数：

```swift
.sheet(item: $editingVariable) { variable in
    EditVariableSheet(
        variable: variable,
        groupId: group.id,
        onSave: { updatedVariable in
            Task {
                viewModel.selectedGroupId = group.id
                await viewModel.updateVariable(updatedVariable)
                editingVariable = nil
            }
        }
    )
}
```

- [ ] **Step 3: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 11: 更新 MainViewModel 的方法签名

**Files:**
- Modify: `EnvManager/ViewModels/MainViewModel.swift`（如果存在，否则修改 EnvService）

- [ ] **Step 1: 查找 MainViewModel 文件**

Run: `find /Volumes/MyExt/workspace/mac/env-manager/EnvManager -name "MainViewModel.swift"`
Expected: 找到文件路径

- [ ] **Step 2: 修改 addVariable 方法签名**

将原来的多个参数改为单个 EnvVariable 参数：

```swift
func addVariable(_ variable: EnvVariable, to groupId: UUID) async {
    do {
        try await envService.addVariable(variable, to: groupId)
    } catch {
        errorMessage = "添加变量失败: \(error.localizedDescription)"
    }
}
```

- [ ] **Step 3: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 12: 更新 ShellService 写入逻辑

**Files:**
- Modify: `EnvManager/Services/ShellService.swift`

- [ ] **Step 1: 修改 ShellService 支持多种配置类型**

修改 `generateEnvBlock` 方法，根据 configType 生成不同的语句：

```swift
/// 生成环境变量块
private func generateEnvBlock(_ group: EnvGroup) -> String {
    var block = ""
    block += Constants.envMarkerBegin + "\n"
    block += Constants.envMarkerGroupBegin + group.name + "\n"

    for variable in group.variables {
        let line = variable.generateConfigStatement()
        block += line + "\n"
    }

    block += Constants.envMarkerEnd + "\n"
    return block
}
```

- [ ] **Step 2: 修改 writeEnvVariables 支持多 Shell 文件**

```swift
/// 写入环境变量到 Shell 配置文件
func writeEnvVariables(_ group: EnvGroup) throws {
    os_log("🔄 writeEnvVariables 开始", log: log, type: .info)
    
    // 按变量配置的 shellType 写入不同文件
    // 先写入 zsh 文件
    let zshVariables = group.variables.filter { v in
        v.configType.isShellConfig && (v.shellType == .zsh || v.shellType == .both)
    }
    if !zshVariables.isEmpty {
        let zshGroup = EnvGroup(id: group.id, name: group.name, variables: zshVariables)
        try writeToFile(Constants.zshrcPath, group: zshGroup)
    }
    
    // 再写入 bash 文件
    let bashVariables = group.variables.filter { v in
        v.configType.isShellConfig && (v.shellType == .bash || v.shellType == .both)
    }
    if !bashVariables.isEmpty {
        let bashGroup = EnvGroup(id: group.id, name: group.name, variables: bashVariables)
        try writeToFile(Constants.bashrcPath, group: bashGroup)
    }
    
    // 处理 launchctl 变量
    for variable in group.variables where variable.configType == .launchctl {
        try executeLaunchctlSetenv(key: variable.key ?? "", value: variable.value)
    }
}

/// 写入到指定文件
private func writeToFile(_ filePath: String, group: EnvGroup) throws {
    let expandedPath = filePath.replacingOccurrences(of: "~", with: NSHomeDirectory())
    
    let content = try readFileContent(expandedPath)
    let cleanedContent = removeGroupBlock(content, groupName: group.name)
    let newBlock = generateEnvBlock(group)
    let newContent = cleanedContent + newBlock
    
    try writeFileContent(expandedPath, content: newContent)
}

/// 执行 launchctl setenv
private func executeLaunchctlSetenv(key: String, value: String) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/launchctl")
    process.arguments = ["setenv", key, value]
    try process.run()
    process.waitUntilExit()
}

/// 读取指定文件内容
private func readFileContent(_ path: String) throws -> String {
    if !FileManager.default.fileExists(atPath: path) {
        return ""
    }
    return try String(contentsOfFile: path, encoding: .utf8)
}

/// 写入指定文件内容
private func writeFileContent(_ path: String, content: String) throws {
    try content.write(toFile: path, atomically: true, encoding: .utf8)
}
```

- [ ] **Step 3: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 13: 更新 EnvService 的历史记录字段

**Files:**
- Modify: `EnvManager/Services/EnvService.swift`

- [ ] **Step 1: 修改历史记录中的变量键**

在 `addVariable` 和 `updateVariable` 方法中，使用 `variable.displayTitle` 替代 `variable.key`：

```swift
// 在 addVariable 方法中
let record = HistoryRecord(action: .create, variableKey: variable.displayTitle, newValue: variable.displaySubtitle)

// 在 updateVariable 方法中
let record = HistoryRecord(
    action: .update,
    variableKey: variable.displayTitle,
    oldValue: oldVariable?.displaySubtitle,
    newValue: variable.displaySubtitle
)

// 在 deleteVariable 方法中
let record = HistoryRecord(action: .delete, variableKey: variable?.displayTitle ?? "", oldValue: variable?.displaySubtitle)
```

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 14: 删除废弃的 EnvSource.swift

**Files:**
- Delete: `EnvManager/Models/EnvSource.swift`

- [ ] **Step 1: 删除 EnvSource.swift 文件**

Run: `rm /Volumes/MyExt/workspace/mac/env-manager/EnvManager/EnvManager/Models/EnvSource.swift`

- [ ] **Step 2: 构建验证**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && xcodebuild build -scheme EnvManager -configuration Debug 2>&1 | head -50`
Expected: BUILD SUCCEEDED

---

### Task 15: 运行应用并测试

**Files:**
- Test: 手动测试应用功能

- [ ] **Step 1: 运行应用**

Run: `cd /Volumes/MyExt/workspace/mac/env-manager/EnvManager && open build/Debug/EnvManager.app`

- [ ] **Step 2: 测试各配置类型**

测试项：
1. 创建新分组，添加环境变量（选择 zsh）
2. 添加 Shell 配置（选择 bash）
3. 添加 PATH 路径（选择通用）
4. 添加 Alias 别名（选择 zsh）
5. 添加系统级环境变量（launchctl）
6. 编辑配置，切换类型
7. 检查变量列表显示是否正确
8. 检查激活分组后配置文件是否正确写入

---

## Self-Review

**1. Spec Coverage:**
- ✅ ConfigType 枚举定义（Task 1）
- ✅ ShellType 枚举定义（Task 2）
- ✅ EnvVariable 模型修改（Task 3）
- ✅ ConfigTypePicker 组件（Task 4）
- ✅ ShellTypePicker 组件（Task 5）
- ✅ DynamicConfigForm 组件（Task 6）
- ✅ AddVariableSheet 修改（Task 7）
- ✅ EditVariableSheet 修改（Task 8）
- ✅ VariableListRow 显示（Task 9）
- ✅ ShellService 写入逻辑（Task 12）
- ✅ 旧数据迁移（Task 3 解码器处理）

**2. Placeholder Scan:**
- 无 TBD/TODO/待实现

**3. Type Consistency:**
- ConfigType、ShellType、EnvVariable 在所有任务中使用一致的命名
- generateConfigStatement() 方法在各处调用一致