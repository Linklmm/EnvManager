import ArgumentParser
import Foundation
import EnvManagerCore

@main
struct EnvManagerCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "envm",
        abstract: "环境变量管理器 CLI",
        discussion: "管理和切换 macOS 开发环境配置",
        subcommands: [
            ListCommand.self,
            ShowCommand.self,
            SwitchCommand.self,
            ActivateCommand.self,
            DeactivateCommand.self
        ],
        defaultSubcommand: ShowCommand.self
    )
}

// MARK: - List Command

struct ListCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "列出所有环境分组"
    )

    @Flag(name: [.short, .long], help: "显示详细信息")
    var verbose = false

    mutating func run() async throws {
        let service = CLIEnvService.createDefault()
        let groups = try await service.listGroups()

        if groups.isEmpty {
            print("没有找到任何环境分组")
            print("请使用 GUI 应用创建分组")
            return
        }

        print("环境分组列表:")
        print("")

        for group in groups {
            let activeMark = group.isActive ? "✓" : " "
            print("[\(activeMark)] \(group.name) (\(group.variables.count) 个变量)")

            if verbose {
                for variable in group.variables {
                    let value = variable.isSensitive ? "********" : variable.value
                    print("    - \(variable.key ?? "PATH"): \(value)")
                }
                print("")
            }
        }

        if !verbose {
            print("")
            print("使用 --verbose 查看详细信息")
        }
    }
}

// MARK: - Show Command

struct ShowCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "show",
        abstract: "显示当前激活的分组"
    )

    mutating func run() async throws {
        let service = CLIEnvService.createDefault()
        let activeGroup = try await service.getActiveGroup()

        if let group = activeGroup {
            print("当前激活分组: \(group.name)")
            print("")

            if group.variables.isEmpty {
                print("该分组没有配置变量")
            } else {
                print("变量列表:")
                for variable in group.variables {
                    let value = variable.isSensitive ? "********" : variable.value
                    let typeLabel = variable.configType.displayName
                    print("  \(variable.key ?? "PATH") = \(value)")
                    print("    类型: \(typeLabel)")
                    if let shellType = variable.shellType {
                        print("    Shell: \(shellType.displayName)")
                    }
                }
            }
        } else {
            print("当前没有激活的分组")
            print("")
            print("使用 'envm switch <分组名>' 激活一个分组")
            print("使用 'envm list' 查看所有分组")
        }
    }
}

// MARK: - Switch Command

struct SwitchCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "switch",
        abstract: "切换到指定的环境分组"
    )

    @Argument(help: "分组名称")
    var groupName: String

    mutating func run() async throws {
        let service = CLIEnvService.createDefault()

        // 先检查分组是否存在
        guard let group = try await service.findGroupByName(name: groupName) else {
            print("错误: 找不到分组 '\(groupName)'")
            print("")
            print("使用 'envm list' 查看所有分组")
            throw ExitCode(1)
        }

        print("正在切换到分组: \(groupName)")
        let success = try await service.switchGroup(name: groupName)

        if success {
            print("✓ 已激活分组: \(groupName)")
            print("")
            print("变量已写入 shell 配置文件")
            print("请运行 'source ~/.zshrc' 或重新打开终端使变量生效")
        } else {
            print("切换失败")
            throw ExitCode(1)
        }
    }
}

// MARK: - Activate Command

struct ActivateCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "activate",
        abstract: "激活指定的环境分组 (同 switch)"
    )

    @Argument(help: "分组名称")
    var groupName: String

    mutating func run() async throws {
        let service = CLIEnvService.createDefault()

        // 先检查分组是否存在
        guard let group = try await service.findGroupByName(name: groupName) else {
            print("错误: 找不到分组 '\(groupName)'")
            print("")
            print("使用 'envm list' 查看所有分组")
            throw ExitCode(1)
        }

        print("正在激活分组: \(groupName)")
        let success = try await service.switchGroup(name: groupName)

        if success {
            print("✓ 已激活分组: \(groupName)")
            print("")
            print("变量已写入 shell 配置文件")
            print("请运行 'source ~/.zshrc' 或重新打开终端使变量生效")
        } else {
            print("激活失败")
            throw ExitCode(1)
        }
    }
}

// MARK: - Deactivate Command

struct DeactivateCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "deactivate",
        abstract: "取消当前激活的分组"
    )

    mutating func run() async throws {
        let service = CLIEnvService.createDefault()

        // 先检查是否有激活的分组
        guard let activeGroup = try await service.getActiveGroup() else {
            print("当前没有激活的分组")
            return
        }

        print("正在取消激活分组: \(activeGroup.name)")
        try await service.deactivateCurrentGroup()

        print("✓ 已取消激活分组: \(activeGroup.name)")
        print("")
        print("配置已从 shell 配置文件中移除")
        print("请运行 'source ~/.zshrc' 或重新打开终端使更改生效")
    }
}