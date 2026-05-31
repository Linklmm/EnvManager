import Foundation
import os.log

private let log = OSLog(subsystem: "com.envmanager", category: "StorageService")

/// 环境配置结构
struct EnvConfig: Codable {
    var groups: [EnvGroup]
    var activeGroupId: UUID?
    var version: String

    init(groups: [EnvGroup] = [], activeGroupId: UUID? = nil) {
        self.groups = groups
        self.activeGroupId = activeGroupId
        self.version = "1.0"
    }

    /// 获取激活的分组
    var activeGroup: EnvGroup? {
        guard let id = activeGroupId else { return nil }
        return groups.first { $0.id == id }
    }
}

/// 存储服务 - 管理 JSON 配置文件
actor StorageService {
    private let configURL: URL
    private let templatesURL: URL

    /// 初始化存储服务
    init(
        configURL: URL = Constants.configFileURL,
        templatesURL: URL = Constants.templatesFileURL
    ) {
        self.configURL = configURL
        self.templatesURL = templatesURL

        // 在初始化时确保目录存在
        ensureDirectoryExists()
    }

    /// 确保存储目录存在（如果失败会打印日志）
    private func ensureDirectoryExists() {
        let directory = configURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                print("创建数据目录: \(directory.path)")
            } catch {
                print("无法创建数据目录: \(error.localizedDescription)")
            }
        }
    }

    /// 保存配置
    func saveConfig(_ config: EnvConfig) throws {
        ensureDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: [.atomic])
    }

    /// 加载配置
    func loadConfig() throws -> EnvConfig {
        ensureDirectoryExists()
        os_log("📂 loadConfig: 配置文件路径 %{public}s", log: log, type: .info, configURL.path)
        if !FileManager.default.fileExists(atPath: configURL.path) {
            os_log("⚠️ 配置文件不存在，返回空配置", log: log, type: .info)
            return EnvConfig()
        }
        let data = try Data(contentsOf: configURL)
        os_log("📖 读取配置文件成功，大小: %{public}d 字节", log: log, type: .info, data.count)
        let decoder = JSONDecoder()
        let config = try decoder.decode(EnvConfig.self, from: data)
        os_log("✅ 解码配置成功，groups数量: %{public}d", log: log, type: .info, config.groups.count)
        return config
    }

    /// 保存模板列表
    func saveTemplates(_ templates: [Template]) throws {
        ensureDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(templates)
        try data.write(to: templatesURL, options: [.atomic])
    }

    /// 加载模板列表
    func loadTemplates() throws -> [Template] {
        ensureDirectoryExists()
        if !FileManager.default.fileExists(atPath: templatesURL.path) {
            return []
        }
        let data = try Data(contentsOf: templatesURL)
        let decoder = JSONDecoder()
        return try decoder.decode([Template].self, from: data)
    }

    /// 导出配置到指定路径
    func exportConfig(to url: URL) throws {
        let config = try loadConfig()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(config)
        try data.write(to: url, options: [.atomic])
    }

    /// 从指定路径导入配置
    func importConfig(from url: URL) throws -> EnvConfig {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let config = try decoder.decode(EnvConfig.self, from: data)
        try saveConfig(config)
        return config
    }
}