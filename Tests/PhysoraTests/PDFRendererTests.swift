import XCTest
@testable import Physora

@MainActor
final class PDFRendererTests: XCTestCase {
    func testPDFDocumentIsGeneratedAsPDFData() throws {
        var solution = PhysicsSolution()
        solution.topic = "Механика"
        solution.problemAnalysis = "Применим второй закон Ньютона."
        solution.given = [GivenQuantity(symbol: "m", value: "2", unit: "кг")]
        solution.find = [FindQuantity(symbol: "F", description: "сила", unit: "Н")]
        solution.formulas = [
            FormulaReference(name: "Второй закон Ньютона", expression: "F = ma", variables: "F — сила; m — масса; a — ускорение")
        ]
        solution.solutionSteps = [
            SolutionStep(
                title: "Подставим значения",
                explanation: "Используем второй закон Ньютона.",
                formula: "F = ma",
                calculation: "F = 2 \\cdot 3",
                result: "F = 6 Н"
            )
        ]
        solution.finalAnswer = [AnswerQuantity(symbol: "F", value: "6", unit: "Н")]
        solution.explanation = "Сила направлена вдоль ускорения."
        solution.warnings = ["Проверьте единицы измерения."]

        let data = try SolutionPDFRenderer.pdfData(
            prompt: "Тело массой 2 кг движется с ускорением 3 м/с². Найдите силу.",
            solution: solution,
            modelTitle: "DeepSeek Flash",
            date: Date(timeIntervalSince1970: 1_800_000_000)
        )

        XCTAssertGreaterThan(data.count, 1_000)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
    }
}
