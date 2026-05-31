import Foundation

/// 模板服务 - 管理环境变量模板
actor TemplateService {
    private var builtInTemplates: [Template] = []

    /// 初始化
    init() {
        builtInTemplates = createBuiltInTemplates()
    }

    /// 获取内置模板
    func getBuiltInTemplates() -> [Template] {
        return builtInTemplates
    }

    /// 获取指定分类的模板
    func getTemplate(category: String) -> Template? {
        return builtInTemplates.first { $0.category == category }
    }

    /// 应用模板创建分组
    func applyTemplate(_ template: Template, name: String, icon: String? = nil, color: String = "#667eea") -> EnvGroup {
        return template.applyToGroup(name: name, icon: icon, color: color)
    }

    /// 创建内置模板
    private func createBuiltInTemplates() -> [Template] {
        return [
            createPythonTemplate(),
            createJavaTemplate(),
            createNodeTemplate(),
            createGoTemplate(),
            createSystemTemplate()
        ]
    }

    private func createPythonTemplate() -> Template {
        let variables = [
            EnvVariable(key: "PYTHONPATH", value: "/usr/local/lib/python3.9", configType: .envVariable, shellType: .zsh, description: "Python 库路径"),
            EnvVariable(key: "PYTHONHOME", value: "/usr/local", configType: .envVariable, shellType: .zsh, description: "Python 安装目录"),
        ]
        return Template(name: "Python 开发环境", category: "Python", variables: variables, isBuiltIn: true)
    }

    private func createJavaTemplate() -> Template {
        let variables = [
            EnvVariable(key: "JAVA_HOME", value: "/usr/lib/jvm/java-17", configType: .envVariable, shellType: .zsh, description: "Java 安装目录"),
            EnvVariable(value: "$JAVA_HOME/bin", configType: .path, shellType: .zsh, description: "添加 Java 到 PATH"),
        ]
        return Template(name: "Java 开发环境", category: "Java", variables: variables, isBuiltIn: true)
    }

    private func createNodeTemplate() -> Template {
        let variables = [
            EnvVariable(key: "NODE_HOME", value: "/usr/local/node", configType: .envVariable, shellType: .zsh, description: "Node.js 安装目录"),
            EnvVariable(value: "$NODE_HOME/bin", configType: .path, shellType: .zsh, description: "添加 Node.js 到 PATH"),
        ]
        return Template(name: "Node.js 开发环境", category: "Node.js", variables: variables, isBuiltIn: true)
    }

    private func createGoTemplate() -> Template {
        let variables = [
            EnvVariable(key: "GOROOT", value: "/usr/local/go", configType: .envVariable, shellType: .zsh, description: "Go 安装目录"),
            EnvVariable(key: "GOPATH", value: "~/go", configType: .envVariable, shellType: .zsh, description: "Go 工作空间"),
            EnvVariable(value: "$GOROOT/bin:$GOPATH/bin", configType: .path, shellType: .zsh, description: "添加 Go 到 PATH"),
        ]
        return Template(name: "Go 开发环境", category: "Go", variables: variables, isBuiltIn: true)
    }

    private func createSystemTemplate() -> Template {
        let variables = [
            EnvVariable(key: "LANG", value: "en_US.UTF-8", configType: .launchctl, description: "系统语言"),
            EnvVariable(key: "LC_ALL", value: "en_US.UTF-8", configType: .launchctl, description: "系统编码"),
        ]
        return Template(name: "系统基础环境", category: "System", variables: variables, isBuiltIn: true)
    }
}