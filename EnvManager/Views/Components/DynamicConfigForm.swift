import SwiftUI
import EnvManagerCore

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
        @unknown default:
            return false
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 根据配置类型显示不同字段
            switch configType {
            case .envVariable, .shellConfig, .launchctl:
                FormField(label: "变量名", placeholder: "例如: JAVA_HOME", binding: $key, error: keyError, onChange: validateKey)
                FormField(label: "变量值", placeholder: "例如: /usr/lib/jvm/java-17", binding: $value, error: valueError, isSecure: isSensitive, onChange: validateValue)

            case .path:
                FormField(label: "路径", placeholder: "例如: /usr/local/bin", binding: $value, error: valueError, onChange: validatePath)
                Text("将添加到 PATH 环境变量")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

            case .alias:
                FormField(label: "别名", placeholder: "例如: ll", binding: $value, error: valueError, onChange: validateAliasName)
                FormField(label: "命令", placeholder: "例如: ls -la", binding: $aliasCommand, error: aliasCommandError, onChange: validateAliasCommand)

            @unknown default:
                EmptyView()
            }

            // Shell 选择器（仅 Shell 配置类显示）
            if configType.isShellConfig {
                ShellTypePicker(selectedShell: $shellType)
            }

            // 描述（所有类型都有）
            FormField(label: "描述（可选）", placeholder: "用途说明", binding: $description, error: nil)

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

    private func validateKey(_ newKey: String) {
        if newKey.isEmpty { keyError = nil }
        else if newKey.contains(" ") || newKey.contains("=") { keyError = "变量名不能包含空格或等号" }
        else if newKey.hasPrefix("$") { keyError = "变量名不能以 $ 开头" }
        else { keyError = nil }
    }

    private func validateValue(_ newValue: String) {
        valueError = newValue.isEmpty ? "变量值不能为空" : nil
    }

    private func validatePath(_ newPath: String) {
        if newPath.isEmpty { valueError = "路径不能为空" }
        else if !newPath.hasPrefix("/") { valueError = "路径应以 / 开头" }
        else { valueError = nil }
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
                    .onChange(of: binding) { _, newValue in onChange?(newValue) }
            } else {
                TextField(placeholder, text: $binding)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: binding) { _, newValue in onChange?(newValue) }
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
