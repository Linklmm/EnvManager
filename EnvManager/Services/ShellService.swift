import Foundation
import os.log

private let log = OSLog(subsystem: "com.envmanager", category: "ShellService")

/// Shell 配置文件服务 - 按 shellType 分流写入不同配置文件
actor ShellService {

    /// 写入环境变量到 Shell 配置文件
    /// 按 shellType 分流写入不同的配置文件（zsh → ~/.zshrc, bash → ~/.bashrc）
    func writeEnvVariables(_ group: EnvGroup) throws {
        os_log("🔄 writeEnvVariables 开始", log: log, type: .info)
        os_log("  - 分组名: %{public}s", log: log, type: .info, group.name)
        os_log("  - 变量数: %{public}d", log: log, type: .info, group.variables.count)

        // 打印每个变量的详细信息
        for variable in group.variables {
            os_log("  - 变量: key=%{public}s, value=%{public}s, configType=%{public}s, shellType=%{public}s",
                   log: log, type: .info,
                   variable.key ?? "nil",
                   variable.value,
                   variable.configType.rawValue,
                   variable.shellType?.rawValue ?? "nil")
        }

        // 只处理 shell 相关类型（排除 launchctl）
        let shellVariables = group.variables.filter { $0.configType != .launchctl }
        os_log("  - Shell 变量数: %{public}d", log: log, type: .info, shellVariables.count)

        // 按 shellType 分组
        var zshVariables: [EnvVariable] = []
        var bashVariables: [EnvVariable] = []

        for variable in shellVariables {
            os_log("    - 分流变量: shellType=%{public}s", log: log, type: .info, variable.shellType?.rawValue ?? "nil")
            switch variable.shellType {
            case .zsh:
                os_log("      → 加入 zshVariables", log: log, type: .info)
                zshVariables.append(variable)
            case .bash:
                os_log("      → 加入 bashVariables", log: log, type: .info)
                bashVariables.append(variable)
            case .both, nil:
                os_log("      → 加入 zshVariables 和 bashVariables（通用/nil）", log: log, type: .info)
                zshVariables.append(variable)
                bashVariables.append(variable)
            }
        }

        os_log("  - zshVariables 数量: %{public}d", log: log, type: .info, zshVariables.count)
        os_log("  - bashVariables 数量: %{public}d", log: log, type: .info, bashVariables.count)

        // 写入 zsh 配置
        if !zshVariables.isEmpty {
            os_log("  - 写入 zsh 配置 (%{public}d 个变量)", log: log, type: .info, zshVariables.count)
            let zshGroup = EnvGroup(name: group.name, icon: group.icon, color: group.color, variables: zshVariables)
            try writeToFile(Constants.zshrcPath, group: zshGroup)
        }

        // 写入 bash 配置
        if !bashVariables.isEmpty {
            os_log("  - 写入 bash 配置 (%{public}d 个变量)", log: log, type: .info, bashVariables.count)
            let bashGroup = EnvGroup(name: group.name, icon: group.icon, color: group.color, variables: bashVariables)
            try writeToFile(Constants.bashrcPath, group: bashGroup)
        }

        os_log("  ✅ 写入成功", log: log, type: .info)
    }

    /// 写入到指定文件
    private func writeToFile(_ filePath: String, group: EnvGroup) throws {
        os_log("    - 文件路径: %{public}s", log: log, type: .info, filePath)

        // 文件不存在时创建空文件
        if !FileManager.default.fileExists(atPath: filePath) {
            os_log("    - 文件不存在，创建新文件", log: log, type: .info)
            try "".write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        let content = try readFileContent(at: filePath)
        os_log("    - 当前文件内容长度: %{public}d 字符", log: log, type: .info, content.count)

        let cleanedContent = removeGroupBlock(content, groupName: group.name)
        os_log("    - 清理后内容长度: %{public}d 字符", log: log, type: .info, cleanedContent.count)

        let newBlock = generateEnvBlock(group)
        os_log("    - 新块已生成", log: log, type: .info)

        let newContent = cleanedContent + newBlock
        os_log("    - 最终内容长度: %{public}d 字符", log: log, type: .info, newContent.count)

        try writeFileContent(newContent, at: filePath)
        os_log("    ✅ 写入文件成功", log: log, type: .info)
    }

    /// 移除指定分组的环境变量（从所有配置文件中移除）
    func removeEnvVariables(groupName: String) throws {
        // 从 zshrc 移除
        if FileManager.default.fileExists(atPath: Constants.zshrcPath) {
            let content = try readFileContent(at: Constants.zshrcPath)
            let cleanedContent = removeGroupBlock(content, groupName: groupName)
            try writeFileContent(cleanedContent, at: Constants.zshrcPath)
        }

        // 从 bashrc 移除
        if FileManager.default.fileExists(atPath: Constants.bashrcPath) {
            let content = try readFileContent(at: Constants.bashrcPath)
            let cleanedContent = removeGroupBlock(content, groupName: groupName)
            try writeFileContent(cleanedContent, at: Constants.bashrcPath)
        }
    }

    /// 读取指定分组的环境变量
    func readEnvVariables(groupName: String) throws -> EnvGroup? {
        // 优先从 zshrc 读取
        if FileManager.default.fileExists(atPath: Constants.zshrcPath) {
            let content = try readFileContent(at: Constants.zshrcPath)
            if let group = parseGroupFromContent(content, groupName: groupName) {
                return group
            }
        }

        // 如果 zshrc 没有，尝试 bashrc
        if FileManager.default.fileExists(atPath: Constants.bashrcPath) {
            let content = try readFileContent(at: Constants.bashrcPath)
            return parseGroupFromContent(content, groupName: groupName)
        }

        return nil
    }

    /// 从内容中解析分组
    private func parseGroupFromContent(_ content: String, groupName: String) -> EnvGroup? {
        let groupBeginMarker = Constants.envMarkerGroupBegin + groupName

        guard let beginIndex = content.range(of: groupBeginMarker)?.lowerBound else {
            return nil
        }

        guard let endIndex = content[beginIndex...].range(of: Constants.envMarkerEnd)?.upperBound else {
            return nil
        }

        let blockContent = String(content[beginIndex..<endIndex])

        var variables: [EnvVariable] = []
        let lines = blockContent.split(separator: "\n")

        for line in lines {
            if line.contains("export ") {
                let parts = line.replacingOccurrences(of: "export ", with: "").split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    var value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

                    let variable = EnvVariable(key: key, value: value, configType: .envVariable, shellType: .zsh)
                    variables.append(variable)
                }
            }
        }

        return EnvGroup(name: groupName, variables: variables)
    }

    /// 读取文件内容
    private func readFileContent(at path: String) throws -> String {
        if !FileManager.default.fileExists(atPath: path) {
            return ""
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// 写入文件内容
    private func writeFileContent(_ content: String, at path: String) throws {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// 移除分组块 - 移除整个 EnvManager 块（包括 Begin 标记）
    private func removeGroupBlock(_ content: String, groupName: String) -> String {
        // 找到 EnvManager Begin 标记，移除从该标记到文件末尾的所有内容
        if let beginRange = content.range(of: Constants.envMarkerBegin) {
            let cleaned = String(content[..<beginRange.lowerBound])
            let trimmed = cleaned.trimmingCharacters(in: .newlines)
            return trimmed.isEmpty ? "" : trimmed + "\n"
        }

        let trimmed = content.trimmingCharacters(in: .newlines)
        return trimmed.isEmpty ? "" : trimmed + "\n"
    }

    /// 生成环境变量块
    private func generateEnvBlock(_ group: EnvGroup) -> String {
        var block = ""
        block += Constants.envMarkerBegin + "\n"
        block += Constants.envMarkerGroupBegin + group.name + "\n"

        for variable in group.variables {
            let line = variable.generateConfigStatement()
            block += line + "\n"
        }

        block += Constants.envMarkerEnd + "\n"
        return block
    }

    /// 获取所有 Shell 配置文件路径
    func getAllShellConfigPaths() -> [String] {
        [Constants.zshrcPath, Constants.bashrcPath, Constants.bashProfilePath]
    }
}