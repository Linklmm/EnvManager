import SwiftUI
import Combine
import os.log
import EnvManagerCore

private let log = OSLog(subsystem: "com.envmanager", category: "EnvService")

/// 环境服务错误
enum EnvError: Error, LocalizedError {
    case groupNotFound(UUID)
    case variableNotFound(UUID)
    case saveFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .groupNotFound(let id):
            return "未找到分组 (ID: \(id.uuidString))"
        case .variableNotFound(let id):
            return "未找到变量 (ID: \(id.uuidString))"
        case .saveFailed:
            return "保存配置失败"
        case .loadFailed:
            return "加载配置失败"
        }
    }
}

/// 环境变量主服务 - 协调所有服务
@MainActor
class EnvService: ObservableObject {
    @Published var config: EnvConfig = EnvConfig()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let storageService: StorageService
    private let historyService: HistoryService
    private let shellService: ShellService
    private let cryptoService: CryptoService
    private let templateService: TemplateService

    /// 初始化
    init(
        storageService: StorageService = StorageService(),
        historyService: HistoryService = HistoryService(),
        shellService: ShellService = ShellService(),
        cryptoService: CryptoService = CryptoService(),
        templateService: TemplateService = TemplateService()
    ) {
        self.storageService = storageService
        self.historyService = historyService
        self.shellService = shellService
        self.cryptoService = cryptoService
        self.templateService = templateService

        Task {
            await loadConfig()
        }
    }

    /// 加载配置
    func loadConfig() async {
        isLoading = true
        os_log("🔄 loadConfig 开始", log: log, type: .info)
        do {
            let loadedConfig = try await storageService.loadConfig()
            os_log("✅ loadConfig 成功, groups数量: %{public}d", log: log, type: .info, loadedConfig.groups.count)
            for group in loadedConfig.groups {
                os_log("  - 分组: %{public}s, 变量数: %{public}d", log: log, type: .info, group.name, group.variables.count)
            }
            config = loadedConfig
            os_log("📤 config 已更新", log: log, type: .info)
        } catch {
            os_log("❌ loadConfig 失败: %{public}s", log: log, type: .error, error.localizedDescription)
            errorMessage = "加载配置失败: \(error.localizedDescription)"
            config = EnvConfig()
        }
        isLoading = false
    }

    /// 保存配置
    func saveConfig() async throws {
        try await storageService.saveConfig(config)
    }

    /// 获取所有分组
    func getAllGroups() -> [EnvGroup] {
        return config.groups
    }

    /// 获取指定分组
    func getGroup(id: UUID) -> EnvGroup? {
        return config.groups.first { $0.id == id }
    }

    /// 创建新分组
    func createGroup(name: String, icon: String? = nil, color: String = "#667eea") async throws -> EnvGroup {
        let group = EnvGroup(name: name, icon: icon, color: color)
        config.groups.append(group)

        try await saveConfig()

        do {
            let record = HistoryRecord(action: .create, variableKey: "Group: \(name)")
            try await historyService.addRecord(record)
        } catch {
            // 历史记录失败不影响主流程
            print("添加历史记录失败: \(error)")
        }

        return group
    }

    /// 删除分组
    func deleteGroup(id: UUID) async throws {
        guard let group = getGroup(id: id) else {
            throw EnvError.groupNotFound(id)
        }

        // 保存原始状态
        let originalGroups = config.groups
        let originalActiveGroupId = config.activeGroupId

        config.groups.removeAll { $0.id == id }
        if config.activeGroupId == id {
            config.activeGroupId = nil
        }

        do {
            try await saveConfig()
        } catch {
            // 保存失败，恢复原始状态
            config.groups = originalGroups
            config.activeGroupId = originalActiveGroupId
            print("保存配置失败，已恢复本地状态: \(error)")
            throw error
        }

        // Shell 操作不影响数据一致性，可以继续
        try await shellService.removeEnvVariables(groupName: group.name)

        do {
            let record = HistoryRecord(action: .delete, variableKey: "Group: \(group.name)")
            try await historyService.addRecord(record)
        } catch {
            // 历史记录失败不影响主流程
            print("添加历史记录失败: \(error)")
        }
    }

    /// 更新分组图标
    func updateGroupIcon(_ groupId: UUID, icon: String?) async throws {
        guard let index = config.groups.firstIndex(where: { $0.id == groupId }) else {
            throw EnvError.groupNotFound(groupId)
        }

        // 保存原始状态
        let originalIcon = config.groups[index].icon

        config.groups[index].icon = icon

        do {
            try await saveConfig()
        } catch {
            // 保存失败，恢复原始状态
            config.groups[index].icon = originalIcon
            print("保存配置失败，已恢复本地状态: \(error)")
            throw error
        }
    }

    /// 添加变量到分组
    func addVariable(_ variable: EnvVariable, to groupId: UUID) async throws {
        guard let index = config.groups.firstIndex(where: { $0.id == groupId }) else {
            print("添加变量失败: 未找到分组 \(groupId)")
            throw EnvError.groupNotFound(groupId)
        }

        // 先保存原始状态，以便在保存失败时恢复
        let originalVariables = config.groups[index].variables

        config.groups[index].addVariable(variable)

        do {
            try await saveConfig()
        } catch {
            // 保存失败，恢复原始状态
            config.groups[index].variables = originalVariables
            print("保存配置失败，已恢复本地状态: \(error)")
            throw error
        }

        do {
            let record = HistoryRecord(action: .create, variableKey: variable.key ?? "", newValue: variable.value)
            try await historyService.addRecord(record)
        } catch {
            // 历史记录失败不影响主流程
            print("添加历史记录失败: \(error)")
        }
    }

    /// 更新变量
    func updateVariable(_ variable: EnvVariable, in groupId: UUID) async throws {
        guard let groupIndex = config.groups.firstIndex(where: { $0.id == groupId }) else {
            throw EnvError.groupNotFound(groupId)
        }

        let oldVariable = config.groups[groupIndex].findVariable(id: variable.id)
        guard oldVariable != nil else {
            throw EnvError.variableNotFound(variable.id)
        }

        // 保存原始状态
        let originalVariables = config.groups[groupIndex].variables

        config.groups[groupIndex].updateVariable(id: variable.id, with: variable)

        do {
            try await saveConfig()
        } catch {
            // 保存失败，恢复原始状态
            config.groups[groupIndex].variables = originalVariables
            print("保存配置失败，已恢复本地状态: \(error)")
            throw error
        }

        do {
            let record = HistoryRecord(
                action: .update,
                variableKey: variable.key ?? "",
                oldValue: oldVariable?.value,
                newValue: variable.value
            )
            try await historyService.addRecord(record)
        } catch {
            // 历史记录失败不影响主流程
            print("添加历史记录失败: \(error)")
        }
    }

    /// 删除变量
    func deleteVariable(id: UUID, from groupId: UUID) async throws {
        guard let groupIndex = config.groups.firstIndex(where: { $0.id == groupId }) else {
            throw EnvError.groupNotFound(groupId)
        }

        let variable = config.groups[groupIndex].findVariable(id: id)
        guard variable != nil else {
            throw EnvError.variableNotFound(id)
        }

        // 保存原始状态
        let originalVariables = config.groups[groupIndex].variables

        config.groups[groupIndex].removeVariable(id: id)

        do {
            try await saveConfig()
        } catch {
            // 保存失败，恢复原始状态
            config.groups[groupIndex].variables = originalVariables
            print("保存配置失败，已恢复本地状态: \(error)")
            throw error
        }

        do {
            let record = HistoryRecord(action: .delete, variableKey: variable?.key ?? "", oldValue: variable?.value)
            try await historyService.addRecord(record)
        } catch {
            // 历史记录失败不影响主流程
            print("添加历史记录失败: \(error)")
        }
    }

    /// 切换激活分组
    func switchGroup(to groupId: UUID?) async throws {
        os_log("🔄 switchGroup 开始, 目标groupId: %{public}s", log: log, type: .info, groupId?.uuidString ?? "nil")
        let oldGroupId = config.activeGroupId
        let oldGroup = oldGroupId != nil ? getGroup(id: oldGroupId!) : nil
        os_log("  - 旧分组: %{public}s", log: log, type: .info, oldGroup?.name ?? "无")

        // 禁用旧分组
        if let old = oldGroup {
            os_log("  - 禁用旧分组: %{public}s", log: log, type: .info, old.name)
            for i in config.groups.indices {
                if config.groups[i].id == old.id {
                    config.groups[i].isActive = false
                }
            }
            try await shellService.removeEnvVariables(groupName: old.name)
        }

        // 激活新分组
        if let gid = groupId, let newGroup = getGroup(id: gid) {
            os_log("  - 激活新分组: %{public}s, 变量数: %{public}d", log: log, type: .info, newGroup.name, newGroup.variables.count)
            for i in config.groups.indices {
                if config.groups[i].id == gid {
                    config.groups[i].isActive = true
                }
            }
            os_log("  - 准备调用 shellService.writeEnvVariables...", log: log, type: .info)
            try await shellService.writeEnvVariables(newGroup)
            os_log("  ✅ shellService.writeEnvVariables 完成", log: log, type: .info)
        } else {
            os_log("  ⚠️ 未找到目标分组, gid: %{public}s", log: log, type: .error, groupId?.uuidString ?? "nil")
        }

        /// 设置 activeGroupId 并触发发布
        os_log("  - 设置 activeGroupId: %{public}s", log: log, type: .info, groupId?.uuidString ?? "nil")
        config.activeGroupId = groupId

        // 触发 @Published 发布：必须重新赋值整个 config
        // Swift 的 @Published 只在值被替换时才触发 $config 发布
        // objectWillChange.send() 只触发 SwiftUI 视图更新，不会触发 $config 发布
        os_log("  - 触发发布：重新赋值 config...", log: log, type: .info)
        let tempConfig = config
        config = tempConfig
        os_log("  ✅ config 已重新赋值，$config 将发布更新", log: log, type: .info)

        try await saveConfig()

        do {
            let record = HistoryRecord(
                action: .switchGroup,
                variableKey: oldGroup?.name ?? "",
                newValue: groupId != nil ? getGroup(id: groupId!)?.name ?? "" : ""
            )
            try await historyService.addRecord(record)
        } catch {
            // 历史记录失败不影响主流程
            print("添加历史记录失败: \(error)")
        }
    }

    /// 取消激活当前分组
    func deactivateGroup() async throws {
        os_log("🔄 deactivateGroup 开始", log: log, type: .info)
        guard let activeGroupId = config.activeGroupId else {
            os_log("  ⚠️ 当前没有激活的分组", log: log, type: .info)
            return
        }

        let activeGroup = getGroup(id: activeGroupId)
        guard let group = activeGroup else {
            os_log("  ⚠️ 未找到激活分组, id: %{public}s", log: log, type: .error, activeGroupId.uuidString)
            return
        }

        os_log("  - 取消激活分组: %{public}s", log: log, type: .info, group.name)

        // 更新配置
        config.activeGroupId = nil
        for i in config.groups.indices {
            config.groups[i].isActive = false
        }

        // 触发 @Published 发布：必须重新赋值整个 config
        os_log("  - 触发发布：重新赋值 config...", log: log, type: .info)
        let tempConfig = config
        config = tempConfig
        os_log("  ✅ config 已重新赋值，$config 将发布更新", log: log, type: .info)

        // 移除 shell 配置文件中的环境变量
        try await shellService.removeEnvVariables(groupName: group.name)
        os_log("  ✅ shellService.removeEnvVariables 完成", log: log, type: .info)

        try await saveConfig()

        do {
            let record = HistoryRecord(
                action: .switchGroup,
                variableKey: group.name,
                newValue: ""
            )
            try await historyService.addRecord(record)
        } catch {
            // 历史记录失败不影响主流程
            print("添加历史记录失败: \(error)")
        }

        os_log("✅ deactivateGroup 完成", log: log, type: .info)
    }

    /// 获取激活分组
    func getActiveGroup() -> EnvGroup? {
        return config.activeGroup
    }

    /// 获取内置模板
    func getTemplates() async -> [Template] {
        return await templateService.getBuiltInTemplates()
    }

    /// 应用模板创建分组
    func applyTemplate(_ template: Template, name: String) async throws {
        let group = await templateService.applyTemplate(template, name: name)
        config.groups.append(group)
        try await saveConfig()
    }

    /// 加密敏感变量
    func encryptVariable(_ variable: EnvVariable) async throws -> EnvVariable {
        let encryptedValue = try await cryptoService.encrypt(variable.value)
        return EnvVariable(
            id: variable.id,
            key: variable.key,
            value: variable.value,
            configType: variable.configType,
            shellType: variable.shellType,
            isSensitive: true,
            encryptedValue: encryptedValue,
            description: variable.description,
            aliasCommand: variable.aliasCommand
        )
    }

    /// 解密敏感变量
    func decryptVariable(_ variable: EnvVariable) async throws -> String {
        guard let encrypted = variable.encryptedValue else {
            return variable.value
        }
        return try await cryptoService.decrypt(encrypted)
    }

    /// 获取历史记录
    func getHistory() async throws -> [HistoryRecord] {
        return try await historyService.getRecentRecords()
    }

    /// 导出配置
    func exportConfig(to url: URL) async throws {
        try await storageService.exportConfig(to: url)
    }

    /// 导入配置
    func importConfig(from url: URL) async throws {
        let imported = try await storageService.importConfig(from: url)
        config = imported
    }

    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }
}