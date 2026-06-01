import SwiftUI
import Combine
import os.log
import EnvManagerCore

private let log = OSLog(subsystem: "com.envmanager", category: "MenuBarViewModel")

/// 菜单栏 ViewModel
@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var groups: [EnvGroup] = []
    @Published var activeGroupId: UUID?
    @Published var isLoading: Bool = false

    private let envService: EnvService
    private var cancellables = Set<AnyCancellable>()

    /// 初始化 - 接收共享的 EnvService
    init(envService: EnvService) {
        self.envService = envService

        os_log("🚀🚀🚀 [MenuBarVM] init, EnvService 实例地址: %{public}s", log: log, type: .info, String(describing: ObjectIdentifier(envService)))
        print("🚀🚀🚀 [MenuBarVM] init, EnvService 实例地址: \(ObjectIdentifier(envService))")

        // 订阅 EnvService.config 的变化，自动同步数据
        envService.$config
            .receive(on: RunLoop.main)
            .sink { [weak self] newConfig in
                guard let self = self else {
                    os_log("⚠️ [MenuBarVM] 订阅收到更新但 self 为 nil", log: log, type: .error)
                    return
                }
                os_log("📥 [MenuBarVM] 收到 config 更新, groups数量: %{public}d, activeGroupId: %{public}s",
                       log: log, type: .info,
                       newConfig.groups.count,
                       newConfig.activeGroupId?.uuidString ?? "nil")
                self.groups = newConfig.groups
                self.activeGroupId = newConfig.activeGroupId
                os_log("📋 [MenuBarVM] 已同步, 本地 activeGroupId: %{public}s",
                       log: log, type: .info,
                       self.activeGroupId?.uuidString ?? "nil")
            }
            .store(in: &cancellables)

        // 初始加载
        Task {
            os_log("🔄 [MenuBarVM] 开始初始加载", log: log, type: .info)
            await loadGroups()
            os_log("✅ [MenuBarVM] 初始加载完成, activeGroupId: %{public}s",
                   log: log, type: .info,
                   self.activeGroupId?.uuidString ?? "nil")
        }
    }

    /// 加载分组
    func loadGroups() async {
        isLoading = true
        os_log("🔄 [MenuBarVM] loadGroups 开始", log: log, type: .info)

        groups = envService.getAllGroups()
        activeGroupId = envService.getActiveGroup()?.id

        os_log("📋 [MenuBarVM] loadGroups 完成, groups数量: %{public}d, activeGroupId: %{public}s",
               log: log, type: .info,
               groups.count,
               activeGroupId?.uuidString ?? "nil")

        // 打印每个分组的状态
        for group in groups {
            os_log("  - 分组: %{public}s, isActive: %{public}s",
                   log: log, type: .info,
                   group.name,
                   group.isActive ? "true" : "false")
        }

        isLoading = false
    }

    /// 切换分组（激活）
    func switchGroup(id: UUID) async {
        os_log("🚀 [MenuBarVM] switchGroup 开始, id: %{public}s", log: log, type: .info, id.uuidString)
        isLoading = true

        do {
            os_log("  - 调用 envService.switchGroup...", log: log, type: .info)
            try await envService.switchGroup(to: id)
            os_log("  ✅ envService.switchGroup 完成", log: log, type: .info)
            // 数据通过订阅自动更新，无需手动赋值

            // 操作完成，发送通知关闭 popover
            NotificationCenter.default.post(name: .menuBarOperationCompleted, object: nil)
        } catch {
            os_log("  ❌ 激活失败: %{public}s", log: log, type: .error, error.localizedDescription)
            print("激活失败: \(error)")
        }

        isLoading = false
        os_log("🚀 [MenuBarVM] switchGroup 完成", log: log, type: .info)
    }

    /// 取消激活当前分组
    func deactivateGroup() async {
        os_log("🚀 [MenuBarVM] deactivateGroup 开始", log: log, type: .info)
        isLoading = true

        do {
            os_log("  - 调用 envService.deactivateGroup...", log: log, type: .info)
            try await envService.deactivateGroup()
            os_log("  ✅ envService.deactivateGroup 完成", log: log, type: .info)
            // 数据通过订阅自动更新，无需手动赋值

            // 操作完成，发送通知关闭 popover
            NotificationCenter.default.post(name: .menuBarOperationCompleted, object: nil)
        } catch {
            os_log("  ❌ 取消激活失败: %{public}s", log: log, type: .error, error.localizedDescription)
            print("取消激活失败: \(error)")
        }

        isLoading = false
        os_log("🚀 [MenuBarVM] deactivateGroup 完成", log: log, type: .info)
    }

    /// 打开主窗口
    func openMainWindow() {
        // 显示主窗口
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    /// 获取激活分组名称
    var activeGroupName: String? {
        guard let id = activeGroupId else { return nil }
        return groups.first { $0.id == id }?.name
    }

    /// 是否有激活分组
    var hasActiveGroup: Bool {
        return activeGroupId != nil
    }

    /// 获取分组数量
    var groupCount: Int {
        return groups.count
    }
}