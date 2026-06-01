import Foundation

/// 环境变量分组模型
public struct EnvGroup: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var icon: String?
    public var color: String
    public var variables: [EnvVariable]
    public var isActive: Bool
    public let createdAt: Date
    public var updatedAt: Date

    // 自定义解码键，处理旧版本数据
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, variables, isActive, createdAt, updatedAt
    }

    // 自定义解码，为缺失字段提供默认值
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#667eea"
        variables = try container.decodeIfPresent([EnvVariable].self, forKey: .variables) ?? []
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    // 标准编码
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encode(color, forKey: .color)
        try container.encode(variables, forKey: .variables)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    /// 创建新的环境变量分组
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String? = nil,
        color: String = "#667eea",
        variables: [EnvVariable] = [],
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.variables = variables
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 获取变量数量
    public var variableCount: Int {
        variables.count
    }

    /// 添加变量
    public mutating func addVariable(_ variable: EnvVariable) {
        variables.append(variable)
        updateTimestamp()
    }

    /// 移除变量
    public mutating func removeVariable(id: UUID) {
        variables.removeAll { $0.id == id }
        updateTimestamp()
    }

    /// 更新变量
    public mutating func updateVariable(id: UUID, with newVariable: EnvVariable) {
        if let index = variables.firstIndex(where: { $0.id == id }) {
            variables[index] = newVariable
            updateTimestamp()
        }
    }

    /// 更新时间戳
    public mutating func updateTimestamp() {
        updatedAt = Date()
    }

    /// 查找变量
    public func findVariable(id: UUID) -> EnvVariable? {
        variables.first { $0.id == id }
    }

    /// 查找变量 by key
    public func findVariable(key: String) -> EnvVariable? {
        variables.first { $0.key == key }
    }

    /// 用于哈希和相等比较
    public static func == (lhs: EnvGroup, rhs: EnvGroup) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}