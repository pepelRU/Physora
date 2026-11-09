import XCTest
@testable import Physora

final class SolutionFormattingTests: XCTestCase {
    private func makeSolution() -> PhysicsSolution {
        var solution = PhysicsSolution()
        solution.topic = "Механика"
        solution.problemAnalysis = "Запишем второй закон Ньютона."
        solution.given = [GivenQuantity(symbol: "m", value: "2", unit: "кг")]
        solution.find = [FindQuantity(symbol: "F", description: "сила", unit: "Н")]
        solution.siNote = "Все величины уже в СИ."
        solution.formulas = [
            FormulaReference(name: "Второй закон Ньютона", expression: "F = ma", variables: "F — сила; m — масса; a — ускорение")
        ]
        solution.solutionSteps = [
            SolutionStep(
                title: "Подставим значения",
                explanation: "Масса и ускорение даны.",
                formula: "F = ma",
                calculation: "F = 2 \\cdot 3",
                result: "F = 6 Н"
            )
        ]
        solution.finalAnswer = [AnswerQuantity(symbol: "F", value: "6", unit: "Н")]
        solution.explanation = "Сила направлена вдоль ускорения."
        return solution
    }

    func testFullTextHasSchoolSectionsAndNoLatex() {
        let text = SolutionTextFormatter.full(
            prompt: "m = 2 кг, a = 3 м/с²",
            solution: makeSolution(),
            modelTitle: "DeepSeek Flash",
            date: Date(timeIntervalSince1970: 1_800_000_000)
        )
        XCTAssertTrue(text.contains("УСЛОВИЕ"))
        XCTAssertTrue(text.contains("ДАНО"))
        XCTAssertTrue(text.contains("НАЙТИ"))
        XCTAssertTrue(text.contains("РЕШЕНИЕ"))
        XCTAssertTrue(text.contains("ОТВЕТ"))
        XCTAssertTrue(text.contains("F = 6 Н"))
        XCTAssertFalse(text.contains("\\frac"))
        XCTAssertFalse(text.contains("\\cdot"))
    }

    func testStepCopyIsHumanReadable() {
        let step = SolutionStep(
            title: "Вычислим",
            explanation: "Подставляем.",
            formula: "E = \\frac{mv^2}{2}",
            calculation: "E = \\frac{2 \\cdot 3^2}{2}",
            result: "E = 9 Дж"
        )
        let text = SolutionTextFormatter.stepText(step, number: 1)
        XCTAssertTrue(text.contains("(mv²)/(2)"))
        XCTAssertFalse(text.contains("\\frac"))
    }

    func testPromptIncludesStrictJSONContract() {
        let prompt = AIPromptBuilder.systemPrompt(preferences: .standard)
        XCTAssertTrue(prompt.contains("problemAnalysis"))
        XCTAssertTrue(prompt.lowercased().contains("json"))
        XCTAssertTrue(prompt.contains("solutionSteps"))
        XCTAssertTrue(prompt.contains("ЧЕРТЕЖ"))
        XCTAssertFalse(prompt.contains("TODO"))
    }

    func testPromptRespectsDisabledDiagramPreference() {
        var preferences = SolutionPreferences.standard
        preferences.buildDiagrams = false
        let prompt = AIPromptBuilder.systemPrompt(preferences: preferences)
        XCTAssertTrue(prompt.contains("Всегда возвращай пустой массив diagrams"))
        let user = AIPromptBuilder.userPrompt(problem: "Тест", preferences: preferences)
        XCTAssertTrue(user.contains("BEGIN_PROBLEM"))
        XCTAssertTrue(user.contains("END_PROBLEM"))
    }
}
