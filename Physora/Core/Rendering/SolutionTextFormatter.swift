import Foundation
import UIKit

enum SolutionTextFormatter {
    static func formula(_ expression: String) -> String {
        MathParser.plainText(expression)
    }

    static func full(
        prompt: String,
        solution: PhysicsSolution,
        modelTitle: String,
        date: Date
    ) -> String {
        var sections: [String] = []
        sections.append("PHYSORA · решение задачи по физике")
        if !solution.topic.isEmpty {
            sections.append("Тема: \(solution.topic)")
        }
        sections.append("Модель: \(modelTitle)")
        sections.append("Дата: \(date.physoraDateTime)")
        sections.append("")
        sections.append("УСЛОВИЕ")
        sections.append(prompt.trimmingCharacters(in: .whitespacesAndNewlines))

        if !solution.problemAnalysis.isEmpty {
            sections.append("")
            sections.append("АНАЛИЗ")
            sections.append(solution.problemAnalysis)
        }

        if !solution.given.isEmpty {
            sections.append("")
            sections.append("ДАНО")
            sections.append(contentsOf: solution.given.map { givenLine($0) })
        }

        if !solution.find.isEmpty {
            sections.append("")
            sections.append("НАЙТИ")
            sections.append(contentsOf: solution.find.map { findLine($0) })
        }

        if !solution.siConversions.isEmpty || !solution.siNote.isEmpty {
            sections.append("")
            sections.append("СИ")
            if !solution.siNote.isEmpty {
                sections.append(solution.siNote)
            }
            sections.append(contentsOf: solution.siConversions.map {
                "\($0.quantity): \($0.from) → \($0.to)"
                    + ($0.note.isEmpty ? "" : " — \($0.note)")
            })
        }

        if !solution.formulas.isEmpty {
            sections.append("")
            sections.append("ФОРМУЛЫ")
            sections.append(contentsOf: solution.formulas.map { formulaLine($0) })
        }

        if !solution.solutionSteps.isEmpty {
            sections.append("")
            sections.append("РЕШЕНИЕ")
            for (index, step) in solution.solutionSteps.enumerated() {
                sections.append(stepText(step, number: index + 1))
            }
        }

        if !solution.calculations.isEmpty {
            sections.append("")
            sections.append("ВЫЧИСЛЕНИЯ")
            sections.append(contentsOf: solution.calculations.map(calculationLine))
        }

        if !solution.diagrams.isEmpty {
            sections.append("")
            sections.append("ЧЕРТЕЖИ")
            sections.append(contentsOf: solution.diagrams.map { "Схема: \($0.title)" })
        }

        if !solution.graphs.isEmpty {
            sections.append("")
            sections.append("ГРАФИКИ")
            sections.append(contentsOf: solution.graphs.map {
                "\($0.title) (\($0.xLabel) → \($0.yLabel))"
            })
        }

        if !solution.finalAnswer.isEmpty {
            sections.append("")
            sections.append("ОТВЕТ")
            sections.append(solution.finalAnswer.map {
                "\($0.symbol) = \($0.value) \($0.unit)".trimmingCharacters(in: .whitespaces)
            }.joined(separator: "\n"))
        }

        if !solution.explanation.isEmpty {
            sections.append("")
            sections.append("ПОЯСНЕНИЕ")
            sections.append(solution.explanation)
        }

        if !solution.warnings.isEmpty {
            sections.append("")
            sections.append("ПРОВЕРЬТЕ")
            sections.append(contentsOf: solution.warnings.map { "• \($0)" })
        }

        sections.append("")
        sections.append("Решение сгенерировано AI-моделью в Physora. Проверяйте вычисления и единицы измерения.")
        return sections.joined(separator: "\n")
    }

    static func givenText(_ solution: PhysicsSolution) -> String {
        solution.given.map { givenLine($0) }.joined(separator: "\n")
    }

    static func findText(_ solution: PhysicsSolution) -> String {
        solution.find.map { findLine($0) }.joined(separator: "\n")
    }

    static func formulasText(_ solution: PhysicsSolution) -> String {
        solution.formulas.map { formulaLine($0) }.joined(separator: "\n\n")
    }

    static func stepText(_ step: SolutionStep, number: Int) -> String {
        var lines: [String] = ["\(number). \(step.title)"]
        if !step.explanation.isEmpty { lines.append(step.explanation) }
        if !step.formula.isEmpty { lines.append("   \(formula(step.formula))") }
        if !step.calculation.isEmpty { lines.append("   \(formula(step.calculation))") }
        if !step.result.isEmpty { lines.append("   \(formula(step.result))") }
        return lines.joined(separator: "\n")
    }

    static func finalAnswerText(_ solution: PhysicsSolution) -> String {
        solution.finalAnswer.map {
            "\($0.symbol) = \($0.value) \($0.unit)".trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n")
    }

    static func formulaLine(_ formula: FormulaReference) -> String {
        var line = formula.name.isEmpty ? "" : "\(formula.name): "
        line += self.formula(formula.expression)
        if !formula.variables.isEmpty {
            line += "\n   \(formula.variables)"
        }
        if !formula.note.isEmpty {
            line += "\n   \(formula.note)"
        }
        return line
    }

    private static func givenLine(_ given: GivenQuantity) -> String {
        var line = "\(given.symbol) = \(given.value)"
        if !given.unit.isEmpty { line += " \(given.unit)" }
        if !given.note.isEmpty { line += " — \(given.note)" }
        return line
    }

    private static func findLine(_ find: FindQuantity) -> String {
        var line = "\(find.symbol)"
        if !find.description.isEmpty { line += " — \(find.description)" }
        if !find.unit.isEmpty { line += ", \(find.unit)" }
        return line + " — ?"
    }

    private static func calculationLine(_ calculation: CalculationLine) -> String {
        var line = "\(formula(calculation.expression))"
        if !calculation.result.isEmpty {
            line += " = \(calculation.result)"
        }
        if !calculation.unit.isEmpty {
            line += " \(calculation.unit)"
        }
        if !calculation.note.isEmpty {
            line += " — \(calculation.note)"
        }
        return line
    }
}

@MainActor
enum Clipboard {
    @discardableResult
    static func copy(_ text: String) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        UIPasteboard.general.string = value
        Haptics.light()
        return true
    }
}
