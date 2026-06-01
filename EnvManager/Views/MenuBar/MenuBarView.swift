import SwiftUI
import EnvManagerCore

/// 菜单栏弹出视图
struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HeaderView(
                title: "环境管理",
                activeGroup: viewModel.activeGroupName
            )

            Divider()

            // 分组列表
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.groups.isEmpty {
                EmptyGroupsView()
            } else {
                MenuBarGroupListView(viewModel: viewModel)
            }

            Divider()

            // 底部操作栏
            FooterView(onOpenMain: { viewModel.openMainWindow() })
        }
        .frame(width: 260)
    }
}

/// 标题栏
struct HeaderView: View {
    let title: String
    let activeGroup: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            if let group = activeGroup {
                Text("当前: \(group)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// 分组列表（菜单栏专用）
struct MenuBarGroupListView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.groups) { group in
                    GroupRowView(
                        group: group,
                        isActive: group.id == viewModel.activeGroupId,
                        onActivate: {
                            Task { await viewModel.switchGroup(id: group.id) }
                        },
                        onDeactivate: {
                            Task { await viewModel.deactivateGroup() }
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 300)
    }
}

/// 空分组视图
struct EmptyGroupsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("暂无分组")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Text("打开主窗口创建分组")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
    }
}

/// 加载视图
struct LoadingView: View {
    var body: some View {
        ProgressView()
            .frame(height: 100)
    }
}

/// 底部栏
struct FooterView: View {
    let onOpenMain: () -> Void

    var body: some View {
        Button(action: onOpenMain) {
            HStack {
                Image(systemName: "window.shade.open.from.right")
                Text("打开完整配置")
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MenuBarView(viewModel: MenuBarViewModel(envService: EnvService()))
}