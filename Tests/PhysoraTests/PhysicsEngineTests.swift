import XCTest
@testable import Physora

final class PhysicsEngineTests: XCTestCase {
    private func makeSolution() -> PhysicsSolution {
        var solution = PhysicsSolution()
        solution.topic = "Механика"
        solution.problemAnalysis = "Применим второй закон Ньютона."
        solution.given = [GivenQuantity(symbol: "m", value: "2", unit: "кг", note: "масса")]
        solution.find = [FindQuantity(symbol: "F", description: "сила", unit: "Н")]
        solution.solutionSteps = [
            SolutionStep(
                title: "Запишем второй закон Ньютона",
                explanation: "Ускорение вызвано равнодействующей силой.",
                formula: "F = ma",
                calculation: "F = 2 \\cdot 3",
                result: "F = 6 Н"
            )
        ]
        solution.finalAnswer = [AnswerQuantity(symbol: "F", value: "6", unit: "Н")]
        solution.explanation = "Сила направлена так же, как ускорение."
        return solution
    }

    func testValidSolutionIsPreserved() throws {
        let prepared = try PhysicsEngine.prepare(makeSolution(), preferences: .standard)
        XCTAssertEqual(prepared.finalAnswer.first?.value, "6")
        XCTAssertEqual(prepared.solutionSteps.count, 1)
        XCTAssertTrue(prepared.hasVisibleContent)
    }

    func testNumericAnswerWithoutUnitGetsWarning() throws {
        var solution = makeSolution()
        solution.finalAnswer = [AnswerQuantity(symbol: "F", value: "6", unit: "")]
        let prepared = try PhysicsEngine.prepare(solution, preferences: .standard)
        XCTAssertTrue(prepared.warnings.contains(where: { $0.localizedCaseInsensitiveContains("единиц") }))
    }

    func testNonPhysicsProblemIsRejected() {
        var solution = makeSolution()
        solution.isPhysicsProblem = false
        solution.explanation = "Это задача по литературе."
        XCTAssertThrowsError(try PhysicsEngine.prepare(solution, preferences: .standard)) { error in
            guard let aiError = error as? AIError,
                  case .notPhysics = aiError else {
                return XCTFail("Expected notPhysics")
            }
        }
    }

    func testEmptyPayloadIsRejected() {
        let solution = PhysicsSolution()
        XCTAssertThrowsError(try PhysicsEngine.prepare(solution, preferences: .standard))
    }

    func testDiagramIsRemovedWhenThePreferenceIsOff() throws {
        let decoded = try diagramSolution()
        var preferences = SolutionPreferences.standard
        preferences.buildDiagrams = false
        let prepared = try PhysicsEngine.prepare(decoded, preferences: preferences)
        XCTAssertTrue(prepared.diagrams.isEmpty)
        XCTAssertFalse(prepared.needsDiagram)
    }

    func testTextOnlyDiagramIsRejected() throws {
        let json = """
        {
          "schemaVersion": 1,
          "topic": "Механика",
          "isPhysicsProblem": true,
          "problemAnalysis": "Разберём силы.",
          "given": [],
          "find": [{"symbol":"F","description":"сила","unit":"Н"}],
          "siNote": "",
          "siConversions": [],
          "formulas": [],
          "solutionSteps": [{"title":"Шаг","explanation":"","formula":"F = ma","calculation":"","result":""}],
          "calculations": [],
          "diagrams": [{
            "title": "Текстовое описание",
            "kind": "forces",
            "width": 360,
            "height": 240,
            "elements": [
              {"type":"label","x":20,"y":20,"text":"На тело действует сила"},
              {"type":"label","x":40,"y":50,"text":"Направление вправо"}
            ]
          }],
          "graphs": [],
          "finalAnswer": [{"symbol":"F","value":"6","unit":"Н"}],
          "explanation": "",
          "warnings": [],
          "needsDiagram": true
        }
        """
        let decoded = try JSONDecoder().decode(PhysicsSolution.self, from: Data(json.utf8))
        let prepared = try PhysicsEngine.prepare(decoded, preferences: .standard)
        XCTAssertTrue(prepared.diagrams.isEmpty)
    }

    private func diagramSolution() throws -> PhysicsSolution {
        let json = """
        {
          "schemaVersion": 1,
          "topic": "Механика",
          "isPhysicsProblem": true,
          "problemAnalysis": "Разберём силы.",
          "given": [{"symbol":"m","value":"2","unit":"кг","note":""}],
          "find": [{"symbol":"F","description":"сила","unit":"Н"}],
          "siNote": "",
          "siConversions": [],
          "formulas": [],
          "solutionSteps": [{"title":"Шаг","explanation":"","formula":"F = ma","calculation":"","result":""}],
          "calculations": [],
          "diagrams": [{
            "title": "Силы",
            "kind": "forces",
            "width": 360,
            "height": 240,
            "elements": [
              {"type":"arrow","x1":20,"y1":20,"x2":100,"y2":20,"label":"F","color":"accent"}
            ]
          }],
          "graphs": [],
          "finalAnswer": [{"symbol":"F","value":"6","unit":"Н"}],
          "explanation": "",
          "warnings": [],
          "needsDiagram": true
        }
        """
        return try JSONDecoder().decode(PhysicsSolution.self, from: Data(json.utf8))
    }
}
