import SwiftUI
import EnvManagerCore
import UniformTypeIdentifiers

/// 主窗口视图 - 使用视图切换而非弹窗
struct MainWindowView: View {
    @StateObject private var viewModel: MainViewModel
    @State private var selectedGroup: EnvGroup?
    @State private var showDetailView = false
    @State private var selectedTab = 0

    /// 接收 EnvService 参数初始化
    init(envService: EnvService) {
        _viewModel = StateObject(wrappedValue: MainViewModel(envService: envService))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 分组管理标签页
            ZStack {
                if showDetailView && selectedGroup != nil {
                    // 详情页视图（页面切换，不是弹窗）
                    GroupDetailView(
                        group: selectedGroup!,
                        viewModel: viewModel,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showDetailView = false
                                selectedGroup = nil
                            }
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1)
                } else {
                    // 主列表视图
                    GroupListView(
                        viewModel: viewModel,
                        onEditGroup: { group in
                            selectedGroup = group
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showDetailView = true
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(0)
                }
            }
            .tabItem {
                Label("分组管理", systemImage: "folder.fill")
            }
            .tag(0)

            // Shell 配置标签页
            ShellConfigView()
                .tabItem {
                    Label("Shell 配置", systemImage: "terminal.fill")
                }
                .tag(1)
        }
    }
}

/// 分组列表视图 - 主页面
struct GroupListView: View {
    @ObservedObject var viewModel: MainViewModel
    let onEditGroup: (EnvGroup) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack(spacing: 12) {
                Text("环境分组")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { Task { await viewModel.loadGroups() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("刷新")

                    Button(action: { viewModel.showingImportPicker = true }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .help("导入")

                    Button(action: { viewModel.showingExportPicker = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("导出")

                    Divider()
                        .frame(height: 20)

                    Button(action: { viewModel.showingNewGroupSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("新建")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // 分组列表 - 设置面板风格
            Form {
                Section("环境分组") {
                    ForEach(viewModel.groups) { group in
                        GroupListRow(
                            group: group,
                            isActive: group.isActive,
                            onActivate: {
                                Task { await viewModel.switchGroup(id: group.id) }
                            },
                            onDeactivate: {
                                Task { await viewModel.deactivateGroup() }
                            },
                            onEdit: {
                                onEditGroup(group)
                            },
                            onIconChange: { newIcon in
                                Task { await viewModel.updateGroupIcon(group.id, icon: newIcon) }
                            }
                        )
                    }
                }
            }
            .formStyle(.grouped)

            // 错误提示
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Button("关闭") { viewModel.clearError() }
                        .buttonStyle(.plain)
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .task {
            await viewModel.loadGroups()
        }
        .sheet(isPresented: $viewModel.showingNewGroupSheet) {
            NewGroupSheet(
                name: $viewModel.newGroupName,
                icon: $viewModel.newGroupIcon,
                color: $viewModel.newGroupColor,
                onSave: {
                    Task {
                        await viewModel.createGroup(
                            name: viewModel.newGroupName,
                            icon: viewModel.newGroupIcon,
                            color: viewModel.newGroupColor
                        )
                        viewModel.resetNewGroupFields()
                        viewModel.showingNewGroupSheet = false
                    }
                },
                onCancel: {
                    viewModel.resetNewGroupFields()
                    viewModel.showingNewGroupSheet = false
                }
            )
        }
        .fileImporter(
            isPresented: $viewModel.showingImportPicker,
            allowedContentTypes: [.json],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    Task { await viewModel.importConfig(from: url) }
                case .failure(let error):
                    viewModel.errorMessage = "导入失败: \(error.localizedDescription)"
                }
            }
        )
        .fileExporter(
            isPresented: $viewModel.showingExportPicker,
            document: EnvConfigDocument(config: EnvConfig(groups: viewModel.groups)),
            contentType: .json,
            onCompletion: { result in
                if case .failure(let error) = result {
                    viewModel.errorMessage = "导出失败: \(error.localizedDescription)"
                }
            }
        )
    }
}

/// 分组详情视图 - 页面视图（不是弹窗）
struct GroupDetailView: View {
    let group: EnvGroup
    @ObservedObject var viewModel: MainViewModel
    let onBack: () -> Void

    @State private var searchText = ""
    @State private var showAddForm = false
    @State private var editingVariable: EnvVariable?
    @State private var showIconPicker = false
    @State private var previewExpanded = false

    // 用于刷新 group 数据（因为 group 是 let，需要从 viewModel 获取最新数据）
    var currentGroup: EnvGroup {
        viewModel.groups.first { $0.id == group.id } ?? group
    }

    var filteredVariables: [EnvVariable] {
        let variables = currentGroup.variables
        if searchText.isEmpty {
            return variables
        }
        return variables.filter { variable in
            (variable.key ?? "").lowercased().contains(searchText.lowercased()) ||
            (!variable.isSensitive && variable.value.lowercased().contains(searchText.lowercased()))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏 + 返回按钮（不变）
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                // 图标 - 可点击更换
                Button(action: { showIconPicker = true }) {
                    TechIconView(
                        iconName: currentGroup.icon,
                        size: 32,
                        groupColor: currentGroup.color,
                        groupName: currentGroup.name
                    )
                }
                .buttonStyle(.plain)
                .help("点击更换图标")
                .popover(isPresented: $showIconPicker, arrowEdge: .bottom) {
                    TechIconPicker(
                        currentIcon: currentGroup.icon,
                        onSelect: { selectedIcon in
                            if let icon = selectedIcon {
                                Task { await viewModel.updateGroupIcon(group.id, icon: icon.iconName) }
                            } else {
                                Task { await viewModel.updateGroupIcon(group.id, icon: nil) }
                            }
                            showIconPicker = false
                        }
                    )
                }

                Text(currentGroup.name)
                    .font(.system(size: 18, weight: .semibold))

                Spacer()
            }
            .padding()

            Divider()

            // 激活状态（不变）
            if currentGroup.isActive {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("当前已激活此分组")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
            }

            // 滚动容器 - 使用分组样式（macOS 使用 Form）
            Form {
                // 搜索栏
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索变量", text: $searchText)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                }

                // 配置项列表
                Section {
                    ForEach(filteredVariables) { variable in
                        VariableListRow(
                            variable: variable,
                            onEdit: {
                                editingVariable = variable
                                showAddForm = false
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deleteVariable(id: variable.id, from: group.id)
                                }
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("配置项")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Button(action: {
                            showAddForm = true
                            editingVariable = nil
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("添加")
                            }
                            .font(.system(size: 12))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // 预览变更 - 整行可点击展开
                Section {
                    if previewExpanded {
                        PreviewContentShellView(group: currentGroup)
                    }
                } header: {
                    HStack {
                        Text("预览变更")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(previewExpanded ? .degrees(90) : .zero)
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            previewExpanded.toggle()
                        }
                    }
                }
            }
            .formStyle(.grouped)

            // 底部按钮栏（移到 ScrollView 外）
            HStack(spacing: 12) {
                if currentGroup.isActive {
                    Button(action: {
                        Task { await viewModel.deactivateGroup() }
                    }) {
                        Text("取消激活")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: {
                        Task { await viewModel.switchGroup(id: group.id) }
                    }) {
                        Text("激活分组")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()

                Button("返回") {
                    onBack()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 550)
        .sheet(isPresented: $showAddForm) {
            AddVariableSheet(
                groupId: group.id,
                onSave: { variable in
                    Task {
                        await viewModel.addVariable(
                            configType: variable.configType,
                            shellType: variable.shellType,
                            key: variable.key,
                            value: variable.value,
                            aliasCommand: variable.aliasCommand,
                            isSensitive: variable.isSensitive,
                            description: variable.description,
                            to: group.id
                        )
                        showAddForm = false
                    }
                }
            )
        }
        .sheet(item: $editingVariable) { variable in
            EditVariableSheet(
                variable: variable,
                groupId: group.id,
                onSave: { updatedVariable in
                    Task {
                        viewModel.selectedGroupId = group.id
                        await viewModel.updateVariable(updatedVariable)
                        editingVariable = nil
                    }
                }
            )
        }
    }
}

/// 添加变量弹窗
struct AddVariableSheet: View {
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var configType: ConfigType = .envVariable
    @State private var shellType: ShellType = .zsh
    @State private var key = ""
    @State private var value = ""
    @State private var aliasCommand = ""
    @State private var description = ""
    @State private var isSensitive = false

    let onSave: (EnvVariable) -> Void

    var isValid: Bool {
        switch configType {
        case .envVariable, .shellConfig, .launchctl:
            return !key.isEmpty && !value.isEmpty
        case .path:
            return !value.isEmpty
        case .alias:
            return !value.isEmpty && !aliasCommand.isEmpty
        @unknown default:
            return false
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("添加配置")
                .font(.system(size: 18, weight: .semibold))

            ConfigTypePicker(selectedType: $configType)
                .onChange(of: configType) { _, newType in
                    if newType == .path { key = "" }
                    if newType != .alias { aliasCommand = "" }
                }

            DynamicConfigForm(
                configType: $configType,
                shellType: $shellType,
                key: $key,
                value: $value,
                aliasCommand: $aliasCommand,
                description: $description,
                isSensitive: $isSensitive
            )

            Divider()

            HStack(spacing: 12) {
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)

                Button("保存") {
                    if isValid {
                        let variable = EnvVariable(
                            key: configType == .path || configType == .alias ? nil : key,
                            value: value,
                            configType: configType,
                            shellType: configType.isShellConfig ? shellType : nil,
                            isSensitive: isSensitive,
                            description: description.isEmpty ? nil : description,
                            aliasCommand: configType == .alias ? aliasCommand : nil
                        )
                        onSave(variable)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
}

/// 编辑变量弹窗
struct EditVariableSheet: View {
    let variable: EnvVariable
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var configType: ConfigType
    @State private var shellType: ShellType
    @State private var key: String
    @State private var value: String
    @State private var aliasCommand: String
    @State private var description: String
    @State private var isSensitive: Bool

    let onSave: (EnvVariable) -> Void

    init(variable: EnvVariable, groupId: UUID, onSave: @escaping (EnvVariable) -> Void) {
        self.variable = variable
        self.groupId = groupId
        self.onSave = onSave

        _configType = State(initialValue: variable.configType)
        _shellType = State(initialValue: variable.shellType ?? .zsh)
        _key = State(initialValue: variable.key ?? "")
        _value = State(initialValue: variable.value)
        _aliasCommand = State(initialValue: variable.aliasCommand ?? "")
        _description = State(initialValue: variable.description ?? "")
        _isSensitive = State(initialValue: variable.isSensitive)
    }

    var isValid: Bool {
        switch configType {
        case .envVariable, .shellConfig, .launchctl:
            return !key.isEmpty && !value.isEmpty
        case .path:
            return !value.isEmpty
        case .alias:
            return !value.isEmpty && !aliasCommand.isEmpty
        @unknown default:
            return false
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("编辑配置")
                .font(.system(size: 18, weight: .semibold))

            ConfigTypePicker(selectedType: $configType)
                .onChange(of: configType) { _, newType in
                    if newType == .path { key = "" }
                    if newType != .alias { aliasCommand = "" }
                }

            DynamicConfigForm(
                configType: $configType,
                shellType: $shellType,
                key: $key,
                value: $value,
                aliasCommand: $aliasCommand,
                description: $description,
                isSensitive: $isSensitive
            )

            Divider()

            HStack(spacing: 12) {
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)

                Button("保存") {
                    if isValid {
                        let updatedVariable = EnvVariable(
                            id: variable.id,
                            key: configType == .path || configType == .alias ? nil : key,
                            value: value,
                            configType: configType,
                            shellType: configType.isShellConfig ? shellType : nil,
                            isSensitive: isSensitive,
                            description: description.isEmpty ? nil : description,
                            aliasCommand: configType == .alias ? aliasCommand : nil,
                            createdAt: variable.createdAt
                        )
                        onSave(updatedVariable)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
}

/// 分组列表行 - macOS 设置风格
struct GroupListRow: View {
    let group: EnvGroup
    let isActive: Bool
    let onActivate: () -> Void
    let onDeactivate: () -> Void
    let onEdit: () -> Void
    let onIconChange: (String?) -> Void

    @State private var showIconPicker = false

    var body: some View {
        HStack(spacing: 16) {
            // 图标 - 可点击更换，使用 TechIconView 显示
            Button(action: { showIconPicker = true }) {
                TechIconView(
                    iconName: group.icon,
                    size: 28,
                    groupColor: group.color,
                    groupName: group.name
                )
                .frame(width: 28, height: 28)
                .background(Color(hex: group.color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("点击更换图标")
            .popover(isPresented: $showIconPicker, arrowEdge: .leading) {
                TechIconPicker(
                    currentIcon: group.icon,
                    onSelect: { selectedIcon in
                        if let icon = selectedIcon {
                            onIconChange(icon.iconName)
                        } else {
                            onIconChange(nil)
                        }
                        showIconPicker = false
                    }
                )
            }

            // 名称和描述
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 13, weight: .semibold))

                Text("\(group.variables.count) 个变量")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Toggle 开关
            Toggle("", isOn: Binding(
                get: { isActive },
                set: { newValue in
                    if newValue {
                        onActivate()
                    } else {
                        onDeactivate()
                    }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)

            // 编辑按钮
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("编辑分组")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }
}

/// 变量列表行 - 统一样式（与分组列表一致）
struct VariableListRow: View {
    let variable: EnvVariable
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 配置类型图标区域（代替分组图标）
            Image(systemName: variable.configType.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // 变量名和值
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(variable.displayTitle)
                        .font(.system(size: 13, weight: .semibold))

                    if variable.isSensitive {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }

                    // Shell 类型标签
                    if let shell = variable.shellType {
                        Text(shell.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(3)
                    }
                }

                // 描述或值
                if let desc = variable.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text(variable.displayValue)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 配置类型标签
            Text(variable.configType.displayName)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)

            // 操作按钮
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("编辑")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("删除")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }
}

/// 新建分组弹窗
struct NewGroupSheet: View {
    @Binding var name: String
    @Binding var icon: String
    @State private var showIconPicker = false
    @Binding var color: String

    let onSave: () -> Void
    let onCancel: () -> Void

    let colorOptions = ["#667eea", "#f5576c", "#4ec9b0", "#f093fb", "#6a9955", "#888888", "#FFB347", "#77DD77"]

    var body: some View {
        VStack(spacing: 24) {
            Text("新建环境分组")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("分组名称")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("例如: Python 开发环境", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("图标")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Button(action: { showIconPicker = true }) {
                        HStack(spacing: 8) {
                            TechIconView(
                                iconName: icon.isEmpty ? nil : icon,
                                size: 24,
                                groupColor: color,
                                groupName: name
                            )
                            Text(icon.isEmpty ? "选择图标" : "点击更换")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showIconPicker, arrowEdge: .bottom) {
                        TechIconPicker(
                            currentIcon: icon.isEmpty ? nil : icon,
                            onSelect: { selectedIcon in
                                if let newIcon = selectedIcon {
                                    icon = newIcon.iconName
                                } else {
                                    icon = ""
                                }
                                showIconPicker = false
                            }
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("颜色")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(colorOptions, id: \.self) { option in
                            Button(action: { color = option }) {
                                Circle()
                                    .fill(Color(hex: option))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: color == option ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                Button("取消", action: onCancel)
                    .buttonStyle(.bordered)

                Button("创建", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

/// 配置文档类型
struct EnvConfigDocument: FileDocument {
    var config: EnvConfig

    init(config: EnvConfig) {
        self.config = config
    }

    static var readableContentTypes: [UTType] { [.json] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        config = try JSONDecoder().decode(EnvConfig.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(config)
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    MainWindowView(envService: EnvService())
}