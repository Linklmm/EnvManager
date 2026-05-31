import SwiftUI

/// Shell 类型选择器组件
struct ShellTypePicker: View {
    @Binding var selectedShell: ShellType

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("目标 Shell")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(ShellType.allCases, id: \.self) { shell in
                    Button(action: { selectedShell = shell }) {
                        VStack(spacing: 4) {
                            Text(shell.displayName)
                                .font(.system(size: 13, weight: selectedShell == shell ? .medium : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedShell == shell ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedShell == shell ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    ShellTypePicker(selectedShell: .constant(.zsh))
}
