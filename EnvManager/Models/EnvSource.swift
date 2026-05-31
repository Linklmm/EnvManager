import Foundation

/// 环境变量的来源类型
enum EnvSource: String, Codable, CaseIterable {
    /// 手动添加
    case manual
    /// Shell 配置文件 (.zshrc, .bashrc 等)
    case shellConfig
    /// 系统级环境变量 (launchctl)
    case launchctl
    /// 特定应用环境变量
    case application

    /// 获取来源的显示名称
    var displayName: String {
        switch self {
        case .manual:
            return "手动添加"
        case .shellConfig:
            return "Shell 配置"
        case .launchctl:
            return "系统级"
        case .application:
            return "应用级"
        }
    }

    /// 获取来源的图标
    var icon: String {
        switch self {
        case .manual:
            return "pencil"
        case .shellConfig:
            return "terminal"
        case .launchctl:
            return "gear"
        case .application:
            return "app"
        }
    }

    /// 获取来源的 emoji 图标
    var iconEmoji: String {
        switch self {
        case .manual:
            return "✏️"
        case .shellConfig:
            return "🖥️"
        case .launchctl:
            return "⚙️"
        case .application:
            return "📱"
        }
    }
}