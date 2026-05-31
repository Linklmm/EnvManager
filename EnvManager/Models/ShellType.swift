import Foundation

/// Shell 类型枚举
enum ShellType: String, Codable, CaseIterable {
    case zsh
    case bash
    case both  // 通用，两者都写

    /// 显示名称
    var displayName: String {
        switch self {
        case .zsh: return "zsh"
        case .bash: return "bash"
        case .both: return "通用"
        }
    }

    /// 配置文件路径（展开 ~ 为实际路径）
    var configFilePaths: [String] {
        let home = NSHomeDirectory()
        switch self {
        case .zsh:
            return [home + "/.zshrc"]
        case .bash:
            return [home + "/.bashrc"]
        case .both:
            return [home + "/.zshrc", home + "/.bashrc"]
        }
    }

    /// export 命令
    var exportCommand: String {
        return "export"
    }

    /// 描述
    var description: String {
        switch self {
        case .zsh: return "写入 ~/.zshrc"
        case .bash: return "写入 ~/.bashrc"
        case .both: return "同时写入 .zshrc 和 .bashrc"
        }
    }
}
