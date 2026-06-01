import Foundation

/// 应用常量
public enum Constants {
    // MARK: - 应用信息
    public static let appName = "EnvManager"
    public static let appVersion = "1.0.0"

    // MARK: - 存储路径
    public static let appSupportDirectory: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("EnvManager")
    }()

    public static let configFileURL: URL = {
        appSupportDirectory.appendingPathComponent("config.json")
    }()

    public static let templatesFileURL: URL = {
        appSupportDirectory.appendingPathComponent("templates.json")
    }()

    public static let historyDatabaseURL: URL = {
        appSupportDirectory.appendingPathComponent("history.db")
    }()

    // MARK: - Shell 配置文件路径
    public static let zshrcPath: String = NSHomeDirectory() + "/.zshrc"
    public static let bashrcPath: String = NSHomeDirectory() + "/.bashrc"
    public static let bashProfilePath: String = NSHomeDirectory() + "/.bash_profile"

    // MARK: - 环境变量标记
    public static let envMarkerBegin = "# === EnvManager Begin ==="
    public static let envMarkerEnd = "# === EnvManager End ==="
    public static let envMarkerGroupBegin = "# EnvManager Group: "

    // MARK: - 预设颜色
    public static let defaultColors = [
        "#667eea", "#f5576c", "#4ec9b0", "#f093fb",
        "#6a9955", "#888888", "#FFB347", "#77DD77"
    ]

    // MARK: - 默认分组图标
    public static let defaultIcons: [String: String] = [
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