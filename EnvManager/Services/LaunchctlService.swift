import Foundation

/// Launchctl 错误
enum LaunchctlError: Error, LocalizedError {
    case setFailed(String)
    case unsetFailed(String)
    case executionFailed

    var errorDescription: String? {
        switch self {
        case .setFailed(let key):
            return "设置环境变量 \(key) 失败"
        case .unsetFailed(let key):
            return "删除环境变量 \(key) 失败"
        case .executionFailed:
            return "命令执行失败"
        }
    }
}

/// Launchctl 服务 - 管理系统级环境变量
actor LaunchctlService {

    /// 设置环境变量
    func setEnv(key: String, value: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["launchctl", "setenv", key, value]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw LaunchctlError.setFailed(key)
        }
    }

    /// 获取环境变量
    func getEnv(key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }

    /// 删除环境变量
    func unsetEnv(key: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["launchctl", "unsetenv", key]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw LaunchctlError.unsetFailed(key)
        }
    }

    /// 获取所有环境变量
    func listEnvVariables() -> [String: String] {
        return ProcessInfo.processInfo.environment
    }

    /// 从环境变量创建 EnvVariable 列表
    func createEnvVariablesFromSystem() -> [EnvVariable] {
        let env = ProcessInfo.processInfo.environment
        return env.map { (key, value) in
            EnvVariable(key: key, value: value, configType: .launchctl)
        }
    }
}