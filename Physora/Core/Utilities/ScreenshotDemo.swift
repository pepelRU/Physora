#if DEBUG
import Foundation
import SwiftData

/// Seeds one complete conversation for the simulator screenshots. This is
/// compiled only into Debug builds and only runs with `-physoraScreenshots`.
@MainActor
enum ScreenshotDemo {
    static let chatID = UUID(uuidString: "A11CE000-0000-4000-8000-000000000002")!

    static func seedIfNeeded(in context: ModelContext) {
        guard ScreenshotMode.isActive else { return }
        let descriptor = FetchDescriptor<SolvedProblem>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let solution = sampleSolution()
        let problem = SolvedProblem(
            prompt: solution.problemStatement,
            solution: solution,
            modelID: "deepseek-flash",
            chatID: chatID
        )
        context.insert(problem)
        try? context.save()
    }

    static func sampleSolution() -> PhysicsSolution {
        var solution = PhysicsSolution()
        solution.topic = "Динамика"
        solution.problemStatement = "Брусок массой 2 кг тянут по горизонтальной поверхности с силой 6 Н. Коэффициент трения 0,2. Найдите ускорение бруска. g = 10 м/с²."
        solution.given = [
            GivenQuantity(symbol: "m", value: "2", unit: "кг"),
            GivenQuantity(symbol: "F", value: "6", unit: "Н"),
            GivenQuantity(symbol: "μ", value: "0,2", unit: ""),
            GivenQuantity(symbol: "g", value: "10", unit: "м/с²")
        ]
        solution.find = [
            FindQuantity(symbol: "a", description: "ускорение", unit: "м/с²")
        ]
        solution.siNote = "Все данные уже в СИ."
        solution.solutionSteps = [
            SolutionStep(title: "", formula: "N = mg"),
            SolutionStep(title: "", formula: "F_{\\text{тр}} = μN"),
            SolutionStep(title: "", formula: "ma = F - F_{\\text{тр}}"),
            SolutionStep(
                title: "",
                formula: "a = \\frac{F - μmg}{m}",
                calculation: "a = \\frac{6 - 0{,}2 · 2 · 10}{2}",
                result: "a = 1 м/с²"
            )
        ]
        solution.finalAnswer = [
            AnswerQuantity(symbol: "a", value: "1", unit: "м/с²")
        ]
        solution.diagrams = [sampleDiagram()].compactMap { $0 }
        return solution
    }

    private static func sampleDiagram() -> DiagramSpec? {
        let json = """
        {
          "title": "Силы",
          "kind": "forces",
          "width": 360,
          "height": 240,
          "showGrid": false,
          "elements": [
            {"type":"line","x1":34,"y1":190,"x2":326,"y2":190,"color":"primary","strokeWidth":1.5},
            {"type":"rectangle","x":140,"y":140,"width":80,"height":50,"color":"primary","strokeWidth":2},
            {"type":"arrow","x1":180,"y1":140,"x2":180,"y2":56,"label":"N","color":"primary"},
            {"type":"arrow","x1":180,"y1":190,"x2":180,"y2":232,"label":"mg","color":"primary"},
            {"type":"arrow","x1":220,"y1":165,"x2":314,"y2":165,"label":"F","color":"primary"},
            {"type":"arrow","x1":140,"y1":165,"x2":62,"y2":165,"label":"Fтр","color":"primary"},
            {"type":"arrow","x1":300,"y1":86,"x2":336,"y2":86,"label":"x","color":"secondary"},
            {"type":"arrow","x1":300,"y1":86,"x2":300,"y2":44,"label":"y","color":"secondary"}
          ]
        }
        """
        return try? JSONDecoder().decode(DiagramSpec.self, from: Data(json.utf8))
    }
}
#endif
