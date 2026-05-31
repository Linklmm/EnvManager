import SwiftUI

/// 图标类型
enum IconType {
    case asset      // Assets.xcassets 中的图片
    case sfSymbol   // SF Symbols 系统图标
    case emoji      // 通用 emoji
}

/// 图标分类
enum IconCategory {
    case language    // 编程语言
    case framework   // 框架/工具
    case general     // 通用图标
}

/// 技术图标模型
struct TechIcon: Identifiable, Hashable {
    let id = UUID()
    let name: String           // 显示名称：如 "Java"
    let iconName: String       // Assets 图片名或 SF Symbol 名或 emoji
    let iconType: IconType     // 图片类型
    let category: IconCategory // 分类
    let keywords: [String]     // 搜索关键词

    static func == (lhs: TechIcon, rhs: TechIcon) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// String 扩展 - 检查是否为 emoji
extension String {
    var isEmoji: Bool {
        return self.unicodeScalars.first?.properties.isEmoji == true
    }
}

/// 根据 iconName 推断图标类型
func getIconType(iconName: String) -> IconType {
    // Assets 图片统一以 "icon-" 前缀命名
    if iconName.hasPrefix("icon-") {
        return .asset
    }
    // Emoji：检查是否为 emoji 字符
    if iconName.isEmoji {
        return .emoji
    }
    // 其他为 SF Symbol
    return .sfSymbol
}

/// 所有技术图标列表
let allTechIcons: [TechIcon] = [
    // 编程语言（15个）
    TechIcon(name: "Java", iconName: "icon-java", iconType: .asset, category: .language, keywords: ["java", "jvm", "jdk"]),
    TechIcon(name: "Python", iconName: "icon-python", iconType: .asset, category: .language, keywords: ["python", "py"]),
    TechIcon(name: "JavaScript", iconName: "icon-javascript", iconType: .asset, category: .language, keywords: ["javascript", "js", "node"]),
    TechIcon(name: "TypeScript", iconName: "icon-typescript", iconType: .asset, category: .language, keywords: ["typescript", "ts"]),
    TechIcon(name: "Go", iconName: "icon-go", iconType: .asset, category: .language, keywords: ["go", "golang"]),
    TechIcon(name: "Rust", iconName: "icon-rust", iconType: .asset, category: .language, keywords: ["rust", "rs"]),
    TechIcon(name: "Swift", iconName: "icon-swift", iconType: .asset, category: .language, keywords: ["swift", "apple"]),
    TechIcon(name: "Kotlin", iconName: "icon-kotlin", iconType: .asset, category: .language, keywords: ["kotlin", "kt"]),
    TechIcon(name: "C", iconName: "icon-c", iconType: .asset, category: .language, keywords: ["c", "c语言"]),
    TechIcon(name: "C++", iconName: "icon-cpp", iconType: .asset, category: .language, keywords: ["cpp", "c++", "cplus"]),
    TechIcon(name: "C#", iconName: "icon-csharp", iconType: .asset, category: .language, keywords: ["csharp", "c#", "dotnet"]),
    TechIcon(name: "Ruby", iconName: "icon-ruby", iconType: .asset, category: .language, keywords: ["ruby", "rb"]),
    TechIcon(name: "PHP", iconName: "icon-php", iconType: .asset, category: .language, keywords: ["php"]),
    TechIcon(name: "Scala", iconName: "icon-scala", iconType: .asset, category: .language, keywords: ["scala"]),
    TechIcon(name: "Dart", iconName: "icon-dart", iconType: .asset, category: .language, keywords: ["dart", "flutter"]),

    // 框架/工具（20个）
    TechIcon(name: "React", iconName: "icon-react", iconType: .asset, category: .framework, keywords: ["react", "reactjs", "js"]),
    TechIcon(name: "Vue", iconName: "icon-vue", iconType: .asset, category: .framework, keywords: ["vue", "vuejs"]),
    TechIcon(name: "Angular", iconName: "icon-angular", iconType: .asset, category: .framework, keywords: ["angular", "ng"]),
    TechIcon(name: "Svelte", iconName: "icon-svelte", iconType: .asset, category: .framework, keywords: ["svelte"]),
    TechIcon(name: "Node.js", iconName: "icon-nodejs", iconType: .asset, category: .framework, keywords: ["node", "nodejs", "js"]),
    TechIcon(name: "Spring", iconName: "icon-spring", iconType: .asset, category: .framework, keywords: ["spring", "springboot", "java"]),
    TechIcon(name: "Django", iconName: "icon-django", iconType: .asset, category: .framework, keywords: ["django", "python", "py"]),
    TechIcon(name: "Flask", iconName: "icon-flask", iconType: .asset, category: .framework, keywords: ["flask", "python", "py"]),
    TechIcon(name: "Docker", iconName: "icon-docker", iconType: .asset, category: .framework, keywords: ["docker", "container"]),
    TechIcon(name: "Kubernetes", iconName: "icon-kubernetes", iconType: .asset, category: .framework, keywords: ["kubernetes", "k8s", "kub"]),
    TechIcon(name: "Git", iconName: "icon-git", iconType: .asset, category: .framework, keywords: ["git", "version"]),
    TechIcon(name: "Flutter", iconName: "icon-flutter", iconType: .asset, category: .framework, keywords: ["flutter", "dart"]),
    TechIcon(name: "TensorFlow", iconName: "icon-tensorflow", iconType: .asset, category: .framework, keywords: ["tensorflow", "tf", "ml"]),
    TechIcon(name: "PyTorch", iconName: "icon-pytorch", iconType: .asset, category: .framework, keywords: ["pytorch", "torch", "ml"]),
    TechIcon(name: "Electron", iconName: "icon-electron", iconType: .asset, category: .framework, keywords: ["electron", "js"]),
    TechIcon(name: "Webpack", iconName: "icon-webpack", iconType: .asset, category: .framework, keywords: ["webpack", "bundler"]),
    TechIcon(name: "Nginx", iconName: "icon-nginx", iconType: .asset, category: .framework, keywords: ["nginx", "server"]),
    TechIcon(name: "Redis", iconName: "icon-redis", iconType: .asset, category: .framework, keywords: ["redis", "cache"]),
    TechIcon(name: "MongoDB", iconName: "icon-mongodb", iconType: .asset, category: .framework, keywords: ["mongodb", "mongo", "db"]),
    TechIcon(name: "PostgreSQL", iconName: "icon-postgresql", iconType: .asset, category: .framework, keywords: ["postgresql", "postgres", "pg", "db"]),

    // 通用图标（10个）- SF Symbols 和 emoji
    TechIcon(name: "代码", iconName: "chevron.left.forwardslash.chevron.right", iconType: .sfSymbol, category: .general, keywords: ["code", "coding"]),
    TechIcon(name: "终端", iconName: "terminal", iconType: .sfSymbol, category: .general, keywords: ["terminal", "cmd", "shell"]),
    TechIcon(name: "服务器", iconName: "server.rack", iconType: .sfSymbol, category: .general, keywords: ["server", "backend"]),
    TechIcon(name: "云", iconName: "cloud", iconType: .sfSymbol, category: .general, keywords: ["cloud"]),
    TechIcon(name: "数据库", iconName: "cylinder", iconType: .sfSymbol, category: .general, keywords: ["database", "db"]),
    TechIcon(name: "API", iconName: "arrow.left.arrow.right", iconType: .sfSymbol, category: .general, keywords: ["api"]),
    TechIcon(name: "配置", iconName: "gear", iconType: .sfSymbol, category: .general, keywords: ["config", "settings"]),
    TechIcon(name: "工具", iconName: "wrench.and.screwdriver", iconType: .sfSymbol, category: .general, keywords: ["tool", "dev"]),
    TechIcon(name: "设置", iconName: "\u{2699}\u{fe0f}", iconType: .emoji, category: .general, keywords: ["settings", "config"]),
    TechIcon(name: "开发", iconName: "\u{1f527}", iconType: .emoji, category: .general, keywords: ["dev", "tool"]),
]

/// 按分类获取图标
func getIconsByCategory(_ category: IconCategory) -> [TechIcon] {
    return allTechIcons.filter { $0.category == category }
}

/// 搜索图标
func searchIcons(query: String) -> [TechIcon] {
    if query.isEmpty {
        return allTechIcons
    }
    let lowerQuery = query.lowercased()
    return allTechIcons.filter { icon in
        icon.name.lowercased().contains(lowerQuery) ||
        icon.keywords.contains { $0.contains(lowerQuery) }
    }
}

/// 根据 iconName 获取 TechIcon
func getTechIcon(byIconName: String) -> TechIcon? {
    return allTechIcons.first { $0.iconName == byIconName }
}
