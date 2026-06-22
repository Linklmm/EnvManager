import SwiftUI
import Combine
import os.log
import EnvManagerCore

private let log = OSLog(subsystem: "com.envmanager", category: "MainViewModel")

/// 带分组信息的变量包装结构
struct EnvVariableWithGroup: Identifiable, Hashable {
    let variable: EnvVariable
    let group: EnvGroup

    var id: UUID { variable.id }
    var key: String { variable.key ?? "" }
    var value: String { variable.value }
    var displayValue: String { variable.displayValue }
    var configType: ConfigType { variable.configType }
    var isSensitive: Bool { variable.isSensitive }
    var groupName: String { group.name }
    var groupIcon: String? { group.icon }
    var groupColor: String { group.color }
    var groupIsActive: Bool { group.isActive }
}

/// 主窗口 ViewModel
@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [EnvGroup] = []
    @Published var filteredVariables: [EnvVariableWithGroup] = []
    @Published var selectedGroupFilter: String = "全部"
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingEditSheet: Bool = false
    @Published var showingNewGroupSheet: Bool = false
    @Published var selectedVariable: EnvVariable?
    @Published var selectedGroupId: UUID?

    // MARK: - 新增属性（用于新 UI）
    @Published var newGroupName = ""
    @Published var newGroupIcon = "🔧"
    @Published var newGroupColor = "#667eea"
    @Published var showingImportPicker = false
    @Published var showingExportPicker = false
    @Published var editViewModel = EnvEditViewModel()

    // MARK: - Services
    private let envService: EnvService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var groupFilters: [String] {
        ["全部"] + groups.map { $0.name }
    }

    var hasGroups: Bool {
        !groups.isEmpty
    }

    var hasVariables: Bool {
        !filteredVariables.isEmpty
    }

    var activeGroup: EnvGroup? {
        groups.first { $0.isActive }
    }

    // MARK: - Initialization
    init(envService: EnvService) {
        self.envService = envService
        print("🚀🚀🚀 [MainViewModel] init, EnvService 实例地址: \(ObjectIdentifier(envService))")

        // 监听搜索文本变化
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredVariables()
            }
            .store(in: &cancellables)

        // 监听分组筛选变化
        // 注意：Combine 先通知订阅者，后更新属性
        // 所以必须传入新值，不能读取 self.selectedGroupFilter
        $selectedGroupFilter
            .sink { [weak self] newFilter in
                print("🔍 [MainViewModel] selectedGroupFilter 变化: \(newFilter)")
                self?.updateFilteredVariables(withFilter: newFilter)
            }
            .store(in: &cancellables)

        // 监听 EnvService.config 的变化，自动同步 groups 并更新显示
        // 这是唯一的数据同步机制 - EnvService 是唯一数据源
        envService.$config
            .receive(on: RunLoop.main)
            .sink { [weak self] newConfig in
                guard let self = self else {
                    print("⚠️ [MainViewModel] 订阅收到更新但 self 为 nil")
                    return
                }
                print("📥 [MainViewModel] 收到 config 更新, groups数量: \(newConfig.groups.count)")
                print("  📌 activeGroupId: \(newConfig.activeGroupId?.uuidString ?? "nil")")
                for group in newConfig.groups {
                    print("  - 分组: \(group.name), isActive: \(group.isActive), 变量数: \(group.variables.count)")
                }
                // 同步 groups 数据
                self.groups = newConfig.groups
                print("📊 [MainViewModel] groups 已同步, 本地 groups 数量: \(self.groups.count)")
                print("📌 [MainViewModel] 本地 activeGroup: \(self.activeGroup?.name ?? "nil")")
                // 立即更新过滤后的变量列表
                self.updateFilteredVariables()
                print("📋 [MainViewModel] filteredVariables 已更新, 数量: \(self.filteredVariables.count)")
            }
            .store(in: &cancellables)

        // 注意：移除了 Task { await loadGroups() }
        // 数据通过 envService.$config 订阅自动同步
    }

    // MARK: - Public Methods

    /// 刷新数据 - 触发 EnvService 加载最新配置
    /// 数据通过 envService.$config 订阅自动同步到 groups
    func loadGroups() async {
        isLoading = true
        errorMessage = nil

        // 触发 EnvService 刷新配置
        await envService.loadConfig()
        // groups 会通过订阅自动更新，无需手动赋值

        isLoading = false
    }

    /// 创建新分组
    func createGroup(name: String, icon: String?, color: String) async {
        isLoading = true

        do {
            _ = try await envService.createGroup(name: name, icon: icon, color: color)
            // groups 会通过 envService.$config 订阅自动同步，无需手动 append
        } catch {
            errorMessage = "创建分组失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 删除分组
    func deleteGroup(id: UUID) async {
        isLoading = true

        do {
            try await envService.deleteGroup(id: id)
            groups.removeAll { $0.id == id }
            updateFilteredVariables()
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 切换分组激活状态
    func switchGroup(id: UUID) async {
        os_log("🔄 switchGroup 开始, id: %{public}s", log: log, type: .info, id.uuidString)
        isLoading = true

        do {
            os_log("  - 调用 envService.switchGroup...", log: log, type: .info)
            try await envService.switchGroup(to: id)
            os_log("  ✅ envService.switchGroup 完成", log: log, type: .info)
            for i in groups.indices {
                groups[i].isActive = groups[i].id == id
            }
            os_log("  - 更新本地 groups 的 isActive 状态", log: log, type: .info)
        } catch {
            os_log("  ❌ 切换失败: %{public}s", log: log, type: .error, error.localizedDescription)
            errorMessage = "切换失败: \(error.localizedDescription)"
        }

        isLoading = false
        os_log("🔄 switchGroup 完成", log: log, type: .info)
    }

    /// 取消激活当前分组
    func deactivateGroup() async {
        os_log("🔄 deactivateGroup 开始", log: log, type: .info)
        isLoading = true

        do {
            os_log("  - 调用 envService.deactivateGroup...", log: log, type: .info)
            try await envService.deactivateGroup()
            os_log("  ✅ envService.deactivateGroup 完成", log: log, type: .info)
            for i in groups.indices {
                groups[i].isActive = false
            }
            os_log("  - 更新本地 groups 的 isActive 状态为全部 false", log: log, type: .info)
        } catch {
            os_log("  ❌ 取消激活失败: %{public}s", log: log, type: .error, error.localizedDescription)
            errorMessage = "取消激活失败: \(error.localizedDescription)"
        }

        isLoading = false
        os_log("🔄 deactivateGroup 完成", log: log, type: .info)
    }

    /// 选择变量进行编辑
    func selectVariable(_ variable: EnvVariable, groupId: UUID) {
        selectedVariable = variable
        selectedGroupId = groupId
        showingEditSheet = true
    }

    /// 添加新变量到指定分组
    func addVariable(configType: ConfigType, shellType: ShellType?, key: String?, value: String, aliasCommand: String?, isSensitive: Bool, description: String?, to groupId: UUID) async {
        let variable = EnvVariable(
            key: key,
            value: value,
            configType: configType,
            shellType: shellType,
            isSensitive: isSensitive,
            description: description,
            aliasCommand: aliasCommand
        )

        isLoading = true

        do {
            try await envService.addVariable(variable, to: groupId)
            // 重新从 EnvService 获取数据，确保数据同步
            groups = envService.getAllGroups()
            updateFilteredVariables()
        } catch {
            errorMessage = "添加变量失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 更新变量
    func updateVariable(_ variable: EnvVariable) async {
        guard let groupId = selectedGroupId else {
            errorMessage = "请先选择一个分组"
            return
        }

        isLoading = true

        do {
            try await envService.updateVariable(variable, in: groupId)
            // 重新从 EnvService 获取数据，确保数据同步
            groups = envService.getAllGroups()
            updateFilteredVariables()
        } catch {
            errorMessage = "更新变量失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 删除变量
    func deleteVariable(id: UUID, from groupId: UUID) async {
        isLoading = true

        do {
            try await envService.deleteVariable(id: id, from: groupId)
            // 重新从 EnvService 获取数据，确保数据同步
            groups = envService.getAllGroups()
            updateFilteredVariables()
        } catch {
            errorMessage = "删除变量失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 导出配置
    func exportConfig(to url: URL) async {
        isLoading = true

        do {
            try await envService.exportConfig(to: url)
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 导入配置
    func importConfig(from url: URL) async {
        isLoading = true

        do {
            try await envService.importConfig(from: url)
            groups = envService.getAllGroups()
            updateFilteredVariables()
        } catch {
            errorMessage = "导入失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 应用模板
    func applyTemplate(_ template: Template, name: String) async {
        isLoading = true

        do {
            try await envService.applyTemplate(template, name: name)
            groups = envService.getAllGroups()
            updateFilteredVariables()
        } catch {
            errorMessage = "应用模板失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }

    /// 显示新建分组弹窗
    func showNewGroupSheet() {
        showingNewGroupSheet = true
    }

    // MARK: - 新增方法（用于新 UI）

    /// 重置新建分组字段
    func resetNewGroupFields() {
        newGroupName = ""
        newGroupIcon = "🔧"
        newGroupColor = "#667eea"
    }

    /// 更新分组图标
    func updateGroupIcon(_ groupId: UUID, icon: String?) async {
        isLoading = true

        do {
            try await envService.updateGroupIcon(groupId, icon: icon)
            // 数据会通过订阅自动更新
        } catch {
            errorMessage = "更新图标失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// 更新过滤后的变量列表
    /// 参数 filter: 筛选值，如果为 nil 则使用当前属性值
    private func updateFilteredVariables(withFilter filter: String? = nil) {
        let effectiveFilter = filter ?? selectedGroupFilter
        print("🔄 [MainViewModel] updateFilteredVariables 开始")
        print("  - 当前 groups 数量: \(groups.count)")
        print("  - 传入筛选值: \(filter ?? "nil")")
        print("  - 实际使用筛选值: \(effectiveFilter)")

        var result: [EnvVariableWithGroup] = []

        for group in groups {
            print("  - 处理分组: \(group.name), isActive: \(group.isActive)")
            // 分组筛选
            if effectiveFilter != "全部" && group.name != effectiveFilter {
                print("    - 跳过分组 \(group.name) (筛选条件不匹配)")
                continue
            }

            print("    - 分组 \(group.name) 匹配筛选, 变量数: \(group.variables.count)")
            for variable in group.variables {
                // 搜索筛选
                if !searchText.isEmpty {
                    let matchesKey = (variable.key ?? "").lowercased().contains(searchText.lowercased())
                    let matchesValue = !variable.isSensitive && variable.value.lowercased().contains(searchText.lowercased())
                    let matchesDesc = variable.description?.lowercased().contains(searchText.lowercased()) ?? false

                    if !matchesKey && !matchesValue && !matchesDesc {
                        continue
                    }
                }

                result.append(EnvVariableWithGroup(variable: variable, group: group))
            }
        }

        filteredVariables = result
        print("📋 [MainViewModel] updateFilteredVariables 完成, 结果数量: \(filteredVariables.count)")
    }
}