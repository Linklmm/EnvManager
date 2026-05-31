import SwiftUI
import os.log

private let log = OSLog(subsystem: "com.envmanager", category: "GroupRowView")

/// 分组行视图（用于菜单栏）
struct GroupRowView: View {
    let group: EnvGroup
    let isActive: Bool
    let onActivate: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // 激活状态指示器（放在最前面）
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }

            // 图标
            Text(group.icon ?? "🔧")
                .font(.system(size: 16))
                .frame(width: 24)

            // 名称和变量数
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 13, weight: isActive ? .medium : .regular))

                Text("\(group.variables.count) 个变量")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 操作按钮
            if isActive {
                // 已激活：显示取消激活按钮
                Button(action: {
                    os_log("👆 [GroupRowView] 点击取消激活按钮, 分组: %{public}s", log: log, type: .info, group.name)
                    onDeactivate()
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("点击取消激活此分组")
            } else {
                // 未激活：显示激活按钮
                Button(action: {
                    os_log("👆 [GroupRowView] 点击激活按钮, 分组: %{public}s", log: log, type: .info, group.name)
                    onActivate()
                }) {
                    Text("激活")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: group.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: group.color).opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("点击激活此环境分组")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            os_log("👆 [GroupRowView] 点击整个行, 分组: %{public}s, isActive: %{public}s", log: log, type: .info, group.name, isActive ? "true" : "false")
            if isActive {
                onDeactivate()
            } else {
                onActivate()
            }
        }
    }
}

#Preview("Active") {
    GroupRowView(
        group: EnvGroup(name: "Python", icon: "🐍", color: "#667eea", variables: [
            EnvVariable(key: "PYTHONPATH", value: "/python", configType: .shellConfig)
        ], isActive: true),
        isActive: true,
        onActivate: {},
        onDeactivate: {}
    )
    .padding()
}

#Preview("Inactive") {
    GroupRowView(
        group: EnvGroup(name: "Java", icon: "☕", color: "#4ec9b0", isActive: false),
        isActive: false,
        onActivate: {},
        onDeactivate: {}
    )
    .padding()
}