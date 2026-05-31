import Foundation

/// CLI 处理器 - 暂时简化版本
/// CLI 功能将在配置好模块链接后启用
@main
struct EnvManagerCLI {
    static func main() {
        print("EnvManager CLI")
        print("功能暂时禁用，请使用主 App 进行环境管理")
        print("")
        print("请先在 Xcode 中配置:")
        print("1. EnvManagerCLI target 链接 EnvManager 模块")
        print("2. 添加 swift-argument-parser 包依赖")
    }
}