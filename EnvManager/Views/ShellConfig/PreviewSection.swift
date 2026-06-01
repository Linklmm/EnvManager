import SwiftUI
import EnvManagerCore

/// 预览内容 — 显示 shell 配置块（用于 Form Section 内）
struct PreviewContentShellView: View {
    let group: EnvGroup

    @State private var selectedShell: ShellType = .zsh

    var body: some View {
        VStack(spacing: 12) {
            ShellTypePicker(selectedShell: $selectedShell)

            ScrollView {
                ShellFileView(content: generatePreviewBlock())
            }
            .frame(minHeight: 120)
            .border(Color.gray.opacity(0.3))

            Text("激活此分组后，配置文件将包含以上内容")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    private func generatePreviewBlock() -> String {
        let variables = group.variables.filter { variable in
            guard let shellType = variable.shellType else { return true }
            switch shellType {
            case .zsh:
                return selectedShell == .zsh
            case .bash:
                return selectedShell == .bash
            case .both:
                return true
            @unknown default:
                return true
            }
        }

        var block = ""
        block += Constants.envMarkerBegin + "\n"
        block += Constants.envMarkerGroupBegin + group.name + "\n"

        for variable in variables {
            block += variable.generateConfigStatement() + "\n"
        }

        block += Constants.envMarkerEnd + "\n"
        return block
    }
}
