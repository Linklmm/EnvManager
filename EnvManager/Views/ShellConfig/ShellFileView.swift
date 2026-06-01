import SwiftUI
import EnvManagerCore

/// 解析后的文件内容结构
struct ParsedShellContent {
    var lines: [ParsedLine]

    struct ParsedLine: Identifiable {
        let id = UUID()
        var text: String
        var isInManagedBlock: Bool
        var isMarker: Bool
        var isVariable: Bool
        var isGroupMarker: Bool
    }

    struct ManagedBlock {
        var startIndex: Int
        var endIndex: Int
        var lines: [ParsedLine]
    }
}

/// Shell 文件展示组件（带高亮）
struct ShellFileView: View {
    let content: String
    var isEditable: Bool = false

    @State private var parsedContent: ParsedShellContent = ParsedShellContent(lines: [])
    @State private var managedBlocks: [ParsedShellContent.ManagedBlock] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(parsedContent.lines.enumerated()), id: \.element.id) { index, line in
                    // 检查是否是管理块的开始
                    if let block = managedBlocks.first(where: { $0.startIndex == index }) {
                        // 渲染整个管理块
                        ManagedBlockView(lines: block.lines)
                            .padding(.bottom, 8)
                    } else if !managedBlocks.contains(where: { $0.startIndex <= index && $0.endIndex >= index }) {
                        // 非管理区域的普通行
                        lineView(line)
                    }
                }
            }
            .padding(16)
        }
        .onAppear {
            parseContent()
        }
        .onChange(of: content) { _, _ in
            parseContent()
        }
    }

    private func lineView(_ line: ParsedShellContent.ParsedLine) -> some View {
        let textColor: Color = {
            if line.isInManagedBlock && line.isVariable {
                return .green  // 变量行：绿色
            } else if line.isMarker {
                return .blue   // 标记行：蓝色
            } else {
                return .primary // 普通行
            }
        }()

        return Text(line.text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(textColor)
            .fontWeight(line.isMarker ? .medium : .regular)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parseContent() {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        var parsedLines: [ParsedShellContent.ParsedLine] = []
        var inManagedBlock = false

        for line in lines {
            let lineText = String(line)

            // 检测标记行
            if lineText.contains(Constants.envMarkerBegin) {
                inManagedBlock = true
                parsedLines.append(ParsedShellContent.ParsedLine(
                    text: lineText,
                    isInManagedBlock: true,
                    isMarker: true,
                    isVariable: false,
                    isGroupMarker: false
                ))
            } else if lineText.contains(Constants.envMarkerEnd) {
                parsedLines.append(ParsedShellContent.ParsedLine(
                    text: lineText,
                    isInManagedBlock: true,
                    isMarker: true,
                    isVariable: false,
                    isGroupMarker: false
                ))
                inManagedBlock = false
            } else if inManagedBlock {
                // 管理区域内的行
                let isGroupMarker = lineText.contains(Constants.envMarkerGroupBegin)
                let isVariable = lineText.contains("export ") ||
                                 lineText.contains("alias ") ||
                                 lineText.contains("PATH=") ||
                                 lineText.hasSuffix(";") && (lineText.contains("export ") || lineText.contains("alias "))
                parsedLines.append(ParsedShellContent.ParsedLine(
                    text: lineText,
                    isInManagedBlock: true,
                    isMarker: isGroupMarker,
                    isVariable: isVariable && !isGroupMarker,
                    isGroupMarker: isGroupMarker
                ))
            } else {
                // 普通行
                parsedLines.append(ParsedShellContent.ParsedLine(
                    text: lineText,
                    isInManagedBlock: false,
                    isMarker: false,
                    isVariable: false,
                    isGroupMarker: false
                ))
            }
        }

        parsedContent = ParsedShellContent(lines: parsedLines)

        // 计算管理块并存储
        var blocks: [ParsedShellContent.ManagedBlock] = []
        var currentBlock: ParsedShellContent.ManagedBlock?

        for (index, line) in parsedLines.enumerated() {
            if line.text.contains(Constants.envMarkerBegin) {
                currentBlock = ParsedShellContent.ManagedBlock(startIndex: index, endIndex: index, lines: [line])
            } else if let block = currentBlock {
                currentBlock!.lines.append(line)
                if line.text.contains(Constants.envMarkerEnd) {
                    currentBlock!.endIndex = index
                    blocks.append(currentBlock!)
                    currentBlock = nil
                }
            }
        }

        managedBlocks = blocks
    }
}

/// 管理块视图（带虚线边框）
struct ManagedBlockView: View {
    let lines: [ParsedShellContent.ParsedLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(lines) { line in
                lineView(line)
            }
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1, dash: [4, 2])
                )
                .foregroundColor(Color.blue.opacity(0.6))
        )
        .cornerRadius(4)
    }

    private func lineView(_ line: ParsedShellContent.ParsedLine) -> some View {
        let textColor: Color = {
            if line.isGroupMarker {
                return .purple  // 分组标记：紫色
            } else if line.isVariable {
                return .green   // 变量行：绿色
            } else if line.isMarker {
                return .blue    // Begin/End 标记：蓝色
            } else {
                return .primary // 普通行
            }
        }()

        let fontWeight: Font.Weight = {
            if line.isMarker || line.isGroupMarker {
                return .medium
            } else if line.isVariable {
                return .regular
            } else {
                return .regular
            }
        }()

        return Text(line.text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(textColor)
            .fontWeight(fontWeight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview {
    let sampleContent = """
# ~/.zshrc 配置文件

export PATH="/usr/local/bin:$PATH"

# === EnvManager Begin ===
# EnvManager Group: Python 开发环境
export PYTHONPATH="/Users/demo/projects/python"
export VIRTUAL_ENV="/Users/demo/venv"
alias python="python3"
alias pip="pip3"
# === EnvManager End ===

# 其他配置
export EDITOR="vim"

# === EnvManager Begin ===
# EnvManager Group: Node.js 开发环境
export NODE_PATH="/usr/local/lib/node_modules"
alias npm="npm --registry=https://registry.npmmirror.com"
# === EnvManager End ===
"""

    return ShellFileView(content: sampleContent)
        .frame(width: 600, height: 500)
}