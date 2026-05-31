import Foundation

/// 应用常量
enum Constants {
    // MARK: - 应用信息
    static let appName = "EnvManager"
    static let appVersion = "1.0.0"

    // MARK: - 存储路径
    static let appSupportDirectory: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("EnvManager")
    }()

    static let configFileURL: URL = {
        appSupportDirectory.appendingPathComponent("config.json")
    }()

    static let templatesFileURL: URL = {
        appSupportDirectory.appendingPathComponent("templates.json")
    }()

    static let historyDatabaseURL: URL = {
        appSupportDirectory.appendingPathComponent("history.db")
    }()

    // MARK: - Shell 配置文件路径（使用 nonisolated 避免 actor 隔离问题）
    nonisolated(unsafe) static let zshrcPath: String = NSHomeDirectory() + "/.zshrc"
    nonisolated(unsafe) static let bashrcPath: String = NSHomeDirectory() + "/.bashrc"
    nonisolated(unsafe) static let bashProfilePath: String = NSHomeDirectory() + "/.bash_profile"

    // MARK: - 环境变量标记
    static let envMarkerBegin = "# === EnvManager Begin ==="
    static let envMarkerEnd = "# === EnvManager End ==="
    static let envMarkerGroupBegin = "# EnvManager Group: "

    // MARK: - 预设颜色
    static let defaultColors = [
        "#667eea", "#f5576c", "#4ec9b0", "#f093fb",
        "#6a9955", "#888888", "#FFB347", "#77DD77"
    ]

    // MARK: - 默认分组图标
    static let defaultIcons: [String: String] = [
        "🐍": "Python",
        "📦": "Node.js",
        "☕": "Java",
        "🔵": "Go",
        "💎": "Ruby",
        "🦀": "Rust",
        "⚙️": "System",
        "🔧": "Custom"
    ]
}