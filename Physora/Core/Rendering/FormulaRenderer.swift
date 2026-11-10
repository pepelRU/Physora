import SwiftUI

// MARK: - Math AST

indirect enum MathNode: Equatable, Sendable {
    case text(String)
    case space(Double)
    case sequence([MathNode])
    case fraction(numerator: MathNode, denominator: MathNode)
    case root(index: MathNode?, radicand: MathNode)
    case power(base: MathNode, exponent: MathNode)
    case subscriptNode(base: MathNode, sub: MathNode)
    case vector(MathNode)
    case overline(MathNode)
}

// MARK: - Parser

struct MathParser {
    private let characters: [Character]
    private var index = 0
    private var depth = 0
    private let maximumDepth = 32
    private let maximumLength = 4_000

    init(_ expression: String) {
        self.characters = Array(MathNormalizer.normalize(expression).prefix(maximumLength))
    }

    static func parse(_ expression: String) -> [MathNode] {
        var parser = MathParser(expression)
        return parser.parseSequence(stop: nil)
    }

    static func plainText(_ expression: String) -> String {
        MathPlainText.string(from: parse(expression))
    }

    private mutating func parseSequence(stop: Character?) -> [MathNode] {
        guard depth < maximumDepth else {
            let rest = String(characters[index...])
            index = characters.count
            return rest.isEmpty ? [] : [.text(rest)]
        }
        var nodes: [MathNode] = []

        while index < characters.count {
            let character = characters[index]
            if let stop, character == stop { break }
            if character == "}" { break }

            if character.isWhitespace {
                index += 1
                if let lastNode = nodes.last, case .space = lastNode { continue }
                nodes.append(.space(0.30))
                continue
            }

            if character == "^" || character == "_" {
                index += 1
                let operand = parseScriptOperand()
                if let base = nodes.popLast() {
                    nodes.append(character == "^"
                        ? .power(base: base, exponent: operand)
                        : .subscriptNode(base: base, sub: operand))
                }
                continue
            }

            if character == "{" {
                index += 1
                depth += 1
                let group = parseSequence(stop: "}")
                if index < characters.count, characters[index] == "}" { index += 1 }
                depth -= 1
                if group.count == 1, let only = group.first {
                    nodes.append(only)
                } else if !group.isEmpty {
                    nodes.append(.sequence(group))
                }
                continue
            }

            let indexBeforeAtom = index
            if let node = parseAtomWithScripts() {
                nodes.append(node)
            } else if index == indexBeforeAtom {
                index += 1
            }
        }
        return nodes
    }

    private mutating func parseAtomWithScripts() -> MathNode? {
        guard let first = parseAtomic() else { return nil }
        var node = first
        while index < characters.count, characters[index] == "^" || characters[index] == "_" {
            let operation = characters[index]
            index += 1
            let operand = parseScriptOperand()
            node = operation == "^"
                ? .power(base: node, exponent: operand)
                : .subscriptNode(base: node, sub: operand)
        }
        return node
    }

    private mutating func parseAtomic() -> MathNode? {
        guard index < characters.count else { return nil }
        let character = characters[index]

        if character == "\\" {
            return parseCommand()
        }
        if character == "{" {
            index += 1
            depth += 1
            let group = parseSequence(stop: "}")
            if index < characters.count, characters[index] == "}" { index += 1 }
            depth -= 1
            return group.count == 1 ? group[0] : .sequence(group)
        }
        if character == "^" || character == "_" || character == "}" || character.isWhitespace {
            return nil
        }

        let start = index
        while index < characters.count {
            let current = characters[index]
            if current == "\\" || current == "{" || current == "}" || current == "^"
                || current == "_" || current.isWhitespace {
                break
            }
            index += 1
        }
        guard start < index else { return nil }
        return .text(String(characters[start..<index]))
    }

    private mutating func parseScriptOperand() -> MathNode {
        while index < characters.count, characters[index].isWhitespace { index += 1 }
        if index < characters.count, characters[index] == "{" {
            return parseGroup()
        }
        if let atom = parseAtomic() {
            return atom
        }
        return .text("")
    }

    private mutating func parseGroup() -> MathNode {
        while index < characters.count, characters[index].isWhitespace { index += 1 }
        if index < characters.count, characters[index] == "{" {
            index += 1
            depth += 1
            let nodes = parseSequence(stop: "}")
            if index < characters.count, characters[index] == "}" { index += 1 }
            depth -= 1
            if nodes.count == 1, let only = nodes.first {
                return only
            }
            return .sequence(nodes)
        }
        return parseAtomic() ?? .text("")
    }

    private mutating func parseCommand() -> MathNode? {
        index += 1 // backslash
        guard index < characters.count else { return nil }

        let start = index
        if characters[index].isLetter {
            while index < characters.count, characters[index].isLetter { index += 1 }
        } else {
            index += 1
        }
        let name = String(characters[start..<index])

        switch name {
        case "frac", "dfrac", "tfrac", "cfrac":
            let numerator = parseGroup()
            let denominator = parseGroup()
            return .fraction(numerator: numerator, denominator: denominator)
        case "sqrt":
            var rootIndex: MathNode?
            skipSpaces()
            if index < characters.count, characters[index] == "[" {
                index += 1
                let indexStart = index
                while index < characters.count, characters[index] != "]" {
                    index += 1
                }
                let rawIndex = String(characters[indexStart..<index])
                if index < characters.count, characters[index] == "]" { index += 1 }
                let trimmed = rawIndex.trimmingCharacters(in: .whitespacesAndNewlines)
                rootIndex = trimmed.isEmpty ? nil : .text(trimmed)
            }
            let radicand = parseGroup()
            return .root(index: rootIndex, radicand: radicand)
        case "text", "textrm", "mathrm", "mathbf", "mathit", "operatorname", "textnormal":
            let raw = parseRawGroup()
            return .text(raw)
        case "vec":
            return .vector(parseGroup())
        case "overline", "bar":
            return .overline(parseGroup())
        case "hat":
            return .text(MathPlainText.string(from: [parseGroup()]) + "\u{0302}")
        case "left", "right", "big", "Big", "bigg", "Bigg", "middle",
             "displaystyle", "textstyle", "scriptstyle", "scriptscriptstyle",
             "limits", "nolimits", "begin", "end":
            skipSpaces()
            if index < characters.count, characters[index] == "." {
                index += 1
            }
            return nil
        case "quad":
            return .space(1.0)
        case "qquad":
            return .space(1.8)
        case ",", ";", ":", " ":
            return .space(name == "," ? 0.18 : 0.34)
        case "!":
            return .space(0.02)
        case "\\":
            return .space(0.8)
        case "%", "#", "&", "_", "{", "}":
            return .text(name)
        default:
            if let symbol = MathSymbols.commands[name] {
                return .text(symbol)
            }
            return nil
        }
    }

    private mutating func parseRawGroup() -> String {
        skipSpaces()
        guard index < characters.count, characters[index] == "{" else { return "" }
        index += 1
        var level = 1
        let start = index
        while index < characters.count {
            let character = characters[index]
            if character == "\\" {
                index += min(2, characters.count - index)
                continue
            }
            if character == "{" { level += 1 }
            if character == "}" {
                level -= 1
                if level == 0 {
                    let value = String(characters[start..<index])
                    index += 1
                    return value
                }
            }
            index += 1
        }
        return String(characters[start...])
    }

    private mutating func skipSpaces() {
        while index < characters.count, characters[index].isWhitespace { index += 1 }
    }
}

// MARK: - Normalization and symbols

enum MathNormalizer {
    private static let superscriptMap: [Character: Character] = [
        "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4",
        "⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9",
        "⁺": "+", "⁻": "-", "⁼": "=", "⁽": "(", "⁾": ")",
        "ⁿ": "n", "ⁱ": "i"
    ]

    private static let subscriptMap: [Character: Character] = [
        "₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4",
        "₅": "5", "₆": "6", "₇": "7", "₈": "8", "₉": "9",
        "₊": "+", "₋": "-", "₌": "=", "₍": "(", "₎": ")",
        "ₐ": "a", "ₑ": "e", "ₒ": "o", "ₓ": "x", "ₕ": "h",
        "ₖ": "k", "ₗ": "l", "ₘ": "m", "ₙ": "n", "ₚ": "p",
        "ₛ": "s", "ₜ": "t"
    ]

    static func normalize(_ raw: String) -> String {
        var value = raw
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "\\[", with: "")
            .replacingOccurrences(of: "\\]", with: "")
            .replacingOccurrences(of: "$$", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "\\left.", with: "")
            .replacingOccurrences(of: "\\right.", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        value = normalizeScripts(value)
        value = value.replacingOccurrences(of: "**", with: "·")
        return value
    }

    /// Converts Unicode superscripts/subscripts (м/с², 10⁻³, m₀) into the
    /// parser's explicit script syntax so exponents are always rendered by the
    /// math view instead of depending on font glyph coverage.
    private static func normalizeScripts(_ value: String) -> String {
        var result = ""
        var index = value.startIndex
        while index < value.endIndex {
            let character = value[index]
            if let mapped = superscriptMap[character] {
                result.append("^")
                result.append(mapped)
                index = value.index(after: index)
                while index < value.endIndex, let next = superscriptMap[value[index]] {
                    result.append(next)
                    index = value.index(after: index)
                }
                continue
            }
            if let mapped = subscriptMap[character] {
                result.append("_")
                result.append(mapped)
                index = value.index(after: index)
                while index < value.endIndex, let next = subscriptMap[value[index]] {
                    result.append(next)
                    index = value.index(after: index)
                }
                continue
            }
            result.append(character)
            index = value.index(after: index)
        }
        return result
    }
}

enum MathSymbols {
    static let commands: [String: String] = [
        "alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ", "epsilon": "ε",
        "varepsilon": "ε", "zeta": "ζ", "eta": "η", "theta": "θ", "vartheta": "ϑ",
        "iota": "ι", "kappa": "κ", "lambda": "λ", "mu": "μ", "nu": "ν", "xi": "ξ",
        "omicron": "ο", "pi": "π", "varpi": "ϖ", "rho": "ρ", "varrho": "ϱ",
        "sigma": "σ", "varsigma": "ς", "tau": "τ", "upsilon": "υ", "phi": "φ",
        "varphi": "ϕ", "chi": "χ", "psi": "ψ", "omega": "ω",
        "Gamma": "Γ", "Delta": "Δ", "Theta": "Θ", "Lambda": "Λ", "Xi": "Ξ",
        "Pi": "Π", "Sigma": "Σ", "Upsilon": "Υ", "Phi": "Φ", "Psi": "Ψ", "Omega": "Ω",
        "cdot": "·", "times": "×", "div": "÷", "pm": "±", "mp": "∓",
        "approx": "≈", "neq": "≠", "ne": "≠", "equiv": "≡", "sim": "∼",
        "leq": "≤", "le": "≤", "geq": "≥", "ge": "≥", "ll": "≪", "gg": "≫",
        "propto": "∝", "infty": "∞", "partial": "∂", "nabla": "∇",
        "degree": "°", "textdegree": "°", "circ": "∘", "sum": "Σ",
        "prod": "∏", "int": "∫", "dots": "…", "ldots": "…", "cdots": "⋯",
        "therefore": "∴", "because": "∵", "perp": "⊥", "parallel": "∥",
        "angle": "∠", "triangle": "△", "rightarrow": "→", "to": "→",
        "leftarrow": "←", "Rightarrow": "⇒", "Leftarrow": "⇐",
        "Leftrightarrow": "⇔", "leftrightarrow": "↔", "mapsto": "↦",
        "sin": "sin", "cos": "cos", "tan": "tan", "cot": "cot", "sec": "sec",
        "csc": "csc", "arcsin": "arcsin", "arccos": "arccos", "arctan": "arctan",
        "sinh": "sinh", "cosh": "cosh", "tanh": "tanh", "log": "log", "ln": "ln",
        "exp": "exp", "max": "max", "min": "min", "lim": "lim",
        "ell": "ℓ", "hbar": "ħ", "micro": "μ", "ohm": "Ω", "prime": "′",
        "dagger": "†", "star": "⋆", "bullet": "•"
    ]
}

// MARK: - Plain text for copying and PDF

enum MathPlainText {
    static func string(from nodes: [MathNode]) -> String {
        nodes.map { render($0) }.joined()
    }

    static func render(_ node: MathNode) -> String {
        switch node {
        case .text(let text):
            return text
        case .space:
            return " "
        case .sequence(let nodes):
            return string(from: nodes)
        case .fraction(let numerator, let denominator):
            return "(\(render(numerator)))/(\(render(denominator)))"
        case .root(let index, let radicand):
            if let index {
                let renderedIndex = render(index)
                let prefix = toSuperscript(renderedIndex) ?? renderedIndex
                return "\(prefix)√(\(render(radicand)))"
            }
            return "√(\(render(radicand)))"
        case .power(let base, let exponent):
            let baseText = render(base)
            let exponentText = render(exponent)
            if exponentText.count <= 8, let superscript = toSuperscript(exponentText) {
                return baseText + superscript
            }
            return "\(baseText)^(\(exponentText))"
        case .subscriptNode(let base, let sub):
            let baseText = render(base)
            let subText = render(sub)
            if subText.count <= 8, let subscriptText = toSubscript(subText) {
                return baseText + subscriptText
            }
            return "\(baseText)_(\(subText))"
        case .vector(let value):
            let rendered = render(value)
            return rendered + "\u{20D7}"
        case .overline(let value):
            return render(value)
        }
    }

    private static func toSuperscript(_ string: String) -> String? {
        let map: [Character: Character] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵",
            "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "+": "⁺", "-": "⁻",
            "=": "⁼", "(": "⁽", ")": "⁾", "n": "ⁿ", "i": "ⁱ", "x": "ˣ"
        ]
        var result = ""
        for character in string {
            guard let mapped = map[character] else { return nil }
            result.append(mapped)
        }
        return result
    }

    private static func toSubscript(_ string: String) -> String? {
        let map: [Character: Character] = [
            "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅",
            "6": "₆", "7": "₇", "8": "₈", "9": "₉", "+": "₊", "-": "₋",
            "=": "₌", "(": "₍", ")": "₎", "a": "ₐ", "e": "ₑ", "h": "ₕ",
            "i": "ᵢ", "j": "ⱼ", "k": "ₖ", "l": "ₗ", "m": "ₘ", "n": "ₙ",
            "o": "ₒ", "p": "ₚ", "r": "ᵣ", "s": "ₛ", "t": "ₜ", "u": "ᵤ",
            "v": "ᵥ", "x": "ₓ"
        ]
        var result = ""
        for character in string {
            guard let mapped = map[character] else { return nil }
            result.append(mapped)
        }
        return result
    }
}

// MARK: - SwiftUI rendering

struct FormulaView: View {
    let expression: String
    var fontSize: CGFloat = 21
    var foregroundStyle: Color = .primary
    var centersWhenFits: Bool = false

    @ScaledMetric(relativeTo: .body) private var scaledFontSize: CGFloat = 21
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        _ expression: String,
        fontSize: CGFloat = 21,
        foregroundStyle: Color = .primary,
        centersWhenFits: Bool = false
    ) {
        self.expression = expression
        self.fontSize = fontSize
        self.foregroundStyle = foregroundStyle
        self.centersWhenFits = centersWhenFits
        _scaledFontSize = ScaledMetric(wrappedValue: fontSize, relativeTo: .body)
    }

    private var nodes: [MathNode] { MathParser.parse(expression) }

    var body: some View {
        if expression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            EmptyView()
        } else {
            ViewThatFits(in: .horizontal) {
                mathContent(size: resolvedSize)
                mathContent(size: max(10, resolvedSize * 0.90))
                mathContent(size: max(10, resolvedSize * 0.80))
                mathContent(size: max(10, resolvedSize * 0.70))
                mathContent(size: max(10, resolvedSize * 0.60))
                ScrollView(.horizontal) {
                    mathContent(size: resolvedSize)
                }
                .scrollIndicators(.hidden)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(MathParser.plainText(expression))
            .accessibilityAddTraits(.isStaticText)
        }
    }

    private func mathContent(size: CGFloat) -> some View {
        MathNodesView(
            nodes: nodes,
            size: size,
            color: foregroundStyle
        )
        .padding(.vertical, 3)
        .padding(.horizontal, 1)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var resolvedSize: CGFloat {
        let clamp: CGFloat = dynamicTypeSize.isAccessibilitySize ? 26 : 34
        return min(max(scaledFontSize, 13), clamp)
    }
}

private struct MathNodesView: View {
    let nodes: [MathNode]
    let size: CGFloat
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
                MathNodeView(node: node, size: size, color: color)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct MathNodeView: View {
    let node: MathNode
    let size: CGFloat
    let color: Color

    var body: some View {
        switch node {
        case .text(let text):
            Text(text)
                .font(.system(size: size, weight: .regular, design: .serif))
                .foregroundStyle(color)
                .fixedSize()
        case .space(let multiplier):
            Color.clear
                .frame(width: size * CGFloat(multiplier), height: 1)
        case .sequence(let nodes):
            HStack(alignment: .center, spacing: 0) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { _, child in
                    MathNodeView(node: child, size: size, color: color)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        case .fraction(let numerator, let denominator):
            VStack(spacing: max(1, size * 0.08)) {
                MathNodeView(node: numerator, size: size * 0.82, color: color)
                RoundedRectangle(cornerRadius: 0.5, style: .continuous)
                    .fill(color)
                    .frame(height: max(1, size * 0.055))
                    .frame(minWidth: size * 0.65)
                MathNodeView(node: denominator, size: size * 0.82, color: color)
            }
            .padding(.horizontal, size * 0.08)
            .fixedSize()
        case .root(let index, let radicand):
            HStack(alignment: .center, spacing: size * 0.03) {
                if let index {
                    MathNodeView(node: index, size: size * 0.55, color: color)
                        .offset(y: -size * 0.27)
                }
                Text("√")
                    .font(.system(size: size * 1.08, weight: .regular, design: .serif))
                    .foregroundStyle(color)
                VStack(spacing: 1) {
                    Rectangle()
                        .fill(color.opacity(0.75))
                        .frame(height: max(0.8, size * 0.035))
                    MathNodeView(node: radicand, size: size, color: color)
                        .padding(.horizontal, size * 0.05)
                }
            }
            .fixedSize()
        case .power(let base, let exponent):
            HStack(alignment: .center, spacing: size * 0.02) {
                MathNodeView(node: base, size: size, color: color)
                MathNodeView(node: exponent, size: size * 0.60, color: color)
                    .offset(y: -size * 0.34)
            }
            .fixedSize()
        case .subscriptNode(let base, let sub):
            HStack(alignment: .center, spacing: size * 0.015) {
                MathNodeView(node: base, size: size, color: color)
                MathNodeView(node: sub, size: size * 0.58, color: color)
                    .offset(y: size * 0.32)
            }
            .fixedSize()
        case .vector(let value):
            VStack(spacing: -size * 0.10) {
                Image(systemName: "arrow.right")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(color)
                MathNodeView(node: value, size: size, color: color)
            }
            .fixedSize()
        case .overline(let value):
            VStack(spacing: size * 0.02) {
                Rectangle()
                    .fill(color.opacity(0.8))
                    .frame(height: max(0.8, size * 0.035))
                MathNodeView(node: value, size: size, color: color)
            }
            .fixedSize()
        }
    }
}
