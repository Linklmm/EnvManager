import Foundation

/// CLI 专用环境服务 - actor 而非 @MainActor
public actor CLIEnvService {
    private let storageService: StorageService
    private let shellService: ShellService
    private let launchctlService: LaunchctlService

    /// 初始化 CLI 服务
    public init(
        storageService: StorageService,
        shellService: ShellService,
        launchctlService: LaunchctlService
    ) {
        self.storageService = storageService
        self.shellService = shellService
        self.launchctlService = launchctlService
    }

    /// 便捷初始化 - 创建默认服务实例
    public static func createDefault() -> CLIEnvService {
        return CLIEnvService(
            storageService: StorageService(),
            shellService: ShellService(),
            launchctlService: LaunchctlService()
        )
    }

    /// 加载配置
    public func loadConfig() async throws -> EnvConfig {
        return try await storageService.loadConfig()
    }

    /// 保存配置
    public func saveConfig(_ config: EnvConfig) async throws {
        try await storageService.saveConfig(config)
    }

    /// 列出所有分组
    public func listGroups() async throws -> [EnvGroup] {
        let config = try await storageService.loadConfig()
        return config.groups
    }

    /// 获取激活的分组
    public func getActiveGroup() async throws -> EnvGroup? {
        let config = try await storageService.loadConfig()
        return config.activeGroup
    }

    /// 根据名称查找分组
    public func findGroupByName(name: String) async throws -> EnvGroup? {
        let config = try await storageService.loadConfig()
        return config.groups.first { $0.name == name }
    }

    /// 切换激活分组
    public func switchGroup(name: String) async throws -> Bool {
        var config = try await storageService.loadConfig()

        // 查找目标分组
        guard let targetGroup = config.groups.first(where: { $0.name == name }) else {
            return false
        }

        // 如果已有激活分组，先取消激活
        if let oldActiveId = config.activeGroupId,
           let oldGroup = config.groups.first(where: { $0.id == oldActiveId }) {
            // 移除 shell 配置
            try await shellService.removeEnvVariables(groupName: oldGroup.name)

            // 移除 launchctl 变量
            for variable in oldGroup.variables where variable.configType == .launchctl {
                try await launchctlService.unsetEnv(key: variable.key ?? "")
            }
        }

        // 激活新分组
        config.activeGroupId = targetGroup.id

        // 写入 shell 变量（排除 launchctl）
        let shellVariables = targetGroup.variables.filter { $0.configType != .launchctl }
        if !shellVariables.isEmpty {
            let shellGroup = EnvGroup(
                name: targetGroup.name,
                icon: targetGroup.icon,
                color: targetGroup.color,
                variables: shellVariables
            )
            try await shellService.writeEnvVariables(shellGroup)
        }

        // 设置 launchctl 变量
        for variable in targetGroup.variables where variable.configType == .launchctl {
            try await launchctlService.setEnv(key: variable.key ?? "", value: variable.value)
        }

        // 更新 isActive 标记
        for i in config.groups.indices {
            config.groups[i].isActive = config.groups[i].id == targetGroup.id
        }

        // 保存配置
        try await storageService.saveConfig(config)

        return true
    }

    /// 取消激活当前分组
    public func deactivateCurrentGroup() async throws {
        var config = try await storageService.loadConfig()

        guard let activeId = config.activeGroupId,
              let activeGroup = config.groups.first(where: { $0.id == activeId }) else {
            return // 没有激活的分组
        }

        // 移除 shell 配置
        try await shellService.removeEnvVariables(groupName: activeGroup.name)

        // 移除 launchctl 变量
        for variable in activeGroup.variables where variable.configType == .launchctl {
            try await launchctlService.unsetEnv(key: variable.key ?? "")
        }

        // 清除激活状态
        config.activeGroupId = nil
        for i in config.groups.indices {
            config.groups[i].isActive = false
        }

        // 保存配置
        try await storageService.saveConfig(config)
    }
}