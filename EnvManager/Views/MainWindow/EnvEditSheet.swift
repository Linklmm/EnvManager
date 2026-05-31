import SwiftUI

/// 环境变量编辑弹窗
struct EnvEditSheet: View {
    @ObservedObject var editViewModel: EnvEditViewModel
    @ObservedObject var mainViewModel: MainViewModel

    @Environment(\.dismiss) private var dismiss

    var onSave: () async -> Void

    var body: some View {
        // DEBUG: 添加调试日志
        let _ = print("🟢 [EnvEditSheet] body 开始渲染")
        let _ = print("  - editViewModel.title: \(editViewModel.title)")
        let _ = print("  - editViewModel.key: \(editViewModel.key)")
        let _ = print("  - editViewModel.value: \(editViewModel.value)")

        VStack(spacing: 24) {
            // 标题
            Text(editViewModel.title)
                .font(.system(size: 18, weight: .semibold))

            // 表单
            VStack(spacing: 16) {
                // 变量名
                VStack(alignment: .leading, spacing: 4) {
                    Text("变量名")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("例如: JAVA_HOME", text: $editViewModel.key)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: editViewModel.key) { oldValue, newValue in
                            editViewModel.validateKeyAsync(newValue)
                        }

                    if let error = editViewModel.keyError {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }

                // 变量值
                VStack(alignment: .leading, spacing: 4) {
                    Text("变量值")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    if editViewModel.isSensitive {
                        SecureField("输入敏感值", text: $editViewModel.value)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: editViewModel.value) { oldValue, newValue in
                                editViewModel.validateValueAsync(newValue)
                            }
                    } else {
                        TextField("例如: /usr/lib/jvm/java-17", text: $editViewModel.value)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: editViewModel.value) { oldValue, newValue in
                                editViewModel.validateValueAsync(newValue)
                            }
                    }

                    if let error = editViewModel.valueError {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }

                // 配置类型
                VStack(alignment: .leading, spacing: 4) {
                    Text("配置类型")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Picker("配置类型", selection: $editViewModel.configType) {
                        ForEach(editViewModel.configTypeOptions, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Shell 类型（仅当配置类型为 shellConfig 时显示）
                if editViewModel.configType.isShellConfig {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shell 类型")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        ShellTypePicker(selectedShell: $editViewModel.shellType)
                    }
                }

                // 描述
                VStack(alignment: .leading, spacing: 4) {
                    Text("描述（可选）")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("变量用途说明", text: $editViewModel.description)
                        .textFieldStyle(.roundedBorder)
                }

                // 敏感标记
                Toggle(isOn: $editViewModel.isSensitive) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("标记为敏感信息")
                    }
                }
                .toggleStyle(.checkbox)
            }

            Divider()

            // 按钮
            HStack(spacing: 12) {
                Button("取消") {
                    editViewModel.reset()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button(editViewModel.saveButtonTitle) {
                    if editViewModel.canSave() {
                        Task {
                            await onSave()
                            editViewModel.reset()
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!editViewModel.isValid)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

#Preview {
    EnvEditSheet(
        editViewModel: EnvEditViewModel(),
        mainViewModel: MainViewModel(envService: EnvService()),
        onSave: {}
    )
}