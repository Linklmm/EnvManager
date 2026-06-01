import SwiftUI
import EnvManagerCore

/// 配置大类枚举
enum ConfigCategory: String, CaseIterable {
    case shellConfig    // Shell 配置
    case systemConfig   // 系统配置

    var displayName: String {
        switch self {
        case .shellConfig: return "Shell 配置"
        case .systemConfig: return "系统配置"
        }
    }

    var icon: String {
        switch self {
        case .shellConfig: return "terminal"
        case .systemConfig: return "gear"
        }
    }

    /// 该分类下的配置类型
    var configTypes: [ConfigType] {
        switch self {
        case .shellConfig:
            return [.envVariable, .shellConfig, .path, .alias]
        case .systemConfig:
            return [.launchctl]
        }
    }
}

/// 配置类型选择器组件 - 两个独立选择器
struct ConfigTypePicker: View {
    @Binding var selectedType: ConfigType

    // 根据当前选择的类型推断分类
    private var selectedCategory: ConfigCategory {
        selectedType.isShellConfig ? .shellConfig : .systemConfig
    }

    // 当前分类下的可选类型
    private var availableTypes: [ConfigType] {
        selectedCategory.configTypes
    }

    var body: some View {
        VStack(spacing: 12) {
            // 第一个选择器：配置大类
            VStack(alignment: .leading, spacing: 4) {
                Text("配置来源")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    ForEach(ConfigCategory.allCases, id: \.self) { category in
                        Button(action: {
                            // 切换分类时，选择该分类的第一个类型
                            selectedType = category.configTypes.first!
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 12))
                                Text(category.displayName)
                                    .font(.system(size: 13, weight: selectedCategory == category ? .medium : .regular))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(selectedCategory == category ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedCategory == category ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 第二个选择器：具体配置类型
            VStack(alignment: .leading, spacing: 4) {
                Text("配置类型")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Menu {
                    ForEach(availableTypes, id: \.self) { type in
                        Button(action: { selectedType = type }) {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedType.icon)
                            .foregroundColor(.accentColor)
                        Text(selectedType.displayName)
                            .font(.system(size: 13))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderedButton)
            }
        }
    }
}

#Preview {
    ConfigTypePicker(selectedType: .constant(.envVariable))
}
