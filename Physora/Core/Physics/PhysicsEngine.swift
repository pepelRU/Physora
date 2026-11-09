import Foundation

/// Local guardrails around the model response. PhysicsEngine does not pretend
/// to independently solve arbitrary problems; it normalizes the structured
/// answer, rejects unusable payloads, enforces rendering limits and flags
/// obviously incomplete final answers.
enum PhysicsEngine {
    static func prepare(
        _ raw: PhysicsSolution,
        preferences: SolutionPreferences
    ) throws -> PhysicsSolution {
        guard raw.isPhysicsProblem else {
            throw AIError.notPhysics(raw.explanation.isEmpty ? raw.problemAnalysis : raw.explanation)
        }

        var solution = raw
        solution.schemaVersion = 1
        solution.topic = clean(solution.topic, limit: 80)
        solution.problemAnalysis = clean(solution.problemAnalysis, limit: 8_000)
        solution.explanation = clean(solution.explanation, limit: 10_000)
        solution.siNote = clean(solution.siNote, limit: 2_000)
        solution.warnings = Array(solution.warnings.prefix(8).map { clean($0, limit: 1_000) }.filter { !$0.isEmpty })

        solution.given = Array(solution.given.prefix(30)).map {
            GivenQuantity(
                symbol: clean($0.symbol, limit: 40),
                value: clean($0.value, limit: 100),
                unit: clean($0.unit, limit: 40),
                note: clean($0.note, limit: 300)
            )
        }
        solution.find = Array(solution.find.prefix(20)).map {
            FindQuantity(
                symbol: clean($0.symbol, limit: 40),
                description: clean($0.description, limit: 300),
                unit: clean($0.unit, limit: 40)
            )
        }
        solution.siConversions = Array(solution.siConversions.prefix(30)).map {
            SIConversion(
                quantity: clean($0.quantity, limit: 80),
                from: clean($0.from, limit: 80),
                to: clean($0.to, limit: 80),
                note: clean($0.note, limit: 300)
            )
        }
        solution.formulas = Array(solution.formulas.prefix(20)).map {
            FormulaReference(
                name: clean($0.name, limit: 200),
                expression: clean($0.expression, limit: 500),
                variables: clean($0.variables, limit: 1_000),
                note: clean($0.note, limit: 1_000)
            )
        }.filter { !$0.expression.isEmpty || !$0.name.isEmpty }

        solution.solutionSteps = Array(solution.solutionSteps.prefix(15)).compactMap { step in
            let title = clean(step.title, limit: 250)
            let explanation = clean(step.explanation, limit: 5_000)
            let formula = clean(step.formula, limit: 800)
            let calculation = clean(step.calculation, limit: 2_000)
            let result = clean(step.result, limit: 500)
            guard !title.isEmpty || !explanation.isEmpty || !formula.isEmpty
                    || !calculation.isEmpty || !result.isEmpty else { return nil }
            return SolutionStep(
                title: title.isEmpty ? "Шаг решения" : title,
                explanation: explanation,
                formula: formula,
                calculation: calculation,
                result: result
            )
        }

        solution.calculations = Array(solution.calculations.prefix(30)).map {
            CalculationLine(
                expression: clean($0.expression, limit: 500),
                result: clean($0.result, limit: 200),
                unit: clean($0.unit, limit: 50),
                note: clean($0.note, limit: 500)
            )
        }.filter { !$0.expression.isEmpty || !$0.result.isEmpty }

        solution.finalAnswer = Array(solution.finalAnswer.prefix(12)).map {
            AnswerQuantity(
                symbol: clean($0.symbol, limit: 60),
                value: clean($0.value, limit: 120),
                unit: clean($0.unit, limit: 50)
            )
        }.filter { !$0.value.isEmpty || !$0.symbol.isEmpty }

        solution.diagrams = preferences.buildDiagrams ? sanitizeDiagrams(solution.diagrams) : []
        solution.graphs = sanitizeGraphs(solution.graphs)
        solution.needsDiagram = !solution.diagrams.isEmpty

        guard solution.hasVisibleContent else {
            throw AIError.emptyResponse
        }
        if solution.problemAnalysis.isEmpty && solution.solutionSteps.isEmpty {
            throw AIError.malformedJSON
        }

        if solution.finalAnswer.isEmpty {
            let warning = "В ответе не хватает данных для однозначного числового результата."
            if !solution.warnings.contains(where: { $0.localizedCaseInsensitiveContains("данн") }) {
                solution.warnings.insert(warning, at: 0)
            }
        } else if solution.finalAnswer.contains(where: {
            $0.unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.value.contains(where: { $0.isNumber })
        }) {
            solution.warnings.append("В ответе не указана единица измерения — проверьте размерность.")
        }
        if solution.solutionSteps.isEmpty {
            solution.warnings.append("Подробные шаги решения отсутствуют — проверьте условие и формулы.")
        }
        return solution
    }

    private static func sanitizeDiagrams(_ diagrams: [DiagramSpec]) -> [DiagramSpec] {
        Array(diagrams.prefix(4)).compactMap { diagram in
            let elements = diagram.elements
                .prefix(100)
                .filter { $0.isSupported }
                .map { sanitize(element: $0, designWidth: diagram.designSize.width, designHeight: diagram.designSize.height) }
            let hasGeometricContent = elements.contains { $0.type != "label" }
            guard elements.count >= 2, hasGeometricContent else { return nil }
            return DiagramSpec(
                title: clean(diagram.title, limit: 160),
                kind: clean(diagram.kind, limit: 40),
                width: diagram.designSize.width,
                height: diagram.designSize.height,
                showGrid: diagram.showGrid,
                elements: elements
            )
        }
    }

    private static func sanitize(element: DiagramElement, designWidth: Double, designHeight: Double) -> DiagramElement {
        var item = element
        item.strokeWidth = min(max(item.strokeWidth ?? 2, 0.8), 8)
        item.text = item.text.map { cleanInline($0, limit: 120) }
        item.label = item.label.map { cleanInline($0, limit: 120) }
        item.color = item.color.map { cleanInline($0, limit: 30) }
        item.points = item.points?.prefix(80).map { point in
            DiagramPoint(
                x: clamp(point.x, lower: -designWidth, upper: designWidth * 2),
                y: clamp(point.y, lower: -designHeight, upper: designHeight * 2)
            )
        }
        return item
    }

    private static func sanitizeGraphs(_ graphs: [PhysicsGraph]) -> [PhysicsGraph] {
        Array(graphs.prefix(3)).compactMap { graph in
            let series = graph.series.prefix(5).compactMap { series -> GraphSeries? in
                let points = series.points
                    .prefix(500)
                    .filter { $0.x.isFinite && $0.y.isFinite && abs($0.x) < 1e12 && abs($0.y) < 1e12 }
                    .map { GraphPoint(x: $0.x, y: $0.y) }
                guard points.count >= 2 else { return nil }
                return GraphSeries(
                    name: clean(series.name, limit: 80),
                    color: clean(series.color, limit: 30),
                    points: points
                )
            }
            guard !series.isEmpty else { return nil }
            return PhysicsGraph(
                title: clean(graph.title, limit: 160),
                xLabel: cleanInline(graph.xLabel, limit: 80),
                yLabel: cleanInline(graph.yLabel, limit: 80),
                series: series,
                showGrid: graph.showGrid
            )
        }
    }

    private static func clean(_ string: String, limit: Int) -> String {
        let normalized = string
            .replacingOccurrences(of: "\u{0000}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(normalized.prefix(limit))
    }

    private static func cleanInline(_ string: String, limit: Int) -> String {
        clean(string, limit: limit)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        guard value.isFinite else { return lower }
        return min(max(value, lower), upper)
    }
}
