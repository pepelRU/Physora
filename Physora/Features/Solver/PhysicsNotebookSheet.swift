import SwiftUI

/// A compact, school-notebook style solution. The same sheet is reused in the
/// chat and on the dedicated solution screen so both representations stay
/// identical.
struct PhysicsNotebookSheet: View {
    let solution: PhysicsSolution
    var compact: Bool = true

    @Environment(AppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesStackedLayout: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(spacing: 0) {
            if usesStackedLayout {
                stackedColumns
            } else {
                columns
            }

            if appState.showSeparateFormulas, !solution.formulas.isEmpty {
                Divider().overlay(Color.physoraSeparator)
                separateFormulas
            }

            if appState.showSeparateCalculations, !solution.calculations.isEmpty {
                Divider().overlay(Color.physoraSeparator)
                separateCalculations
            }

            if !solution.diagrams.isEmpty {
                Divider().overlay(Color.physoraSeparator)
                diagramsBlock
            }

            if !solution.graphs.isEmpty {
                Divider().overlay(Color.physoraSeparator)
                graphsBlock
            }

            Divider().overlay(Color.physoraSeparator)
            answerBlock

            if !solution.warnings.isEmpty {
                Divider().overlay(Color.physoraSeparator)
                warningsBlock
            }
        }
        .background(Color.physoraSurface)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 20 : 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 20 : 24, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }

    // MARK: - Three-column notebook grid

    private var columns: some View {
        HStack(alignment: .top, spacing: 0) {
            givenColumn
                .padding(.horizontal, 10)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            Divider().overlay(Color.physoraSeparator)

            siColumn
                .padding(.horizontal, 10)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            Divider().overlay(Color.physoraSeparator)

            solutionColumn
                .padding(.horizontal, 10)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var stackedColumns: some View {
        VStack(alignment: .leading, spacing: 0) {
            givenColumn.padding(14)
            Divider().overlay(Color.physoraSeparator)
            siColumn.padding(14)
            Divider().overlay(Color.physoraSeparator)
            solutionColumn.padding(14)
        }
    }

    private var givenColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            notebookHeader("Дано")
            if solution.given.isEmpty {
                notebookEmpty("—")
            } else {
                ForEach(Array(solution.given.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 1) {
                        FormulaView(
                            quantityText(symbol: item.symbol, value: item.value, unit: item.unit),
                            fontSize: compact ? 13 : 17
                        )
                        if appState.showExtraExplanations, !item.note.isEmpty {
                            Text(item.note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Divider().overlay(Color.physoraSeparator)

            notebookHeader("Найти")
            if solution.find.isEmpty {
                notebookEmpty("—")
            } else {
                ForEach(Array(solution.find.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 1) {
                        FormulaView(
                            findText(item),
                            fontSize: compact ? 13 : 17
                        )
                        if appState.showExtraExplanations, !item.description.isEmpty {
                            Text(item.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var siColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            notebookHeader("СИ")
            if solution.siConversions.isEmpty {
                Text(solution.siNote.isEmpty ? "—" : solution.siNote)
                    .font(.system(size: compact ? 11 : 13, weight: .regular, design: .serif))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(solution.siConversions.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.to)
                            .font(.system(size: compact ? 11 : 13, weight: .regular, design: .serif))
                            .fixedSize(horizontal: false, vertical: true)
                        if appState.showExtraExplanations, !item.note.isEmpty {
                            Text(item.note)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var solutionColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            notebookHeader("Решение")
            if solution.solutionSteps.isEmpty {
                if solution.formulas.isEmpty {
                    notebookEmpty("—")
                } else {
                    ForEach(Array(solution.formulas.enumerated()), id: \.offset) { _, formula in
                        FormulaView(formula.expression, fontSize: compact ? 13 : 17)
                    }
                }
            } else {
                ForEach(Array(solution.solutionSteps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 3) {
                        if appState.showExtraExplanations, !step.title.isEmpty {
                            Text(step.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !step.formula.isEmpty {
                            FormulaView(step.formula, fontSize: compact ? 14 : 18)
                        }
                        if !step.calculation.isEmpty {
                            FormulaView(step.calculation, fontSize: compact ? 12 : 16)
                        }
                        if !step.result.isEmpty {
                            FormulaView(
                                step.result,
                                fontSize: compact ? 13 : 17,
                                foregroundStyle: .primary
                            )
                        }
                        if appState.showExtraExplanations, !step.explanation.isEmpty {
                            Text(step.explanation)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if index < solution.solutionSteps.count - 1 {
                        Divider().overlay(Color.physoraSeparator.opacity(0.7))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Optional blocks

    private var separateFormulas: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("Формулы")
            ForEach(Array(solution.formulas.enumerated()), id: \.offset) { _, formula in
                VStack(alignment: .leading, spacing: 3) {
                    FormulaView(formula.expression, fontSize: compact ? 15 : 19)
                    if appState.showExtraExplanations {
                        if !formula.name.isEmpty {
                            Text(formula.name)
                                .font(.caption2.weight(.medium))
                        }
                        if !formula.variables.isEmpty {
                            Text(formula.variables)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(14)
    }

    private var separateCalculations: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Вычисления")
            ForEach(Array(solution.calculations.enumerated()), id: \.offset) { _, line in
                VStack(alignment: .leading, spacing: 2) {
                    FormulaView(line.expression, fontSize: compact ? 14 : 18)
                    if !line.result.isEmpty {
                        FormulaView(
                            "= \(line.result) \(line.unit)",
                            fontSize: compact ? 14 : 18
                        )
                    }
                    if appState.showExtraExplanations, !line.note.isEmpty {
                        Text(line.note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
    }

    private var diagramsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(solution.diagrams.count == 1 ? "Чертёж" : "Чертежи")
            ForEach(Array(solution.diagrams.enumerated()), id: \.offset) { _, diagram in
                VStack(alignment: .leading, spacing: 5) {
                    if solution.diagrams.count > 1 {
                        Text(diagram.title)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    DiagramView(diagram: diagram)
                        .padding(8)
                        .background(Color.physoraSurfaceMuted.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.physoraStroke, lineWidth: 0.8)
                        )
                }
            }
        }
        .padding(14)
    }

    private var graphsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(solution.graphs.count == 1 ? "График" : "Графики")
            ForEach(Array(solution.graphs.enumerated()), id: \.offset) { _, graph in
                VStack(alignment: .leading, spacing: 4) {
                    if solution.graphs.count > 1 {
                        Text(graph.title)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    PhysicsGraphView(graph: graph)
                }
            }
        }
        .padding(14)
    }

    private var answerBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            notebookHeader("Ответ")
            if solution.finalAnswer.isEmpty {
                Text("Недостаточно данных для однозначного ответа — проверьте условие.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(solution.finalAnswer.enumerated()), id: \.offset) { _, answer in
                    FormulaView(
                        quantityText(symbol: answer.symbol, value: answer.value, unit: answer.unit),
                        fontSize: compact ? 18 : 22
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.physoraSurfaceMuted.opacity(0.45))
    }

    private var warningsBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(solution.warnings.enumerated()), id: \.offset) { _, warning in
                HStack(alignment: .top, spacing: 6) {
                    Text("—")
                        .font(.caption2)
                    Text(warning)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Typography helpers

    private func notebookHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .tracking(0.2)
            .foregroundStyle(.primary)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.9)
            .foregroundStyle(.secondary)
    }

    private func notebookEmpty(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private func quantityText(symbol: String, value: String, unit: String) -> String {
        var result = "\(symbol) = \(value)"
        if !unit.isEmpty { result += " \(unit)" }
        return result
    }

    private func findText(_ item: FindQuantity) -> String {
        if item.unit.isEmpty {
            return "\(item.symbol) = ?"
        }
        return "\(item.symbol) = ? \\; [\(item.unit)]"
    }
}
