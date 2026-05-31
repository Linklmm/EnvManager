import SwiftUI

// MARK: - MainWindowContainer
/// 包装视图 - 确保 EnvService 在 SwiftUI 视图创建前存在
struct MainWindowContainer: View {
    var body: some View {
        // AppDelegate.init() 在 App.body 执行前调用，所以 sharedEnvService 已存在
        let envService = AppDelegate.sharedEnvService!
        print("🚀🚀🚀 [MainWindowContainer] body, EnvService 实例地址: \(ObjectIdentifier(envService))")
        return MainWindowView(envService: envService)
    }
}

@main
struct EnvManagerApp: App {
    // AppDelegate 已通过 @NSApplicationDelegateAdaptor 自动注册
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // 使用包装视图来正确注入 EnvService
            MainWindowContainer()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建分组") {
                    // 通过 NotificationCenter 触发
                    NotificationCenter.default.post(name: .showNewGroupSheet, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandMenu("环境管理") {
                Button("刷新配置") {
                    NotificationCenter.default.post(name: .refreshConfig, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("导入配置") {
                    NotificationCenter.default.post(name: .showImportPicker, object: nil)
                }

                Button("导出配置") {
                    NotificationCenter.default.post(name: .showExportPicker, object: nil)
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }

            SecuritySettingsView()
                .tabItem {
                    Label("安全", systemImage: "lock")
                }
        }
        .frame(width: 400, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("defaultShell") private var defaultShell = "zsh"

    var body: some View {
        Form {
            Picker("默认 Shell:", selection: $defaultShell) {
                Text("Zsh").tag("zsh")
                Text("Bash").tag("bash")
            }
        }
        .padding()
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("密码保护")
                .font(.headline)

            Text("设置密码后，查看敏感变量时需要验证")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("设置密码") {
                // 打开密码设置
            }

            Divider()

            Toggle("使用 Touch ID（如可用）", isOn: .constant(false))
        }
        .padding()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let showNewGroupSheet = Notification.Name("showNewGroupSheet")
    static let showImportPicker = Notification.Name("showImportPicker")
    static let showExportPicker = Notification.Name("showExportPicker")
    static let refreshConfig = Notification.Name("refreshConfig")
    static let menuBarOperationCompleted = Notification.Name("menuBarOperationCompleted")
}