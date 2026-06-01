import SwiftUI
import EnvManagerCore

/// Shell 配置查看页面
struct ShellConfigView: View {
    @State private var selectedShell: ShellType = .zsh
    @State private var zshrcContent: String = ""
    @State private var bashrcContent: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // 编辑相关状态
    @State private var isEditing = false
    @State private var editingContent: String = ""
    @State private var showEditWarning = false
    @State private var showEditError = false

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack(spacing: 12) {
                Text("Shell 配置文件")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                // Shell 类型切换
                Picker("", selection: $selectedShell) {
                    Text(".zshrc").tag(ShellType.zsh)
                    Text(".bashrc").tag(ShellType.bash)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .disabled(isEditing)

                if isEditing {
                    // 编辑模式：显示保存和取消按钮
                    Button("取消") {
                        isEditing = false
                        editingContent = ""
                    }
                    .keyboardShortcut(.escape, modifiers: [])

                    Button("保存") {
                        Task { await saveContent() }
                    }
                    .keyboardShortcut("s", modifiers: .command)
                } else {
                    // 非编辑模式：显示刷新和编辑按钮
                    Button(action: { Task { await loadContent() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("刷新")

                    Button(action: { showEditWarning = true }) {
                        Image(systemName: "pencil")
                    }
                    .help("编辑")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // 文件内容展示
            if isLoading && !isEditing {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage, !isEditing {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                    Button("重试") {
                        Task { await loadContent() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isEditing {
                // 编辑模式：使用 TextEditor
                TextEditor(text: $editingContent)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor))
            } else {
                // 非编辑模式：使用 ShellFileView
                ShellFileView(content: selectedShell == .zsh ? zshrcContent : bashrcContent)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .task {
            await loadContent()
        }
        .alert("编辑风险提示", isPresented: $showEditWarning) {
            Button("取消", role: .cancel) { }
            Button("继续编辑") {
                startEditing()
            }
        } message: {
            Text("直接编辑 Shell 配置文件可能会破坏 EnvManager 的管理边界。\n建议只编辑 EnvManager 管理范围之外的内容。\n是否继续编辑？")
        }
        .alert("保存失败", isPresented: $showEditError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private func loadContent() async {
        isLoading = true
        errorMessage = nil

        do {
            // 加载 .zshrc
            if FileManager.default.fileExists(atPath: Constants.zshrcPath) {
                zshrcContent = try String(contentsOfFile: Constants.zshrcPath, encoding: .utf8)
            } else {
                zshrcContent = "# 文件不存在"
            }

            // 加载 .bashrc
            if FileManager.default.fileExists(atPath: Constants.bashrcPath) {
                bashrcContent = try String(contentsOfFile: Constants.bashrcPath, encoding: .utf8)
            } else {
                bashrcContent = "# 文件不存在"
            }
        } catch {
            errorMessage = "读取文件失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func startEditing() {
        editingContent = selectedShell == .zsh ? zshrcContent : bashrcContent
        isEditing = true
    }

    private func saveContent() async {
        isLoading = true
        errorMessage = nil

        do {
            let filePath = selectedShell == .zsh ? Constants.zshrcPath : Constants.bashrcPath
            try editingContent.write(toFile: filePath, atomically: true, encoding: .utf8)

            // 更新显示内容
            if selectedShell == .zsh {
                zshrcContent = editingContent
            } else {
                bashrcContent = editingContent
            }

            isEditing = false
            editingContent = ""
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showEditError = true
        }

        isLoading = false
    }
}