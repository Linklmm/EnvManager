import Foundation

/// 环境变量模型
public struct EnvVariable: Identifiable, Codable, Hashable {
    public let id: UUID
    public var key: String?
    public var value: String
    public var configType: ConfigType
    public var shellType: ShellType?
    public var isSensitive: Bool
    public var encryptedValue: String?
    public var description: String?
    public var aliasCommand: String?
    public let createdAt: Date

    // 新编码键
    enum CodingKeys: String, CodingKey {
        case id, key, value, configType, shellType, isSensitive, encryptedValue,
             description, aliasCommand, createdAt
    }

    // 旧数据解码键（用于迁移）
    enum LegacyCodingKeys: String, CodingKey {
        case source
    }

    // 自定义解码，处理新旧两种数据格式
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        key = try container.decodeIfPresent(String.self, forKey: .key)
        value = try container.decode(String.self, forKey: .value)
        isSensitive = try container.decodeIfPresent(Bool.self, forKey: .isSensitive) ?? false
        encryptedValue = try container.decodeIfPresent(String.self, forKey: .encryptedValue)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        aliasCommand = try container.decodeIfPresent(String.self, forKey: .aliasCommand)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()

        // 尝试解码新字段 configType
        if let configType = try container.decodeIfPresent(ConfigType.self, forKey: .configType) {
            self.configType = configType
            shellType = try container.decodeIfPresent(ShellType.self, forKey: .shellType)
        } else {
            // 旧数据迁移：从 EnvSource 转换为 ConfigType
            let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
            let source = try legacyContainer.decodeIfPresent(EnvSource.self, forKey: .source) ?? .shellConfig
            switch source {
            case .manual, .shellConfig, .application:
                configType = .envVariable
            case .launchctl:
                configType = .launchctl
            }
            shellType = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encode(value, forKey: .value)
        try container.encode(configType, forKey: .configType)
        try container.encodeIfPresent(shellType, forKey: .shellType)
        try container.encode(isSensitive, forKey: .isSensitive)
        try container.encodeIfPresent(encryptedValue, forKey: .encryptedValue)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(aliasCommand, forKey: .aliasCommand)
        try container.encode(createdAt, forKey: .createdAt)
    }

    /// 创建新的环境变量
    public init(
        id: UUID = UUID(),
        key: String? = nil,
        value: String,
        configType: ConfigType,
        shellType: ShellType? = nil,
        isSensitive: Bool = false,
        encryptedValue: String? = nil,
        description: String? = nil,
        aliasCommand: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.configType = configType
        self.shellType = shellType
        self.isSensitive = isSensitive
        self.encryptedValue = encryptedValue
        self.description = description
        self.aliasCommand = aliasCommand
        self.createdAt = createdAt
    }

    /// 生成配置语句
    public func generateConfigStatement() -> String {
        switch configType {
        case .envVariable:
            return "export \(key ?? "")=\"\(value)\""
        case .shellConfig:
            return "\(key ?? "")=\"\(value)\""
        case .path:
            return "export PATH=\(value):$PATH"
        case .alias:
            // value = 别名（如 "ll"），aliasCommand = 命令（如 "ls -la"）
            // 生成格式: alias ll='ls -la'
            return "alias \(value)='\(aliasCommand ?? value)'"
        case .launchctl:
            return "launchctl setenv \(key ?? "") \(value)"
        }
    }

    /// 显示标题（用于列表展示）
    public var displayTitle: String {
        switch configType {
        case .envVariable, .shellConfig:
            return key ?? "(无键)"
        case .path:
            return value
        case .alias:
            return key ?? (aliasCommand ?? "alias")
        case .launchctl:
            return key ?? "(无键)"
        }
    }

    /// 显示副标题（用于列表展示）
    public var displaySubtitle: String {
        let typeLabel = configType.displayName
        let shellLabel: String
        if let shellType = shellType {
            shellLabel = " (\(shellType.displayName))"
        } else {
            shellLabel = ""
        }
        return typeLabel + shellLabel
    }

    /// 获取显示值（敏感信息显示为星号）
    public var displayValue: String {
        if isSensitive {
            return "********"
        }
        return value
    }

    /// 获取显示图标
    public var displayIcon: String {
        return configType.icon
    }

    /// 用于哈希和相等比较的关键字段
    public static func == (lhs: EnvVariable, rhs: EnvVariable) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}