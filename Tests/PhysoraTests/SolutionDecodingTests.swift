import XCTest
@testable import Physora

final class SolutionDecodingTests: XCTestCase {
    func testTolerantDecodingWithMissingOptionalBlocks() throws {
        let json = """
        {
          "topic": "Механика",
          "isPhysicsProblem": true,
          "problemAnalysis": "Нужно найти силу.",
          "given": [{"symbol":"m","value":2,"unit":"кг"}],
          "find": [{"symbol":"F","description":"сила","unit":"Н"}],
          "formulas": [{"name":"Второй закон Ньютона","expression":"F = ma"}],
          "solutionSteps": [{"title":"Подставим значения","formula":"F = 2 \\\\cdot 3","result":"F = 6 Н"}],
          "finalAnswer": {"symbol":"F","value":"6","unit":"Н"},
          "explanation": "Сила нужна для ускорения."
        }
        """
        let solution = try JSONDecoder().decode(PhysicsSolution.self, from: Data(json.utf8))
        XCTAssertEqual(solution.topic, "Механика")
        XCTAssertEqual(solution.given.first?.value, "2")
        XCTAssertEqual(solution.finalAnswer.count, 1)
        XCTAssertEqual(solution.finalAnswer.first?.unit, "Н")
        XCTAssertTrue(solution.siConversions.isEmpty)
        XCTAssertTrue(solution.diagrams.isEmpty)
    }

    func testLossyDiagramAndGraphDecoding() throws {
        let json = """
        {
          "schemaVersion": 1,
          "topic": "Электричество",
          "isPhysicsProblem": true,
          "problemAnalysis": "Соберём цепь.",
          "given": [],
          "find": [],
          "siNote": "",
          "siConversions": [],
          "formulas": [],
          "solutionSteps": [{"title":"Шаг","explanation":"","formula":"","calculation":"","result":""}],
          "calculations": [],
          "diagrams": [{
            "title": "Цепь",
            "kind": "circuit",
            "width": 360,
            "height": 240,
            "showGrid": false,
            "elements": [
              {"type":"battery","x1":50,"y1":180,"x2":310,"y2":180},
              {"type":"unknown-shape","x1":0,"y1":0,"x2":1,"y2":1},
              {"type":"label","x":180,"y":90,"text":"R = 10 Ом"}
            ]
          }],
          "graphs": [{
            "title": "I(U)",
            "xLabel": "U, В",
            "yLabel": "I, А",
            "series": [
              {"name":"I(U)","color":"accent","points":[{"x":0,"y":0},{"x":"2,5","y":"0,5"},{"x":"bad","y":2}]},
              {"name":"bad","points":[{"x":0}]}
            ]
          }],
          "finalAnswer": [{"symbol":"I","value":"0,5","unit":"А"}],
          "explanation": "",
          "warnings": [],
          "needsDiagram": true
        }
        """
        let solution = try JSONDecoder().decode(PhysicsSolution.self, from: Data(json.utf8))
        XCTAssertEqual(solution.diagrams.count, 1)
        XCTAssertEqual(solution.diagrams.first?.elements.count, 3)
        XCTAssertEqual(solution.graphs.count, 1)
        XCTAssertEqual(solution.graphs.first?.series.count, 1)
        XCTAssertEqual(solution.graphs.first?.series.first?.points.count, 2)
    }

    func testEncodingRoundTripKeepsStructuredSolution() throws {
        var solution = PhysicsSolution()
        solution.topic = "Оптика"
        solution.problemAnalysis = "Построим изображение."
        solution.formulas = [FormulaReference(name: "Тонкая линза", expression: "\\frac{1}{F} = \\frac{1}{d} + \\frac{1}{f}")]
        solution.solutionSteps = [SolutionStep(title: "Запишем формулу", formula: "1/F = 1/d + 1/f")]
        solution.finalAnswer = [AnswerQuantity(symbol: "f", value: "0,15", unit: "м")]

        let data = try JSONEncoder().encode(solution)
        let decoded = try JSONDecoder().decode(PhysicsSolution.self, from: data)
        XCTAssertEqual(decoded, solution)
    }

    func testSolvedProblemStoresFullSolutionSnapshot() throws {
        var solution = PhysicsSolution()
        solution.topic = "Механика"
        solution.problemAnalysis = "Используем F = ma."
        solution.solutionSteps = [SolutionStep(title: "Подставим", formula: "F = ma")]
        solution.finalAnswer = [AnswerQuantity(symbol: "F", value: "6", unit: "Н")]

        let problem = SolvedProblem(prompt: "m = 2 кг, a = 3 м/с²", solution: solution, modelID: "deepseek-flash")
        XCTAssertEqual(problem.answerSummary, "F = 6 Н")
        XCTAssertEqual(problem.solution?.topic, "Механика")
        XCTAssertEqual(problem.solution?.finalAnswer.first?.value, "6")
    }
}
