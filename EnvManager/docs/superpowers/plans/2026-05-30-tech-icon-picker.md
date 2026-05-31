# 专业技术图标选择器实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有的 emoji 图标选择器替换为专业技术图标选择器，支持编程语言和框架/工具的专业 logo 图标，并提供搜索筛选功能。

**Architecture:** 数据文件 + 视图分离架构。TechIconData.swift 存储图标数据模型和列表，TechIconPicker.swift 提供搜索筛选网格视图，替换现有 IconPickerPopover 和 iconOptions。

**Tech Stack:** SwiftUI, Assets.xcassets (PNG图片), SF Symbols

---

## 文件结构

**创建文件：**
- `EnvManager/Models/TechIconData.swift` - 图标数据模型和列表
- `EnvManager/Views/Components/TechIconPicker.swift` - 图标选择器组件
- `EnvManager/Resources/Assets.xcassets/TechIcons/*.imageset` - 35个图标图片资源

**修改文件：**
- `EnvManager/Views/MainWindow/MainWindowView.swift` - 替换 IconPickerPopover，修改 GroupListRow、GroupDetailView、NewGroupSheet

---

## Task 1: 创建图标数据模型文件

**Files:**
- Create: `EnvManager/Models/TechIconData.swift`

- [ ] **Step 1: 创建 TechIconData.swift 文件**

```swift
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
    TechIcon(name: "数据库", iconName: "database", iconType: .sfSymbol, category: .general, keywords: ["database", "db"]),
    TechIcon(name: "API", iconName: "arrow.left.arrow.right", iconType: .sfSymbol, category: .general, keywords: ["api"]),
    TechIcon(name: "配置", iconName: "gear", iconType: .sfSymbol, category: .general, keywords: ["config", "settings"]),
    TechIcon(name: "工具", iconName: "wrench.and.screwdriver", iconType: .sfSymbol, category: .general, keywords: ["tool", "dev"]),
    TechIcon(name: "设置", iconName: "⚙️", iconType: .emoji, category: .general, keywords: ["settings", "config"]),
    TechIcon(name: "开发", iconName: "🔧", iconType: .emoji, category: .general, keywords: ["dev", "tool"]),
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
```

- [ ] **Step 2: 验证文件创建成功**

Run: 查看文件是否存在
Expected: 文件已创建在正确位置

---

## Task 2: 创建图标选择器视图组件

**Files:**
- Create: `EnvManager/Views/Components/TechIconPicker.swift`

- [ ] **Step 1: 创建 TechIconPicker.swift 文件**

```swift
import SwiftUI

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
```

- [ ] **Step 2: 验证文件创建成功**

Expected: 文件已创建在正确位置

---

## Task 3: 创建图标显示辅助组件

**Files:**
- Modify: `EnvManager/Views/Components/TechIconPicker.swift` (追加)

- [ ] **Step 1: 在 TechIconPicker.swift 文件末尾添加图标显示视图组件**

```swift
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
```

- [ ] **Step 2: 验证修改成功**

Expected: TechIconView 组件已添加到文件末尾

---

## Task 4: 添加图标图片资源到 Assets

**Files:**
- Create: `EnvManager/Resources/Assets.xcassets/TechIcons/icon-java.imageset/Contents.json` 等 35 个 imageset

**注意：** 由于无法自动下载图片文件，需要手动准备图标图片。以下是需要的图标列表和推荐来源：

- [ ] **Step 1: 创建 TechIcons 文件夹**

在 `Assets.xcassets` 中创建 `TechIcons` 文件夹（通过 Xcode 或手动创建）

- [ ] **Step 2: 准备图标图片文件**

需要准备的 35 个图标图片（PNG格式，推荐 48x48 或 64x64 像素，背景透明）：

| 图标名称 | 建议文件名 | 推荐来源 |
|---------|-----------|---------|
| Java | icon-java.png | https://www.oracle.com/java/ |
| Python | icon-python.png | https://www.python.org/community/logos/ |
| JavaScript | icon-javascript.png | https://github.com/voodootikigod/logo.js |
| TypeScript | icon-typescript.png | https://github.com/remojansen/logo.ts |
| Go | icon-go.png | https://golang.org/solutions/ |
| Rust | icon-rust.png | https://rust-lang.org/ |
| Swift | icon-swift.png | Apple Swift logo |
| Kotlin | icon-kotlin.png | https://kotlinlang.org/docs/ |
| C | icon-c.png | 简化的 C 语言图标 |
| C++ | icon-cpp.png | 简化的 C++ 图标 |
| C# | icon-csharp.png | 简化的 C# 图标 |
| Ruby | icon-ruby.png | https://www.ruby-lang.org/ |
| PHP | icon-php.png | https://www.php.net/ |
| Scala | icon-scala.png | https://scala-lang.org/ |
| Dart | icon-dart.png | https://dart.dev/ |
| React | icon-react.png | https://reactjs.org/community/ |
| Vue | icon-vue.png | https://vuejs.org/ |
| Angular | icon-angular.png | https://angular.io/ |
| Svelte | icon-svelte.png | https://svelte.dev/ |
| Node.js | icon-nodejs.png | https://nodejs.org/ |
| Spring | icon-spring.png | https://spring.io/ |
| Django | icon-django.png | https://www.djangoproject.com/ |
| Flask | icon-flask.png | https://flask.palletsprojects.com/ |
| Docker | icon-docker.png | https://www.docker.com/ |
| Kubernetes | icon-kubernetes.png | https://kubernetes.io/ |
| Git | icon-git.png | https://git-scm.com/downloads/logos |
| Flutter | icon-flutter.png | https://flutter.dev/ |
| TensorFlow | icon-tensorflow.png | https://www.tensorflow.org/ |
| PyTorch | icon-pytorch.png | https://pytorch.org/ |
| Electron | icon-electron.png | https://www.electronjs.org/ |
| Webpack | icon-webpack.png | https://webpack.js.org/ |
| Nginx | icon-nginx.png | https://www.nginx.com/ |
| Redis | icon-redis.png | https://redis.io/ |
| MongoDB | icon-mongodb.png | https://www.mongodb.com/ |
| PostgreSQL | icon-postgresql.png | https://www.postgresql.org/ |

推荐使用 DevIcons 或 Simple Icons 系列的图标，可从以下网站获取：
- https://devicons.github.io/
- https://simpleicons.org/

- [ ] **Step 3: 在 Xcode 中添加图片资源**

在 Xcode 中：
1. 打开 Assets.xcassets
2. 创建 TechIcons 文件夹
3. 为每个图标创建新的 Image Set
4. 将图片文件拖入对应的 Image Set
5. 确保 Image Set 名称与 iconName 匹配（如 "icon-java"）

---

## Task 5: 修改 GroupListRow 使用新图标选择器

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift` (GroupListRow 部分，约第 733-823 行)

- [ ] **Step 1: 删除 GroupListRow 中的 iconOptions 数组**

删除第 743 行：
```swift
let iconOptions = ["🐍", "📦", "☕", "🔵", "💎", "🦀", "⚙️", "🔧", "📱", "🌐"]
```

- [ ] **Step 2: 修改 GroupListRow 的图标显示和 popover**

将第 746-781 行替换为：

```swift
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
```

- [ ] **Step 3: 验证修改成功**

Expected: GroupListRow 使用 TechIconView 和 TechIconPicker

---

## Task 6: 修改 GroupDetailView 使用新图标选择器

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift` (GroupDetailView 部分，约第 188-412 行)

- [ ] **Step 1: 删除 GroupDetailView 中的 iconOptions 数组**

删除第 198 行：
```swift
let iconOptions = ["🐍", "📦", "☕", "🔵", "💎", "🦀", "⚙️", "🔧", "📱", "🌐"]
```

- [ ] **Step 2: 修改 GroupDetailView 的图标显示和 popover**

将第 230-261 行替换为：

```swift
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
```

- [ ] **Step 3: 验证修改成功**

Expected: GroupDetailView 使用 TechIconView 和 TechIconPicker

---

## Task 7: 修改 NewGroupSheet 使用新图标选择器

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift` (NewGroupSheet 部分，约第 917-999 行)

- [ ] **Step 1: 删除 NewGroupSheet 中的 iconOptions 数组**

删除第 926 行：
```swift
let iconOptions = ["🐍", "📦", "☕", "🔵", "💎", "🦀", "⚙️", "🔧", "📱", "🌐"]
```

- [ ] **Step 2: 添加 showIconPicker 状态和修改图标选择区域**

在 NewGroupSheet 结构体中添加状态：
```swift
@State private var showIconPicker = false
```

将图标选择区域（约第 944-961 行）替换为：

```swift
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
```

- [ ] **Step 3: 验证修改成功**

Expected: NewGroupSheet 使用 TechIconPicker 弹窗选择图标

---

## Task 8: 删除旧的 IconPickerPopover 组件

**Files:**
- Modify: `EnvManager/Views/MainWindow/MainWindowView.swift` (删除 IconPickerPopover，约第 825-858 行)

- [ ] **Step 1: 删除 IconPickerPopover 结构体**

删除第 825-858 行的整个 IconPickerPopover 结构体：

```swift
/// 图标选择器弹窗
struct IconPickerPopover: View {
    ... // 删除整个结构体
}
```

- [ ] **Step 2: 验证删除成功**

Expected: IconPickerPopover 已完全删除，代码中不再引用

---

## Task 9: 构建并测试

- [ ] **Step 1: 构建项目**

Run: `xcodebuild -project EnvManager.xcodeproj -scheme EnvManager -configuration Debug build`
Expected: BUILD SUCCEEDED（如有 Assets 图片缺失警告可暂时忽略）

- [ ] **Step 2: 运行应用并测试**

测试要点：
1. 打开应用，查看分组列表图标显示是否正常
2. 点击分组图标，检查 TechIconPicker 弹窗是否显示
3. 测试搜索功能：输入 "java" 或 "python"
4. 测试分类切换：点击"语言"、"框架"、"通用"按钮
5. 选择图标后检查是否正确保存
6. 测试"不使用图标"选项
7. 进入分组详情页，测试图标选择功能
8. 测试新建分组时的图标选择功能

- [ ] **Step 3: 修复任何编译错误**

如果 Assets 图片资源未添加，可能会出现图片加载失败。此时图标显示为空白，但不影响功能测试。

---

## 自检清单

**1. Spec 覆盖检查：**
- ✅ TechIconData.swift - 数据模型和图标列表已定义
- ✅ TechIconPicker.swift - 搜索筛选网格视图组件已定义
- ✅ TechIconView - 图标显示辅助组件已定义
- ✅ Assets 图片资源 - 已列出需要准备的图标清单
- ✅ GroupListRow - 已替换为新组件
- ✅ GroupDetailView - 已替换为新组件
- ✅ NewGroupSheet - 已替换为新组件
- ✅ IconPickerPopover - 已删除

**2. Placeholder 检查：**
- 无 TBD、TODO 或占位符
- 所有代码步骤包含完整代码

**3. 类型一致性检查：**
- TechIcon.iconName 为 String，存储时使用 icon.iconName
- onSelect 回调参数为 TechIcon?
- TechIconView 接收 iconName: String?

---

## 注意事项

1. **Assets 图片资源需要手动准备** - 计划列出了推荐来源，开发者需要自行下载并添加到 Xcode

2. **SF Symbols 可直接使用** - macOS 内置的系统图标无需额外资源

3. **Emoji 可直接使用** - 保留的 emoji 图标直接存储字符即可

4. **命名约定重要** - Assets 图片必须使用 `icon-` 前缀命名，以便 getIconType 正确推断类型