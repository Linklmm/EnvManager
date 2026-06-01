import Foundation
import os.log

private let log = OSLog(subsystem: "com.envmanager", category: "CLIInstaller")

/// CLI 安装服务 - 将 CLI 安装到系统 PATH
enum CLIInstaller {

    /// CLI 安装目标路径
    private static let installPath = "/usr/local/bin/envm"

    /// 检查 CLI 是否已安装
    static func isInstalled() -> Bool {
        return FileManager.default.isExecutableFile(atPath: installPath)
    }

    /// 获取 App 内的 CLI 路径
    private static func getBundledCLIPath() -> String? {
        let bundlePath = Bundle.main.bundlePath
        let cliPath = bundlePath + "/Contents/Resources/envm"
        return FileManager.default.isExecutableFile(atPath: cliPath) ? cliPath : nil
    }

    /// 安装 CLI 到系统 PATH
    /// - Returns: 是否安装成功
    static func install() -> Bool {
        // 如果已安装，检查版本是否需要更新
        if isInstalled() {
            os_log("CLI 已安装在 %{public}s", log: log, type: .info, installPath)
            return true
        }

        // 获取 bundled CLI
        guard let bundledCLIPath = getBundledCLIPath() else {
            os_log("无法找到 App 内的 CLI", log: log, type: .error)
            return false
        }

        os_log("正在安装 CLI: %{public}s -> %{public}s", log: log, type: .info, bundledCLIPath, installPath)

        // 使用 AuthorizationExecuteWithPrivileges 执行复制（需要管理员权限）
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = [
            "-c",
            "cp '\(bundledCLIPath)' '\(installPath)' && chmod +x '\(installPath)'"
        ]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                os_log("CLI 安装成功", log: log, type: .info)
                return true
            } else {
                os_log("CLI 安装失败，退出码: %{public}d", log: log, type: .error, task.terminationStatus)
                return false
            }
        } catch {
            os_log("CLI 安装异常: %{public}s", log: log, type: .error, error.localizedDescription)
            return false
        }
    }

    /// 提示用户手动安装 CLI
    static func getManualInstallCommand() -> String? {
        guard let bundledCLIPath = getBundledCLIPath() else {
            return nil
        }
        return "sudo cp '\(bundledCLIPath)' /usr/local/bin/envm && sudo chmod +x /usr/local/bin/envm"
    }
}