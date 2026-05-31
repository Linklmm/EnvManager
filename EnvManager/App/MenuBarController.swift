import SwiftUI

/// 菜单栏控制器 - 使用 @MainActor 与 UI 兼容
@MainActor
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menuBarViewModel: MenuBarViewModel!
    private var envService: EnvService

    /// 初始化 - 接收共享的 EnvService
    init(envService: EnvService) {
        self.envService = envService
        super.init()

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupNotificationListener()
    }

    /// 设置状态栏项
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "EnvManager")
            button.image?.isTemplate = true
            button.action = #selector(handleStatusItemClick)
            button.target = self
        }
    }

    /// 设置弹出窗口
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        popover.animates = true

        // 使用共享的 EnvService 创建 MenuBarViewModel
        menuBarViewModel = MenuBarViewModel(envService: envService)

        let contentView = NSHostingView(rootView: MenuBarView(viewModel: menuBarViewModel))
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = contentView
    }

    /// 设置事件监听器
    private func setupEventMonitor() {
        // 监听点击其他区域关闭弹出窗口
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closePopover()
            }
        }
    }

    /// 设置通知监听器 - 用于操作完成后关闭 popover
    private func setupNotificationListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOperationCompleted),
            name: .menuBarOperationCompleted,
            object: nil
        )
    }

    /// 处理操作完成通知
    @objc private func handleOperationCompleted() {
        closePopover()
    }

    /// 处理状态栏点击
    @objc private func handleStatusItemClick() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    /// 打开弹出窗口
    private func openPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        // 激活应用
        NSApplication.shared.activate(ignoringOtherApps: true)

        // 添加本地事件监听（点击弹出窗口内部）
        // 注意：不在这里关闭 popover，让按钮点击能正常执行
        // popover.behavior = .transient 会自动处理点击外部关闭
    }

    /// 关闭弹出窗口
    private func closePopover() {
        popover.performClose(nil)
    }

    /// 更新状态栏图标（显示激活分组）
    func updateStatusIcon(groupName: String?) {
        if let name = groupName {
            statusItem.button?.title = "⚙️ \(name)"
        } else {
            statusItem.button?.title = ""
        }
    }
}