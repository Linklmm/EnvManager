import SwiftUI
import Combine
import EnvManagerCore

/// 变量编辑 ViewModel
@MainActor
class EnvEditViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var key: String = ""
    @Published var value: String = ""
    @Published var configType: ConfigType = .envVariable
    @Published var shellType: ShellType = .zsh
    @Published var aliasCommand: String = ""
    @Published var description: String = ""
    @Published var isSensitive: Bool = false

    @Published var keyError: String?
    @Published var valueError: String?

    // 用于 isValid 检查的内部状态（不触发验证）
    @Published var isKeyValid: Bool = false
    @Published var isValueValid: Bool = false

    // 编辑模式
    @Published var isEditMode: Bool = false
    @Published var originalVariable: EnvVariable?

    // MARK: - Computed Properties
    var isValid: Bool {
        // 只检查状态，不触发验证
        isKeyValid && isValueValid
    }

    var configTypeOptions: [ConfigType] {
        ConfigType.allCases
    }

    var title: String {
        isEditMode ? "编辑变量" : "添加变量"
    }

    var saveButtonTitle: String {
        isEditMode ? "保存" : "添加"
    }

    // MARK: - Validation (使用 DispatchQueue.main.async 确保脱离视图更新周期)

    /// 异步验证变量名
    func validateKeyAsync(_ key: String) {
        // 使用 DispatchQueue.main.async 确保在下一个 runloop cycle 执行
        DispatchQueue.main.async {
            let result = self.checkKeyValidation(key)
            self.keyError = result.error
            self.isKeyValid = result.isValid
        }
    }

    /// 异步验证变量值
    func validateValueAsync(_ value: String) {
        // 使用 DispatchQueue.main.async 确保在下一个 runloop cycle 执行
        DispatchQueue.main.async {
            let result = self.checkValueValidation(value)
            self.valueError = result.error
            self.isValueValid = result.isValid
        }
    }

    /// 同步检查变量名验证（不修改 @Published）
    private func checkKeyValidation(_ key: String) -> (isValid: Bool, error: String?) {
        if key.isEmpty {
            return (false, "变量名不能为空")
        }
        if key.first?.isNumber ?? false {
            return (false, "变量名不能以数字开头")
        }
        if key.contains(" ") {
            return (false, "变量名不能包含空格")
        }
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if !key.unicodeScalars.allSatisfy({ validCharacters.contains($0) }) {
            return (false, "变量名只能包含字母、数字和下划线")
        }
        return (true, nil)
    }

    /// 同步检查变量值验证（不修改 @Published）
    private func checkValueValidation(_ value: String) -> (isValid: Bool, error: String?) {
        if value.isEmpty {
            return (false, "变量值不能为空")
        }
        return (true, nil)
    }

    // MARK: - Actions

    /// 创建新变量
    func createVariable() -> EnvVariable {
        return EnvVariable(
            key: configType == .path || configType == .alias ? nil : key.trimmingCharacters(in: .whitespaces),
            value: value.trimmingCharacters(in: .whitespaces),
            configType: configType,
            shellType: configType.isShellConfig ? shellType : nil,
            isSensitive: isSensitive,
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            aliasCommand: configType == .alias ? aliasCommand : nil
        )
    }

    /// 设置编辑变量
    func setEditingVariable(_ variable: EnvVariable) {
        isEditMode = true
        originalVariable = variable

        configType = variable.configType
        shellType = variable.shellType ?? .zsh
        key = variable.key ?? ""
        value = variable.value
        aliasCommand = variable.aliasCommand ?? ""
        isSensitive = variable.isSensitive
        description = variable.description ?? ""

        // 编辑模式下预设验证状态
        isKeyValid = true
        isValueValid = true
        keyError = nil
        valueError = nil
    }

    /// 重置表单
    func reset() {
        isEditMode = false
        originalVariable = nil

        key = ""
        value = ""
        configType = .envVariable
        shellType = .zsh
        aliasCommand = ""
        isSensitive = false
        description = ""

        keyError = nil
        valueError = nil
        isKeyValid = false
        isValueValid = false
    }

    /// 验证并返回是否可以保存
    func canSave() -> Bool {
        let keyResult = checkKeyValidation(key)
        let valueResult = checkValueValidation(value)
        keyError = keyResult.error
        isKeyValid = keyResult.isValid
        valueError = valueResult.error
        isValueValid = valueResult.isValid
        return isValid
    }
}