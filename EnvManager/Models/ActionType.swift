import Foundation

/// 操作历史记录的动作类型
enum ActionType: String, Codable, CaseIterable {
    /// 创建新变量
    case create
    /// 更新现有变量
    case update
    /// 删除变量
    case delete
    /// 切换环境组
    case switchGroup = "switch"

    /// 获取动作的显示名称
    var displayName: String {
        switch self {
        case .create:
            return "创建"
        case .update:
            return "更新"
        case .delete:
            return "删除"
        case .switchGroup:
            return "切换"
        }
    }
}