import SwiftUI
import UIKit

enum SolutionPDFError: LocalizedError {
    case renderFailed
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed: "Не удалось сформировать PDF."
        case .writeFailed: "Не удалось сохранить PDF во временную папку."
        }
    }
}

@MainActor
enum SolutionPDFRenderer {
    static func pdfData(
        prompt: String,
        solution: PhysicsSolution,
        modelTitle: String,
        date: Date
    ) throws -> Data {
        let media = PDFMedia(
            diagrams: solution.diagrams.compactMap(renderDiagram),
            graphs: solution.graphs.compactMap(renderGraph)
        )

        let pageRect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Physora — решение задачи по физике",
            kCGPDFContextAuthor as String: "Physora",
            kCGPDFContextCreator as String: "Physora for iOS",
            kCGPDFContextSubject as String: solution.topic
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { context in
            let writer = SolutionPDFWriter(
                context: context,
                pageRect: pageRect,
                prompt: prompt,
                solution: solution,
                modelTitle: modelTitle,
                date: date,
                media: media
            )
            writer.drawDocument()
        }
    }

    static func temporaryPDFURL(
        prompt: String,
        solution: PhysicsSolution,
        modelTitle: String,
        date: Date
    ) throws -> URL {
        let data = try pdfData(prompt: prompt, solution: solution, modelTitle: modelTitle, date: date)
        guard !data.isEmpty else { throw SolutionPDFError.renderFailed }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let name = "Physora-Solution-\(formatter.string(from: date)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw SolutionPDFError.writeFailed
        }
    }

    private static func renderDiagram(_ diagram: DiagramSpec) -> UIImage? {
        let width: CGFloat = 520
        let height = width * CGFloat(diagram.designSize.height / max(diagram.designSize.width, 1))
        let content = DiagramView(diagram: diagram)
            .frame(width: width, height: height)
            .padding(14)
            .background(Color.white)
            .environment(\.colorScheme, .light)
            .transaction { $0.disablesAnimations = true }
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.uiImage
    }

    private static func renderGraph(_ graph: PhysicsGraph) -> UIImage? {
        let content = PhysicsGraphView(graph: graph)
            .frame(width: 500)
            .padding(14)
            .background(Color.white)
            .environment(\.colorScheme, .light)
            .transaction { $0.disablesAnimations = true }
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.uiImage
    }
}

private struct PDFMedia {
    let diagrams: [UIImage]
    let graphs: [UIImage]
}

// MARK: - Page layout

@MainActor
private final class SolutionPDFWriter {
    private let context: UIGraphicsPDFRendererContext
    private let pageRect: CGRect
    private let prompt: String
    private let solution: PhysicsSolution
    private let modelTitle: String
    private let date: Date
    private let media: PDFMedia

    private let margin: CGFloat = 44
    private let accent = UIColor(red: 56 / 255, green: 169 / 255, blue: 255 / 255, alpha: 1)
    private let ink = UIColor(red: 0.075, green: 0.125, blue: 0.185, alpha: 1)
    private let muted = UIColor(red: 0.37, green: 0.43, blue: 0.51, alpha: 1)
    private let hairline = UIColor(red: 0.84, green: 0.88, blue: 0.92, alpha: 1)
    private let paperTint = UIColor(red: 0.955, green: 0.974, blue: 0.992, alpha: 1)
    private let amber = UIColor(red: 0.72, green: 0.44, blue: 0.06, alpha: 1)

    private var y: CGFloat = 44
    private var pageNumber = 0
    private var hasStarted = false

    private var contentWidth: CGFloat { pageRect.width - margin * 2 }
    private var footerLimit: CGFloat { pageRect.height - 50 }

    init(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        prompt: String,
        solution: PhysicsSolution,
        modelTitle: String,
        date: Date,
        media: PDFMedia
    ) {
        self.context = context
        self.pageRect = pageRect
        self.prompt = prompt
        self.solution = solution
        self.modelTitle = modelTitle
        self.date = date
        self.media = media
    }

    func drawDocument() {
        beginPage(first: true)
        drawDocumentTitle()
        drawCondition()
        drawAnalysis()
        drawGivenAndFind()
        drawSIConversions()
        drawFormulas()
        drawSolutionSteps()
        drawCalculations()
        drawDiagrams()
        drawGraphs()
        drawFinalAnswer()
        drawExplanation()
        drawWarnings()
        finishPage()
    }

    // MARK: Page lifecycle

    private func beginPage(first: Bool = false) {
        if hasStarted {
            drawFooter()
        }
        context.beginPage()
        hasStarted = true
        pageNumber += 1
        UIColor.white.setFill()
        context.cgContext.fill(pageRect)
        y = margin
        drawHeader(compact: !first)
    }

    private func finishPage() {
        guard hasStarted else { return }
        drawFooter()
    }

    private func newPageIfNeeded(_ height: CGFloat) {
        if y + height > footerLimit {
            beginPage()
        }
    }

    private func drawHeader(compact: Bool) {
        let atomRect = CGRect(x: margin, y: margin, width: 22, height: 22)
        drawAtom(in: atomRect)

        let brandAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: ink,
            .kern: 1.8
        ]
        ("PHYSORA" as NSString).draw(at: CGPoint(x: margin + 30, y: margin + 3), withAttributes: brandAttributes)

        if compact {
            let rightAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.5, weight: .semibold),
                .foregroundColor: muted,
                .kern: 1.0
            ]
            let text = "РЕШЕНИЕ ЗАДАЧИ"
            let size = (text as NSString).size(withAttributes: rightAttributes)
            (text as NSString).draw(
                at: CGPoint(x: pageRect.width - margin - size.width, y: margin + 6),
                withAttributes: rightAttributes
            )
        } else {
            let tagAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.5, weight: .semibold),
                .foregroundColor: accent,
                .kern: 1.3
            ]
            let text = "ФИЗИКА · ЯСНО"
            let size = (text as NSString).size(withAttributes: tagAttributes)
            (text as NSString).draw(
                at: CGPoint(x: pageRect.width - margin - size.width, y: margin + 6),
                withAttributes: tagAttributes
            )
        }

        context.cgContext.setStrokeColor(hairline.cgColor)
        context.cgContext.setLineWidth(0.7)
        context.cgContext.move(to: CGPoint(x: margin, y: margin + 32))
        context.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: margin + 32))
        context.cgContext.strokePath()
        y = margin + 50
    }

    private func drawFooter() {
        context.cgContext.setStrokeColor(hairline.cgColor)
        context.cgContext.setLineWidth(0.6)
        context.cgContext.move(to: CGPoint(x: margin, y: pageRect.height - 34))
        context.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: pageRect.height - 34))
        context.cgContext.strokePath()

        let disclaimer = "Physora · ответ ИИ может содержать ошибки — проверяйте решение"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .regular),
            .foregroundColor: muted
        ]
        (disclaimer as NSString).draw(
            at: CGPoint(x: margin, y: pageRect.height - 26),
            withAttributes: attributes
        )
        let pageText = "\(pageNumber)"
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 8, weight: .medium),
            .foregroundColor: muted
        ]
        let size = (pageText as NSString).size(withAttributes: pageAttributes)
        (pageText as NSString).draw(
            at: CGPoint(x: pageRect.width - margin - size.width, y: pageRect.height - 26),
            withAttributes: pageAttributes
        )
    }

    // MARK: Title and condition

    private func drawDocumentTitle() {
        let title = "Решение задачи по физике"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 25, weight: .bold),
            .foregroundColor: ink
        ]
        let titleRect = (title as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: 80),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: titleAttributes,
            context: nil
        )
        (title as NSString).draw(
            in: CGRect(x: margin, y: y, width: contentWidth, height: ceil(titleRect.height)),
            withAttributes: titleAttributes
        )
        y += ceil(titleRect.height) + 7

        if !solution.topic.isEmpty {
            drawTag(solution.topic.uppercased(), color: accent, background: accent.withAlphaComponent(0.09))
        }

        let metadata = "\(date.physoraDateTime)   ·   \(modelTitle)"
        let metadataAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: muted
        ]
        (metadata as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: metadataAttributes)
        y += 23
    }

    private func drawCondition() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        drawSectionHeader("Условие")
        newPageIfNeeded(50)
        let accentBar = CGRect(x: margin, y: y, width: 2.5, height: 22)
        accent.setFill()
        UIBezierPath(roundedRect: accentBar, cornerRadius: 1.25).fill()
        drawLongText(prompt, font: UIFont.systemFont(ofSize: 11.5), color: ink, indent: 14)
        y += 2
    }

    private func drawAnalysis() {
        guard !solution.problemAnalysis.isEmpty else { return }
        newPageIfNeeded(70)
        drawSectionHeader("Анализ задачи")
        drawLongText(solution.problemAnalysis, font: UIFont.systemFont(ofSize: 11.2), color: ink)
    }

    private func drawGivenAndFind() {
        guard !solution.given.isEmpty || !solution.find.isEmpty else { return }
        let givenLines = solution.given.map { item -> String in
            var line = "\(item.symbol) = \(MathParser.plainText(item.value))"
            if !item.unit.isEmpty { line += " \(item.unit)" }
            return line
        }
        let findLines = solution.find.map { item -> String in
            var line = item.symbol
            if !item.unit.isEmpty { line += ", \(item.unit)" }
            return line + " — ?"
        }

        let leftWidth = contentWidth * 0.54
        let rightWidth = contentWidth - leftWidth - 12
        let titleFont = UIFont.systemFont(ofSize: 9, weight: .semibold)
        let lineFont = UIFont.systemFont(ofSize: 11.5, weight: .regular)
        let lineAttributes: [NSAttributedString.Key: Any] = [
            .font: lineFont,
            .foregroundColor: ink
        ]
        let leftText = givenLines.joined(separator: "\n")
        let rightText = findLines.joined(separator: "\n")
        let leftHeight = max(22, (leftText as NSString).boundingRect(
            with: CGSize(width: leftWidth - 24, height: 400),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: lineAttributes,
            context: nil
        ).height)
        let rightHeight = max(22, (rightText as NSString).boundingRect(
            with: CGSize(width: rightWidth - 24, height: 400),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: lineAttributes,
            context: nil
        ).height)
        let blockHeight = max(leftHeight, rightHeight) + 38
        newPageIfNeeded(blockHeight + 40)
        drawSectionHeader("Дано и требуется найти")

        let leftRect = CGRect(x: margin, y: y, width: leftWidth, height: blockHeight)
        let rightRect = CGRect(x: margin + leftWidth + 12, y: y, width: rightWidth, height: blockHeight)
        drawPillBox(leftRect)
        drawPillBox(rightRect)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent,
            .kern: 0.7
        ]
        ("ДАНО" as NSString).draw(at: CGPoint(x: leftRect.minX + 12, y: leftRect.minY + 10), withAttributes: titleAttributes)
        ("НАЙТИ" as NSString).draw(at: CGPoint(x: rightRect.minX + 12, y: rightRect.minY + 10), withAttributes: titleAttributes)

        (leftText as NSString).draw(
            in: CGRect(x: leftRect.minX + 12, y: leftRect.minY + 25, width: leftWidth - 24, height: leftHeight + 4),
            withAttributes: lineAttributes
        )
        (rightText as NSString).draw(
            in: CGRect(x: rightRect.minX + 12, y: rightRect.minY + 25, width: rightWidth - 24, height: rightHeight + 4),
            withAttributes: lineAttributes
        )
        y = max(leftRect.maxY, rightRect.maxY) + 14
    }

    private func drawSIConversions() {
        guard !solution.siConversions.isEmpty || !solution.siNote.isEmpty else { return }
        newPageIfNeeded(60)
        drawSectionHeader("Перевод в СИ")
        if !solution.siNote.isEmpty {
            drawLongText(solution.siNote, font: UIFont.systemFont(ofSize: 10.8), color: muted)
        }
        if !solution.siConversions.isEmpty {
            for conversion in solution.siConversions {
                newPageIfNeeded(24)
                let text = "\(conversion.quantity): \(conversion.from) → \(conversion.to)"
                    + (conversion.note.isEmpty ? "" : "   ·   \(conversion.note)")
                drawPlainLine(text, font: UIFont.systemFont(ofSize: 10.8), color: ink)
            }
        }
        y += 2
    }

    private func drawFormulas() {
        guard !solution.formulas.isEmpty else { return }
        newPageIfNeeded(62)
        drawSectionHeader("Формулы")
        for formula in solution.formulas {
            newPageIfNeeded(62)
            let blockTop = y
            let name = formula.name.isEmpty ? "Формула" : formula.name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9.2, weight: .semibold),
                .foregroundColor: muted
            ]
            (name as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttributes)
            y += 15

            let rendered = MathParser.plainText(formula.expression)
            let formulaFont = UIFont(name: "Georgia", size: 15) ?? UIFont.systemFont(ofSize: 15, weight: .regular)
            drawCenteredFormula(rendered, font: formulaFont, color: ink)
            if !formula.variables.isEmpty {
                let variableAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8.8),
                    .foregroundColor: muted
                ]
                let variableRect = (formula.variables as NSString).boundingRect(
                    with: CGSize(width: contentWidth - 26, height: 200),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: variableAttributes,
                    context: nil
                )
                newPageIfNeeded(ceil(variableRect.height) + 8)
                (formula.variables as NSString).draw(
                    in: CGRect(x: margin + 13, y: y, width: contentWidth - 26, height: ceil(variableRect.height) + 2),
                    withAttributes: variableAttributes
                )
                y += ceil(variableRect.height) + 2
            }
            if !formula.note.isEmpty {
                let noteAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 8.8),
                    .foregroundColor: muted
                ]
                let noteRect = (formula.note as NSString).boundingRect(
                    with: CGSize(width: contentWidth - 26, height: 100),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: noteAttributes,
                    context: nil
                )
                newPageIfNeeded(ceil(noteRect.height) + 5)
                (formula.note as NSString).draw(
                    in: CGRect(x: margin + 13, y: y, width: contentWidth - 26, height: ceil(noteRect.height) + 2),
                    withAttributes: noteAttributes
                )
                y += ceil(noteRect.height) + 2
            }
            y = max(y, blockTop + 30) + 13
            drawHairline(y: y - 6)
        }
    }

    private func drawSolutionSteps() {
        guard !solution.solutionSteps.isEmpty else { return }
        newPageIfNeeded(62)
        drawSectionHeader("Решение")
        for (index, step) in solution.solutionSteps.enumerated() {
            newPageIfNeeded(70)
            let stepTop = y
            let numberCenter = CGPoint(x: margin + 8, y: y + 7)
            accent.setFill()
            UIBezierPath(ovalIn: CGRect(x: numberCenter.x - 8, y: numberCenter.y - 8, width: 16, height: 16)).fill()
            let numberAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.5, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let number = "\(index + 1)"
            let numberSize = (number as NSString).size(withAttributes: numberAttributes)
            (number as NSString).draw(
                at: CGPoint(x: numberCenter.x - numberSize.width / 2, y: numberCenter.y - numberSize.height / 2),
                withAttributes: numberAttributes
            )

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: ink
            ]
            let titleRect = (step.title as NSString).boundingRect(
                with: CGSize(width: contentWidth - 30, height: 80),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: titleAttributes,
                context: nil
            )
            (step.title as NSString).draw(
                in: CGRect(x: margin + 25, y: y, width: contentWidth - 30, height: ceil(titleRect.height)),
                withAttributes: titleAttributes
            )
            y += ceil(titleRect.height) + 4

            if !step.explanation.isEmpty {
                drawLongText(step.explanation, font: UIFont.systemFont(ofSize: 10.8), color: ink, indent: 25)
            }
            if !step.formula.isEmpty {
                let formulaFont = UIFont(name: "Georgia", size: 13.5) ?? UIFont.systemFont(ofSize: 13.5)
                drawIndentedFormula(MathParser.plainText(step.formula), font: formulaFont, color: ink, indent: 25)
            }
            if !step.calculation.isEmpty {
                drawIndentedText(MathParser.plainText(step.calculation), font: UIFont.systemFont(ofSize: 10.8), color: ink, indent: 25)
            }
            if !step.result.isEmpty {
                let resultColor = UIColor(red: 0.08, green: 0.44, blue: 0.70, alpha: 1)
                drawIndentedText(MathParser.plainText(step.result), font: UIFont.systemFont(ofSize: 11.5, weight: .semibold), color: resultColor, indent: 25)
            }
            y = max(y, stepTop + 34)
            y += 8
            drawHairline(y: y - 3)
        }
    }

    private func drawCalculations() {
        guard !solution.calculations.isEmpty else { return }
        newPageIfNeeded(60)
        drawSectionHeader("Вычисления")
        for calculation in solution.calculations {
            newPageIfNeeded(22)
            var text = MathParser.plainText(calculation.expression)
            if !calculation.result.isEmpty {
                text += " = \(MathParser.plainText(calculation.result))"
            }
            if !calculation.unit.isEmpty { text += " \(calculation.unit)" }
            drawPlainLine(text, font: UIFont(name: "Georgia", size: 11.5) ?? UIFont.systemFont(ofSize: 11.5), color: ink)
        }
        y += 2
    }

    private func drawDiagrams() {
        guard !media.diagrams.isEmpty else { return }
        newPageIfNeeded(90)
        drawSectionHeader("Чертёж")
        for (index, image) in media.diagrams.enumerated() {
            let title = index < solution.diagrams.count ? solution.diagrams[index].title : "Схема"
            let availableWidth = contentWidth - 24
            let imageHeight = min(250, availableWidth * image.size.height / max(image.size.width, 1))
            newPageIfNeeded(imageHeight + 44)
            let imageRect = CGRect(x: margin, y: y, width: contentWidth, height: imageHeight)
            drawMediaCard(rect: imageRect, image: image)
            y += imageHeight + 6
            let captionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.8, weight: .medium),
                .foregroundColor: muted
            ]
            (title as NSString).draw(
                in: CGRect(x: margin, y: y, width: contentWidth, height: 20),
                withAttributes: captionAttributes
            )
            y += 25
        }
    }

    private func drawGraphs() {
        guard !media.graphs.isEmpty else { return }
        newPageIfNeeded(90)
        drawSectionHeader("Графики")
        for (index, image) in media.graphs.enumerated() {
            let title = index < solution.graphs.count ? solution.graphs[index].title : "График"
            let availableWidth = contentWidth - 24
            let imageHeight = min(270, availableWidth * image.size.height / max(image.size.width, 1))
            newPageIfNeeded(imageHeight + 44)
            let imageRect = CGRect(x: margin, y: y, width: contentWidth, height: imageHeight)
            drawMediaCard(rect: imageRect, image: image)
            y += imageHeight + 6
            let captionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.8, weight: .medium),
                .foregroundColor: muted
            ]
            (title as NSString).draw(
                in: CGRect(x: margin, y: y, width: contentWidth, height: 20),
                withAttributes: captionAttributes
            )
            y += 25
        }
    }

    private func drawFinalAnswer() {
        guard !solution.finalAnswer.isEmpty else { return }
        newPageIfNeeded(100)
        drawSectionHeader("Ответ")

        let answerText = solution.finalAnswer.map {
            "\($0.symbol) = \($0.value) \($0.unit)".trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n")
        let font = UIFont(name: "Georgia", size: 15) ?? UIFont.systemFont(ofSize: 15, weight: .medium)
        let answerAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.03, green: 0.31, blue: 0.50, alpha: 1)
        ]
        let bounds = (answerText as NSString).boundingRect(
            with: CGSize(width: contentWidth - 34, height: 320),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: answerAttributes,
            context: nil
        )
        let cardHeight = ceil(bounds.height) + 32
        newPageIfNeeded(cardHeight + 10)
        let card = CGRect(x: margin, y: y, width: contentWidth, height: cardHeight)
        UIColor(red: 0.91, green: 0.96, blue: 1, alpha: 1).setFill()
        UIBezierPath(roundedRect: card, cornerRadius: 12).fill()
        accent.withAlphaComponent(0.45).setStroke()
        let border = UIBezierPath(roundedRect: card, cornerRadius: 12)
        border.lineWidth = 0.8
        border.stroke()
        let bar = CGRect(x: card.minX + 13, y: card.minY + 11, width: 2.5, height: card.height - 22)
        accent.setFill()
        UIBezierPath(roundedRect: bar, cornerRadius: 1.25).fill()
        (answerText as NSString).draw(
            in: CGRect(x: card.minX + 25, y: card.minY + 14, width: card.width - 38, height: bounds.height + 4),
            withAttributes: answerAttributes
        )
        y = card.maxY + 14
    }

    private func drawExplanation() {
        guard !solution.explanation.isEmpty else { return }
        newPageIfNeeded(60)
        drawSectionHeader("Пояснение")
        drawLongText(solution.explanation, font: UIFont.systemFont(ofSize: 10.8), color: ink)
    }

    private func drawWarnings() {
        guard !solution.warnings.isEmpty else { return }
        newPageIfNeeded(60)
        drawSectionHeader("Проверьте")
        for warning in solution.warnings {
            newPageIfNeeded(34)
            let font = UIFont.systemFont(ofSize: 9.8)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: amber
            ]
            let bounds = (warning as NSString).boundingRect(
                with: CGSize(width: contentWidth - 34, height: 160),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            let height = ceil(bounds.height) + 14
            let rect = CGRect(x: margin, y: y, width: contentWidth, height: height)
            UIColor(red: 1, green: 0.971, blue: 0.912, alpha: 1).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 8).fill()
            (warning as NSString).draw(
                in: CGRect(x: rect.minX + 13, y: rect.minY + 7, width: rect.width - 26, height: bounds.height + 2),
                withAttributes: attributes
            )
            y = rect.maxY + 7
        }
    }

    // MARK: Drawing helpers

    private func drawSectionHeader(_ title: String) {
        newPageIfNeeded(52)
        y += 8
        accent.setFill()
        UIBezierPath(roundedRect: CGRect(x: margin, y: y + 1, width: 3, height: 13), cornerRadius: 1.5).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: ink,
            .kern: 0.4
        ]
        (title as NSString).draw(at: CGPoint(x: margin + 10, y: y), withAttributes: attributes)
        y += 22
    }

    private func drawTag(_ text: String, color: UIColor, background: UIColor) {
        let font = UIFont.systemFont(ofSize: 8, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: 0.8
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: margin, y: y, width: size.width + 16, height: 18)
        background.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 9).fill()
        (text as NSString).draw(at: CGPoint(x: rect.minX + 8, y: rect.minY + 4.5), withAttributes: attributes)
        y += 23
    }

    private func drawLongText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        indent: CGFloat = 0
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2.5
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        var remaining = trimmed
        let width = contentWidth - indent

        while !remaining.isEmpty {
            let available = footerLimit - y
            if available < font.lineHeight * 2 {
                beginPage()
                continue
            }
            let source = remaining as NSString
            let fullHeight = measure(source, width: width, attributes: attributes)
            if fullHeight <= available - 1 {
                (remaining as NSString).draw(
                    in: CGRect(x: margin + indent, y: y, width: width, height: fullHeight + 2),
                    withAttributes: attributes
                )
                y += fullHeight + 4
                return
            }

            let split = fittingPrefix(source, width: width, height: available - 2, attributes: attributes)
            guard split > 0 else {
                beginPage()
                continue
            }
            let chunk = source.substring(to: split)
            let chunkHeight = measure(chunk as NSString, width: width, attributes: attributes)
            (chunk as NSString).draw(
                in: CGRect(x: margin + indent, y: y, width: width, height: chunkHeight + 2),
                withAttributes: attributes
            )
            remaining = source.substring(from: split)
                .trimmingCharacters(in: .newlines)
            if remaining.hasPrefix(" ") {
                remaining.removeFirst()
            }
            beginPage()
        }
    }

    private func drawPlainLine(_ text: String, font: UIFont, color: UIColor) {
        newPageIfNeeded(font.lineHeight + 5)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        (text as NSString).draw(at: CGPoint(x: margin + 4, y: y), withAttributes: attributes)
        y += font.lineHeight + 3
    }

    private func drawCenteredFormula(_ text: String, font: UIFont, color: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth - 24, height: 80),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        newPageIfNeeded(ceil(size.height) + 10)
        (text as NSString).draw(
            in: CGRect(x: margin + 12, y: y, width: contentWidth - 24, height: ceil(size.height) + 2),
            withAttributes: attributes
        )
        y += ceil(size.height) + 5
    }

    private func drawIndentedFormula(_ text: String, font: UIFont, color: UIColor, indent: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 1.5
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let width = contentWidth - indent
        let height = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 120),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).height
        newPageIfNeeded(ceil(height) + 8)
        (text as NSString).draw(
            in: CGRect(x: margin + indent, y: y, width: width, height: ceil(height) + 2),
            withAttributes: attributes
        )
        y += ceil(height) + 5
    }

    private func drawIndentedText(_ text: String, font: UIFont, color: UIColor, indent: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let width = contentWidth - indent
        let height = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 160),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).height
        newPageIfNeeded(ceil(height) + 5)
        (text as NSString).draw(
            in: CGRect(x: margin + indent, y: y, width: width, height: ceil(height) + 2),
            withAttributes: attributes
        )
        y += ceil(height) + 3
    }

    private func drawPillBox(_ rect: CGRect) {
        paperTint.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()
        hairline.setStroke()
        let border = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        border.lineWidth = 0.7
        border.stroke()
    }

    private func drawMediaCard(rect: CGRect, image: UIImage) {
        UIColor(red: 0.979, green: 0.987, blue: 0.995, alpha: 1).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
        hairline.setStroke()
        let border = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        border.lineWidth = 0.8
        border.stroke()

        let inset = CGRect(x: rect.minX + 12, y: rect.minY + 8, width: rect.width - 24, height: rect.height - 16)
        let scale = min(inset.width / max(image.size.width, 1), inset.height / max(image.size.height, 1))
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = CGRect(
            x: inset.midX - drawSize.width / 2,
            y: inset.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        context.cgContext.saveGState()
        UIBezierPath(roundedRect: inset, cornerRadius: 6).addClip()
        image.draw(in: drawRect)
        context.cgContext.restoreGState()
    }

    private func drawHairline(y: CGFloat) {
        context.cgContext.setStrokeColor(hairline.cgColor)
        context.cgContext.setLineWidth(0.6)
        context.cgContext.move(to: CGPoint(x: margin, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        context.cgContext.strokePath()
    }

    private func drawAtom(in rect: CGRect) {
        context.cgContext.saveGState()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radiusX = rect.width * 0.46
        let radiusY = rect.height * 0.18
        context.cgContext.setStrokeColor(accent.cgColor)
        for angle in [-31.0, 31.0, 89.0] {
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: center.x, y: center.y)
            context.cgContext.rotate(by: CGFloat(angle * .pi / 180))
            let path = UIBezierPath(ovalIn: CGRect(
                x: -radiusX,
                y: -radiusY,
                width: radiusX * 2,
                height: radiusY * 2
            ))
            path.lineWidth = 1.1
            path.stroke()
            context.cgContext.restoreGState()
        }
        accent.setFill()
        UIBezierPath(ovalIn: CGRect(x: center.x - 2.8, y: center.y - 2.8, width: 5.6, height: 5.6)).fill()
        context.cgContext.restoreGState()
    }

    private func measure(
        _ string: NSString,
        width: CGFloat,
        attributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        ceil(string.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).height)
    }

    private func fittingPrefix(
        _ string: NSString,
        width: CGFloat,
        height: CGFloat,
        attributes: [NSAttributedString.Key: Any]
    ) -> Int {
        guard string.length > 0 else { return 0 }
        var low = 1
        var high = string.length
        var best = 0
        while low <= high {
            let mid = (low + high) / 2
            let prefix = string.substring(to: mid)
            let measured = measure(prefix as NSString, width: width, attributes: attributes)
            if measured <= height {
                best = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        if best == 0 { return min(1, string.length) }
        if best < string.length {
            let range = NSRange(location: 0, length: best)
            let whitespace = string.range(of: " ", options: .backwards, range: range)
            if whitespace.location != NSNotFound, whitespace.location > best / 3 {
                return whitespace.location
            }
            let newline = string.range(of: "\n", options: .backwards, range: range)
            if newline.location != NSNotFound, newline.location > best / 3 {
                return newline.location
            }
        }
        return best
    }
}
