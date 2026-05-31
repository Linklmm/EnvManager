import Foundation

/// 配置类型枚举
enum ConfigType: String, Codable, CaseIterable {
    /// 环境变量 - export KEY=value
    case envVariable
    /// Shell 配置 - KEY="value" (非 export)
    case shellConfig
    /// PATH 路径 - export PATH=$PATH:/path
    case path
    /// Alias 别名 - alias name='command'
    case alias
    /// 系统级环境变量 - launchctl setenv KEY value
    case launchctl

    /// 是否为 Shell 配置类（需要选择 Shell）
    var isShellConfig: Bool {
        switch self {
        case .envVariable, .shellConfig, .path, .alias:
            return true
        case .launchctl:
            return false
        }
    }

    /// 显示名称
    var displayName: String {
        switch self {
        case .envVariable: return "环境变量"
        case .shellConfig: return "Shell 配置"
        case .path: return "PATH 路径"
        case .alias: return "Alias 别名"
        case .launchctl: return "系统级环境变量"
        }
    }

    /// 分组名称
    var groupName: String {
        return isShellConfig ? "Shell 配置" : "系统配置"
    }

    /// 图标
    var icon: String {
        switch self {
        case .envVariable: return "chevron.left.forwardslash.chevron.right"
        case .shellConfig: return "terminal"
        case .path: return "folder"
        case .alias: return "arrow.right"
        case .launchctl: return "gear"
        }
    }
}
