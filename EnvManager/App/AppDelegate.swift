import SwiftUI

/// 应用代理 - 管理菜单栏和共享服务
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!

    /// 全局共享的 EnvService 实例
    static var sharedEnvService: EnvService!

    /// 共享实例（用于 MenuBarController 和其他组件）
    var envService: EnvService!

    /// 在 init 中创建 EnvService，确保在 SwiftUI 视图创建前就存在
    override init() {
        super.init()
        // 立即创建 EnvService，而不是等待 applicationDidFinishLaunching
        envService = EnvService()
        AppDelegate.sharedEnvService = envService
        print("🚀🚀🚀 [AppDelegate.init] EnvService 实例地址: \(ObjectIdentifier(envService))")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀🚀🚀 [AppDelegate.applicationDidFinishLaunching] EnvService 已存在，地址: \(ObjectIdentifier(envService))")

        // 创建菜单栏控制器（使用共享的 EnvService）
        menuBarController = MenuBarController(envService: envService)

        // 设置应用为代理应用（不显示在 Dock）
        // NSApplication.shared.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 关闭最后一个窗口时不退出应用（菜单栏继续运行）
        return false
    }
}