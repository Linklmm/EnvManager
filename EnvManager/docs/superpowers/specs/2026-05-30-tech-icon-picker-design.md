# 专业技术图标选择器设计

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将现有的 emoji 图标选择器替换为专业技术图标选择器，支持编程语言和框架/工具的专业 logo 图标，并提供搜索筛选功能。

**Architecture:** 数据文件 + 视图分离架构。创建独立的图标数据文件存储图标列表，创建独立的视图组件负责 UI 展示和搜索筛选，与现有代码解耦便于维护扩展。

**Tech Stack:** SwiftUI, Assets.xcassets (PNG图片), SF Symbols

---

## 数据结构设计

### TechIcon 模型

```swift
struct TechIcon: Identifiable, Hashable {
    let id = UUID()
    let name: String           // 显示名称：如 "Java"
    let iconName: String       // Assets 图片名或 SF Symbol 名或 emoji
    let iconType: IconType     // 图片类型
    let category: IconCategory // 分类
    let keywords: [String]     // 搜索关键词
}
```

### IconType 枚举

```swift
enum IconType {
    case asset      // Assets.xcassets 中的图片
    case sfSymbol   // SF Symbols 系统图标
    case emoji      // 通用 emoji
}
```

### IconCategory 枚举

```swift
enum IconCategory {
    case language    // 编程语言
    case framework   // 框架/工具
    case general     // 通用图标
}
```

---

## 图标列表

共约 45 个图标，按类别分组。

### 编程语言（15个）

| 名称 | iconName | 搜索关键词 |
|------|----------|------------|
| Java | icon-java | java, jvm, jdk |
| Python | icon-python | python, py |
| JavaScript | icon-javascript | javascript, js, node |
| TypeScript | icon-typescript | typescript, ts |
| Go | icon-go | go, golang |
| Rust | icon-rust | rust, rs |
| Swift | icon-swift | swift, apple |
| Kotlin | icon-kotlin | kotlin, kt |
| C | icon-c | c, c语言 |
| C++ | icon-cpp | cpp, c++, cplus |
| C# | icon-csharp | csharp, c#, dotnet |
| Ruby | icon-ruby | ruby, rb |
| PHP | icon-php | php |
| Scala | icon-scala | scala |
| Dart | icon-dart | dart, flutter |

### 框架/工具（20个）

| 名称 | iconName | 搜索关键词 |
|------|----------|------------|
| React | icon-react | react, reactjs, js |
| Vue | icon-vue | vue, vuejs |
| Angular | icon-angular | angular, ng |
| Svelte | icon-svelte | svelte |
| Node.js | icon-nodejs | node, nodejs, js |
| Spring Boot | icon-spring | spring, springboot, java |
| Django | icon-django | django, python, py |
| Flask | icon-flask | flask, python, py |
| Docker | icon-docker | docker, container |
| Kubernetes | icon-kubernetes | kubernetes, k8s, kub |
| Git | icon-git | git, version |
| Flutter | icon-flutter | flutter, dart |
| TensorFlow | icon-tensorflow | tensorflow, tf, ml |
| PyTorch | icon-pytorch | pytorch, torch, ml |
| Electron | icon-electron | electron, js |
| Webpack | icon-webpack | webpack, bundler |
| Nginx | icon-nginx | nginx, server |
| Redis | icon-redis | redis, cache |
| MongoDB | icon-mongodb | mongodb, mongo, db |
| PostgreSQL | icon-postgresql | postgresql, postgres, pg, db |

### 通用图标（10个）

使用 SF Symbols 和少量 emoji：

| 名称 | iconName | iconType | 搜索关键词 |
|------|----------|----------|------------|
| 代码 | chevron.left.forwardslash.chevron.right | sfSymbol | code, coding |
| 终端 | terminal | sfSymbol | terminal, cmd, shell |
| 服务器 | server.rack | sfSymbol | server, backend |
| 云 | cloud | sfSymbol | cloud |
| 数据库 | database | sfSymbol | database, db |
| API | arrow.left.arrow.right | sfSymbol | api |
| 配置 | gear | sfSymbol | config, settings |
| 工具 | wrench.and.screwdriver | sfSymbol | tool, dev |
| 设置 | ⚙️ | emoji | settings, config |
| 开发 | 🔧 | emoji | dev, tool |

---

## 视图组件设计

### TechIconPicker 组件

**位置：** `EnvManager/Views/Components/TechIconPicker.swift`

**功能：**
- 搜索框实时筛选图标
- 搜索逻辑：匹配 name 和 keywords，忽略大小写
- 网格布局展示图标（6列）
- 每个图标显示图片 + 名称标签
- 点击选中返回 TechIcon
- 提供"无图标"选项（用户可选择不使用图标）

**布局结构：**
```
VStack {
  // 搜索框
  TextField("搜索图标...", text: $searchText)
  
  // 无图标选项
  Button("不使用图标") { ... }
  
  // 图标网格（按类别分区）
  ScrollView {
    LazyVGrid(columns: 6) {
      // 编程语言区域
      Section("编程语言") { ... }
      // 框架/工具区域
      Section("框架/工具") { ... }
      // 通用图标区域
      Section("通用") { ... }
    }
  }
}
```

### 单个图标单元格

```
VStack {
  // 根据 iconType 显示图标
  if iconType == .asset {
    Image(iconName)
  } else if iconType == .sfSymbol {
    Image(systemName: iconName)
  } else {
    Text(iconName)  // emoji
  }
  
  // 名称标签
  Text(name)
}
```

---

## Assets 图片资源

**位置：** `EnvManager/Assets.xcassets/TechIcons/`

需要添加约 35 个 PNG 图片：
- 格式：PNG（推荐 48x48 或 64x64 像素）
- 命名：统一格式 `icon-{name}`，如 `icon-java`, `icon-python`
- 每个 icon 创建对应的 Image Set

**图片来源建议：**
- 官方 logo（如 Oracle Java logo、Python official logo）
- 简洁风格的社区图标（如 Devicons、Simple Icons 系列）
- 确保图片背景透明，便于适配不同主题

---

## 集成方式

### 替换现有代码

1. 删除 `MainWindowView.swift` 中的 `iconOptions` emoji 数组
2. 删除 `MainWindowView.swift` 中的 `IconPickerPopover` 组件
3. 删除 `GroupDetailView` 中重复的 `iconOptions` 和 popover 逻辑
4. 导入并使用 `TechIconPicker`

### 使用方式

```swift
// 在 GroupListRow 和 GroupDetailView 中
@State private var showIconPicker = false

Button(action: { showIconPicker = true }) {
  // 显示当前图标（根据存储的 iconName 判断类型）
}

.popover(isPresented: $showIconPicker) {
  TechIconPicker(
    onSelect: { icon in
      // icon 可为 nil（用户选择无图标）
      if let selectedIcon = icon {
        // 存储 selectedIcon.iconName 到 group.icon
        // 后续显示时需根据 iconName 判断类型
      } else {
        // 清空 group.icon
      }
      showIconPicker = false
    }
  )
}
```

### 图标显示逻辑

**方案：使用命名约定推断类型（推荐，无需修改现有数据模型）**

```swift
// 在 TechIconData.swift 中提供辅助函数
func getIconType(iconName: String) -> IconType {
  // Assets 图片统一以 "icon-" 前缀命名
  if iconName.hasPrefix("icon-") {
    return .asset
  }
  // Emoji：长度为1且为通用表情字符
  if iconName.count == 1 && iconName.containsEmoji {
    return .emoji
  }
  // 其他为 SF Symbol
  return .sfSymbol
}

// String 扩展检查是否为 emoji
extension String {
  var containsEmoji: Bool {
    return self.unicodeScalars.first?.properties.isEmoji == true
  }
}
```

**显示组件：**

```swift
func renderIcon(iconName: String?) -> some View {
  if let name = iconName, !name.isEmpty {
    let type = getIconType(iconName: name)
    switch type {
    case .asset:
      return AnyView(Image(name).resizable().frame(width: 24, height: 24))
    case .sfSymbol:
      return AnyView(Image(systemName: name).font(.system(size: 18)))
    case .emoji:
      return AnyView(Text(name).font(.system(size: 18)))
    }
  } else {
    // 无图标，显示首字母圆形背景
    return AnyView(Text(firstChar).font(.system(size: 14, weight: .semibold))
      .frame(width: 28, height: 28)
      .background(Color(hex: groupColor).opacity(0.15))
      .clipShape(Circle()))
  }
}
```

**命名约定总结：**
- Assets 图片：`icon-{name}` 前缀（如 `icon-java`, `icon-python`）
- SF Symbols：直接使用系统名称（如 `terminal`, `database`）
- Emoji：直接存储 emoji 字符（如 `⚙️`, `🔧`）
```

---

## 文件结构

```
EnvManager/
├── Models/
│   └── TechIconData.swift          # 新增：图标数据模型和列表
├── Views/
│   ├── Components/
│   │   └── TechIconPicker.swift    # 新增：图标选择器组件
│   ├── MainWindow/
│   │   └── MainWindowView.swift    # 修改：替换 popover 使用新组件
│   └── GroupDetailView.swift       # 修改：替换 popover 使用新组件
├── Assets.xcassets/
│   └── TechIcons/                   # 新增：图标图片资源目录
│       ├── icon-java.imageset/
│       ├── icon-python.imageset/
│       ├── ...
```

---

## 测试要点

1. 搜索功能：输入关键词正确筛选图标
2. 分类显示：三个类别区域正确展示
3. 图标渲染：asset/sfSymbol/emoji 三种类型正确显示
4. 选中回调：点击图标正确返回 TechIcon
5. 无图标选项：可选择清空图标
6. 现有集成：GroupListRow 和 GroupDetailView 正确使用新组件
7. 数据持久化：选中图标正确保存和加载