import Foundation

/// 操作历史记录
public struct HistoryRecord: Identifiable, Codable {
    public let id: UUID
    public var action: ActionType
    public var variableKey: String
    public var oldValue: String?
    public var newValue: String?
    public let timestamp: Date

    /// 创建历史记录
    public init(
        id: UUID = UUID(),
        action: ActionType,
        variableKey: String,
        oldValue: String? = nil,
        newValue: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.action = action
        self.variableKey = variableKey
        self.oldValue = oldValue
        self.newValue = newValue
        self.timestamp = timestamp
    }

    /// 获取记录描述
    public var description: String {
        let actionName = action.displayName
        switch action {
        case .create:
            return "\(actionName) \(variableKey) = \(newValue ?? "")"
        case .update:
            return "\(actionName) \(variableKey): \(oldValue ?? "") → \(newValue ?? "")"
        case .delete:
            return "\(actionName) \(variableKey) (\(oldValue ?? ""))"
        case .switchGroup:
            return "\(actionName) 环境: \(variableKey) → \(newValue ?? "")"
        }
    }

    /// 是否可以回滚此操作
    public var canRollback: Bool {
        switch action {
        case .create:
            return true  // 可以删除
        case .update:
            return true  // 可以恢复旧值
        case .delete:
            return true  // 可以重新创建
        case .switchGroup:
            return true  // 可以切换回去
        }
    }

    /// 创建回滚记录
    public func createRollback() -> HistoryRecord {
        switch action {
        case .create:
            return HistoryRecord(
                action: .delete,
                variableKey: variableKey,
                oldValue: newValue
            )
        case .update:
            return HistoryRecord(
                action: .update,
                variableKey: variableKey,
                oldValue: newValue,
                newValue: oldValue
            )
        case .delete:
            return HistoryRecord(
                action: .create,
                variableKey: variableKey,
                newValue: oldValue
            )
        case .switchGroup:
            return HistoryRecord(
                action: .switchGroup,
                variableKey: newValue ?? "",
                newValue: variableKey
            )
        }
    }
}