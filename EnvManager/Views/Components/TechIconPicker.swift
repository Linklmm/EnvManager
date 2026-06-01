import SwiftUI
import EnvManagerCore

/// 技术图标选择器组件
struct TechIconPicker: View {
    let currentIcon: String?
    let onSelect: (TechIcon?) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: IconCategory? = nil

    // 网格列配置
    private let columns = Array(repeating: GridItem(.fixed(60), spacing: 8), count: 6)

    // 过滤后的图标
    var filteredIcons: [TechIcon] {
        var result = allTechIcons

        // 搜索过滤
        if !searchText.isEmpty {
            result = searchIcons(query: searchText)
        }

        // 分类过滤
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索图标...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(12)

            Divider()

            // 分类切换按钮
            HStack(spacing: 8) {
                CategoryButton(title: "全部", category: nil, selected: selectedCategory == nil, onTap: {
                    selectedCategory = nil
                })
                CategoryButton(title: "语言", category: .language, selected: selectedCategory == .language, onTap: {
                    selectedCategory = .language
                })
                CategoryButton(title: "框架", category: .framework, selected: selectedCategory == .framework, onTap: {
                    selectedCategory = .framework
                })
                CategoryButton(title: "通用", category: .general, selected: selectedCategory == .general, onTap: {
                    selectedCategory = .general
                })
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // 无图标选项
            Button(action: { onSelect(nil) }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                    Text("不使用图标（显示首字母）")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)

            Divider()

            // 图标网格
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(filteredIcons) { icon in
                        IconCell(
                            icon: icon,
                            isSelected: currentIcon == icon.iconName,
                            onTap: { onSelect(icon) }
                        )
                    }
                }
                .padding(12)
            }
            .frame(minHeight: 200, maxHeight: 300)
        }
        .frame(width: 400)
    }
}

/// 分类按钮
struct CategoryButton: View {
    let title: String
    let category: IconCategory?
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12, weight: selected ? .medium : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(selected ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

/// 图标单元格
struct IconCell: View {
    let icon: TechIcon
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // 图标显示
                switch icon.iconType {
                case .asset:
                    Image(icon.iconName)
                        .resizable()
                        .frame(width: 28, height: 28)
                case .sfSymbol:
                    Image(systemName: icon.iconName)
                        .font(.system(size: 20))
                        .frame(width: 28, height: 28)
                case .emoji:
                    Text(icon.iconName)
                        .font(.system(size: 20))
                        .frame(width: 28, height: 28)
                @unknown default:
                    EmptyView()
                }

                // 名称标签
                Text(icon.name)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 56, height: 56)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(icon.name)
    }
}

#Preview {
    TechIconPicker(currentIcon: "icon-java", onSelect: { _ in })
}

/// 图标显示视图 - 根据 iconName 自动判断类型并渲染
struct TechIconView: View {
    let iconName: String?
    let size: CGFloat
    let groupColor: String
    let groupName: String

    init(iconName: String?, size: CGFloat = 24, groupColor: String = "#667eea", groupName: String = "") {
        self.iconName = iconName
        self.size = size
        self.groupColor = groupColor
        self.groupName = groupName
    }

    var body: some View {
        if let name = iconName, !name.isEmpty {
            let iconType = getIconType(iconName: name)
            switch iconType {
            case .asset:
                Image(name)
                    .resizable()
                    .frame(width: size, height: size)
            case .sfSymbol:
                Image(systemName: name)
                    .font(.system(size: size * 0.8))
                    .frame(width: size, height: size)
            case .emoji:
                Text(name)
                    .font(.system(size: size * 0.8))
                    .frame(width: size, height: size)
            @unknown default:
                EmptyView()
            }
        } else {
            // 无图标：显示首字母圆形背景
            Text(groupName.first?.uppercased() ?? "?")
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundStyle(Color(hex: groupColor))
                .frame(width: size, height: size)
                .background(Color(hex: groupColor).opacity(0.15))
                .clipShape(Circle())
        }
    }
}
