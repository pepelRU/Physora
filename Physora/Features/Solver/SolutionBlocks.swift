import SwiftUI

struct SolutionBlock<Content: View>: View {
    let title: String
    let systemImage: String
    var accent: Color = .physoraAccent
    var copyText: String?
    let content: Content

    @State private var copied = false

    init(
        _ title: String,
        systemImage: String,
        accent: Color = .physoraAccent,
        copyText: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accent = accent
        self.copyText = copyText
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 28, height: 28)
                    .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(.headline.weight(.bold))
                    .fontDesign(.rounded)
                Spacer(minLength: 6)
                if let copyText, !copyText.isEmpty {
                    Button {
                        copy(copyText)
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(copied ? Color.physoraMint : Color.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.physoraSurfaceMuted, in: Circle())
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                    .accessibilityLabel("Скопировать раздел «\(title)»")
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .physoraCard(padding: 18, cornerRadius: 24)
        .contextMenu {
            if let copyText, !copyText.isEmpty {
                Button {
                    copy(copyText)
                } label: {
                    Label("Скопировать раздел", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private func copy(_ text: String) {
        guard Clipboard.copy(text) else { return }
        withAnimation(.snappy(duration: 0.2)) { copied = true }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.snappy(duration: 0.2)) { copied = false }
        }
    }
}

struct GivenFindBlock: View {
    let solution: PhysicsSolution

    @ViewBuilder
    var body: some View {
        if !solution.given.isEmpty, !solution.find.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                givenCard
                findCard
            }
        } else if !solution.given.isEmpty {
            givenCard
        } else if !solution.find.isEmpty {
            findCard
        }
    }

    private var givenCard: some View {
        SolutionBlock(
            "Дано",
            systemImage: "text.book.closed",
            copyText: SolutionTextFormatter.givenText(solution)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(solution.given.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 3) {
                        FormulaView(
                            "\(item.symbol) = \(item.value) \(item.unit)",
                            fontSize: 18
                        )
                        if !item.note.isEmpty {
                            Text(item.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private var findCard: some View {
        SolutionBlock(
            "Найти",
            systemImage: "questionmark.circle",
            accent: .physoraMint,
            copyText: SolutionTextFormatter.findText(solution)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(solution.find.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 3) {
                        FormulaView(
                            item.unit.isEmpty
                                ? "\(item.symbol) = ?"
                                : "\(item.symbol) = ? \\; [\(item.unit)]",
                            fontSize: 18
                        )
                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FormulaRows: View {
    let formulas: [FormulaReference]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(formulas.enumerated()), id: \.offset) { index, formula in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(formula.name.isEmpty ? "Формула \(index + 1)" : formula.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 6)
                        FormulaCopyButton("\(formula.name). \(SolutionTextFormatter.formula(formula.expression))")
                    }
                    FormulaView(formula.expression, fontSize: 24)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Color.physoraSurfaceMuted.opacity(0.72),
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                        )
                    if !formula.variables.isEmpty {
                        Text(formula.variables)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !formula.note.isEmpty {
                        Text(formula.note)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if index < formulas.count - 1 {
                    Divider()
                        .overlay(Color.physoraSeparator)
                }
            }
        }
    }
}

struct FormulaCopyButton: View {
    let text: String
    @State private var copied = false

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Button {
            guard Clipboard.copy(text) else { return }
            withAnimation { copied = true }
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                withAnimation { copied = false }
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(copied ? Color.physoraMint : Color.secondary)
                .frame(width: 28, height: 28)
                .background(Color.physoraSurfaceMuted, in: Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(PressableScaleButtonStyle())
        .accessibilityLabel("Скопировать формулу")
    }
}

struct SolutionStepRow: View {
    let index: Int
    let step: SolutionStep
    let isLast: Bool

    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            VStack(spacing: 0) {
                Text("\(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.physoraAccent, in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(Color.physoraAccent.opacity(0.16))
                        .frame(width: 1.5, height: 22)
                        .padding(.vertical, 2)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(step.title)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 6)
                    Button {
                        guard Clipboard.copy(step.copyText) else { return }
                        withAnimation { copied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(1.3))
                            withAnimation { copied = false }
                        }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption2)
                            .foregroundStyle(copied ? Color.physoraMint : Color.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color.physoraSurfaceMuted, in: Circle())
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                    .accessibilityLabel("Скопировать шаг \(index + 1)")
                }
                if !step.explanation.isEmpty {
                    Text(step.explanation)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !step.formula.isEmpty {
                    FormulaView(step.formula, fontSize: 22)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            Color.physoraAccent.opacity(0.055),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
                if !step.calculation.isEmpty {
                    FormulaView(step.calculation, fontSize: 19)
                        .foregroundStyle(.primary)
                }
                if !step.result.isEmpty {
                    FormulaView(step.result, fontSize: 21, foregroundStyle: .physoraAccent)
                }
            }
            .padding(.bottom, isLast ? 0 : 10)
        }
        .contextMenu {
            Button {
                Clipboard.copy(step.copyText)
            } label: {
                Label("Скопировать шаг", systemImage: "doc.on.doc")
            }
        }
    }
}
