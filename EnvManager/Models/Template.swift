import Foundation

/// 环境变量模板
struct Template: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var variables: [EnvVariable]
    var isBuiltIn: Bool

    /// 创建新模板
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        variables: [EnvVariable] = [],
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.variables = variables
        self.isBuiltIn = isBuiltIn
    }

    /// 将模板应用到新分组
    func applyToGroup(
        name: String,
        icon: String? = nil,
        color: String = "#667eea"
    ) -> EnvGroup {
        // 复制变量（生成新的 UUID）
        let copiedVariables = variables.map { originalVar ->
            EnvVariable in
            EnvVariable(
                key: originalVar.key,
                value: originalVar.value,
                configType: originalVar.configType,
                shellType: originalVar.shellType,
                isSensitive: originalVar.isSensitive,
                description: originalVar.description,
                aliasCommand: originalVar.aliasCommand
            )
        }

        return EnvGroup(
            name: name,
            icon: icon ?? categoryIcon,
            color: color,
            variables: copiedVariables
        )
    }

    /// 获取分类图标
    var categoryIcon: String {
        switch category.lowercased() {
        case "python":
            return "🐍"
        case "node", "nodejs", "node.js":
            return "📦"
        case "java":
            return "☕"
        case "go", "golang":
            return "🔵"
        case "ruby":
            return "💎"
        case "rust":
            return "🦀"
        case "system":
            return "⚙️"
        default:
            return "🔧"
        }
    }

    /// 用于哈希和相等比较
    static func == (lhs: Template, rhs: Template) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}