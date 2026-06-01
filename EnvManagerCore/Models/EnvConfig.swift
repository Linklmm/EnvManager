import Foundation

/// 环境配置结构
public struct EnvConfig: Codable {
    public var groups: [EnvGroup]
    public var activeGroupId: UUID?
    public var version: String

    public init(groups: [EnvGroup] = [], activeGroupId: UUID? = nil) {
        self.groups = groups
        self.activeGroupId = activeGroupId
        self.version = "1.0"
    }

    /// 获取激活的分组
    public var activeGroup: EnvGroup? {
        guard let id = activeGroupId else { return nil }
        return groups.first { $0.id == id }
    }
}