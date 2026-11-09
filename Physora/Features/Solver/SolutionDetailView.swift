import SwiftData
import SwiftUI

struct SolutionDetailView: View {
    let problem: SolvedProblem
    let solution: PhysicsSolution

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize

    @AppStorage("physora.solutionTypeStep") private var typeStep = 0
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    @State private var isPreparingPDF = false
    @State private var copiedAll = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                metadataHeader
                aiNotice
                conditionSection
                analysisSection
                givenFindSection
                siSection
                formulasSection
                solutionSection
                calculationsSection
                diagramsSection
                graphsSection
                answerSection
                explanationSection
                warningsSection
                sourceFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
        .background(PhysoraBackground())
        .navigationTitle("Решение")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: problem.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(problem.isFavorite ? Color.physoraAmber : Color.primary)
                }
                .accessibilityLabel(problem.isFavorite ? "Убрать из избранного" : "Добавить в избранное")

                Button {
                    generatePDF()
                } label: {
                    Image(systemName: "doc.badge.arrow.up")
                }
                .disabled(isPreparingPDF)
                .accessibilityLabel("Экспортировать решение в PDF")

                Menu {
                    Button {
                        copyAll()
                    } label: {
                        Label("Копировать всё решение", systemImage: "doc.on.doc")
                    }

                    ShareLink(
                        item: fullText,
                        preview: SharePreview("Решение Physora")
                    ) {
                        Label("Поделиться текстом", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        generatePDF()
                    } label: {
                        Label("Экспорт в PDF", systemImage: "doc.richtext")
                    }

                    Divider()

                    Button {
                        reSolve()
                    } label: {
                        Label("Решить это условие снова", systemImage: "arrow.clockwise")
                    }

                    Divider()

                    Section("Размер текста") {
                        Button {
                            typeStep = max(-1, typeStep - 1)
                        } label: {
                            Label("Уменьшить текст", systemImage: "textformat.size.smaller")
                        }
                        .disabled(typeStep <= -1)

                        Button {
                            typeStep = min(2, typeStep + 1)
                        } label: {
                            Label("Увеличить текст", systemImage: "textformat.size.larger")
                        }
                        .disabled(typeStep >= 2)

                        if typeStep != 0 {
                            Button {
                                typeStep = 0
                            } label: {
                                Label("Сбросить размер", systemImage: "arrow.counterclockwise")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Другие действия")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActionBar
        }
        .environment(\.dynamicTypeSize, adjustedDynamicTypeSize)
        .sheet(isPresented: $showingShareSheet) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
                    .ignoresSafeArea()
            }
        }
        .overlay {
            if isPreparingPDF {
                pdfProgressOverlay
            }
        }
        .alert(
            "Не удалось выполнить действие",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Header and notices

    private var metadataHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                CapsuleTag(
                    text: solution.topic.isEmpty ? "Физика" : solution.topic,
                    systemImage: "atom",
                    tint: .physoraAccent
                )
                Spacer()
                Text(problem.createdAt.physoraShortDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.caption2)
                Text(problem.modelTitle)
                Circle().fill(Color.physoraSeparator).frame(width: 2.5, height: 2.5)
                Text("локальное оформление")
                Spacer()
                if problem.isFavorite {
                    Label("В избранном", systemImage: "star.fill")
                        .foregroundStyle(Color.physoraAmber)
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    private var aiNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.physoraAmber)
                .padding(.top, 1)
            Text("Решение сгенерировано DeepSeek. Physora проверила структуру JSON и построила оформление, но не заменяет проверку учителя: AI может ошибаться в физике и единицах.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.physoraAmber.opacity(0.075), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.physoraAmber.opacity(0.16), lineWidth: 1)
        )
    }

    // MARK: Solution sections

    private var conditionSection: some View {
        SolutionBlock(
            "Условие",
            systemImage: "text.alignleft",
            copyText: problem.prompt
        ) {
            Text(problem.prompt)
                .font(.body)
                .lineSpacing(2.5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var analysisSection: some View {
        if !solution.problemAnalysis.isEmpty {
            SolutionBlock(
                "Анализ задачи",
                systemImage: "lightbulb",
                copyText: solution.problemAnalysis
            ) {
                Text(solution.problemAnalysis)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var givenFindSection: some View {
        if !solution.given.isEmpty || !solution.find.isEmpty {
            GivenFindBlock(solution: solution)
        }
    }

    @ViewBuilder
    private var siSection: some View {
        if !solution.siConversions.isEmpty || !solution.siNote.isEmpty {
            SolutionBlock(
                "Перевод в СИ",
                systemImage: "arrow.triangle.2.circlepath",
                accent: .physoraMint,
                copyText: siCopyText
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if !solution.siNote.isEmpty {
                        Text(solution.siNote)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(Array(solution.siConversions.enumerated()), id: \.offset) { _, conversion in
                        VStack(alignment: .leading, spacing: 6) {
                            if !conversion.quantity.isEmpty {
                                Text(conversion.quantity.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .tracking(0.8)
                                    .foregroundStyle(Color.physoraMint)
                            }
                            HStack(spacing: 7) {
                                FormulaView(conversion.from, fontSize: 18)
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.tertiary)
                                FormulaView(conversion.to, fontSize: 18, foregroundStyle: .physoraAccent)
                            }
                            if !conversion.note.isEmpty {
                                Text(conversion.note)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var formulasSection: some View {
        if !solution.formulas.isEmpty {
            SolutionBlock(
                "Формулы",
                systemImage: "function",
                copyText: SolutionTextFormatter.formulasText(solution)
            ) {
                FormulaRows(formulas: solution.formulas)
            }
        }
    }

    @ViewBuilder
    private var solutionSection: some View {
        if !solution.solutionSteps.isEmpty {
            SolutionBlock(
                "Решение",
                systemImage: "pencil.and.ruler",
                copyText: stepsCopyText
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(solution.solutionSteps.enumerated()), id: \.offset) { index, step in
                        SolutionStepRow(
                            index: index,
                            step: step,
                            isLast: index == solution.solutionSteps.count - 1
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var calculationsSection: some View {
        if !solution.calculations.isEmpty {
            SolutionBlock(
                "Вычисления",
                systemImage: "number",
                copyText: calculationsCopyText
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(solution.calculations.enumerated()), id: \.offset) { _, calculation in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                FormulaView(calculation.expression, fontSize: 19)
                                if !calculation.result.isEmpty {
                                    Text("=")
                                        .font(.system(size: 19, weight: .regular, design: .serif))
                                        .foregroundStyle(.secondary)
                                    FormulaView(
                                        calculation.result + (calculation.unit.isEmpty ? "" : " \(calculation.unit)"),
                                        fontSize: 19,
                                        foregroundStyle: .physoraAccent
                                    )
                                }
                            }
                            if !calculation.note.isEmpty {
                                Text(calculation.note)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var diagramsSection: some View {
        if !solution.diagrams.isEmpty {
            SolutionBlock(
                solution.diagrams.count == 1 ? "Чертёж" : "Чертежи",
                systemImage: "scribble.variable",
                copyText: solution.diagrams.map(\.title).joined(separator: "\n")
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(solution.diagrams.enumerated()), id: \.offset) { _, diagram in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(diagram.title)
                                .font(.subheadline.weight(.semibold))
                            DiagramView(diagram: diagram)
                                .padding(10)
                                .background(
                                    Color.physoraSurfaceMuted.opacity(0.48),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.physoraSeparator.opacity(0.7), lineWidth: 0.8)
                                )
                            Text("Схема построена приложением из графических примитивов")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var graphsSection: some View {
        if !solution.graphs.isEmpty {
            SolutionBlock(
                solution.graphs.count == 1 ? "График" : "Графики",
                systemImage: "chart.xyaxis.line",
                copyText: solution.graphs.map(\.title).joined(separator: "\n")
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(solution.graphs.enumerated()), id: \.offset) { _, graph in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(graph.title)
                                .font(.subheadline.weight(.semibold))
                            PhysicsGraphView(graph: graph)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var answerSection: some View {
        if solution.finalAnswer.isEmpty {
            SolutionBlock(
                "Ответ",
                systemImage: "questionmark.circle",
                accent: .physoraAmber,
                copyText: solution.warnings.joined(separator: "\n")
            ) {
                Text("Однозначный ответ не сформирован. В условии может не хватать данных — проверьте раздел «Проверьте» ниже.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            answerCard
        }
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Ответ", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.physoraAccent)
                Spacer()
                FormulaCopyButton(SolutionTextFormatter.finalAnswerText(solution))
            }
            ForEach(Array(solution.finalAnswer.enumerated()), id: \.offset) { _, answer in
                FormulaView(
                    "\(answer.symbol) = \(answer.value) \(answer.unit)",
                    fontSize: 28,
                    foregroundStyle: .primary
                )
            }
            Text("Проверьте размерность и округление перед записью в тетрадь.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.physoraAccent.opacity(0.16),
                    Color.physoraAccent.opacity(0.055)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(Color.physoraAccent.opacity(0.25), lineWidth: 1)
        )
        .contextMenu {
            Button {
                Clipboard.copy(SolutionTextFormatter.finalAnswerText(solution))
            } label: {
                Label("Скопировать ответ", systemImage: "doc.on.doc")
            }
        }
    }

    @ViewBuilder
    private var explanationSection: some View {
        if appState.showExtraExplanations, !solution.explanation.isEmpty {
            SolutionBlock(
                "Пояснение",
                systemImage: "text.quote",
                accent: .physoraMint,
                copyText: solution.explanation
            ) {
                Text(solution.explanation)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var warningsSection: some View {
        if !solution.warnings.isEmpty {
            SolutionBlock(
                "Проверьте",
                systemImage: "exclamationmark.triangle",
                accent: .physoraAmber,
                copyText: solution.warnings.map { "• \($0)" }.joined(separator: "\n")
            ) {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(solution.warnings.enumerated()), id: \.offset) { _, warning in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.physoraAmber)
                                .frame(width: 4, height: 4)
                                .padding(.top, 7)
                            Text(warning)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var sourceFooter: some View {
        VStack(spacing: 5) {
            BrandLockup(markSize: 26, showsTagline: false)
                .opacity(0.74)
            Text("Physics, clearly · решение сохранено локально")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    // MARK: Actions

    private var bottomActionBar: some View {
        HStack(spacing: 0) {
            actionBarButton(
                title: isPreparingPDF ? "Готовим…" : "PDF",
                systemImage: "doc.richtext",
                busy: isPreparingPDF
            ) {
                generatePDF()
            }
            actionDivider
            actionBarButton(
                title: copiedAll ? "Скопировано" : "Копировать",
                systemImage: copiedAll ? "checkmark" : "doc.on.doc"
            ) {
                copyAll()
            }
            actionDivider
            actionBarButton(title: "Повторить", systemImage: "arrow.clockwise") {
                reSolve()
            }
        }
        .padding(6)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var actionDivider: some View {
        Rectangle()
            .fill(Color.physoraSeparator)
            .frame(width: 1, height: 22)
    }

    private func actionBarButton(
        title: String,
        systemImage: String,
        busy: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if busy {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Color.physoraAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private var pdfProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()
            HStack(spacing: 12) {
                ProgressView()
                    .tint(Color.physoraAccent)
                Text("Готовим PDF-лист…")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
        }
        .transition(.opacity)
    }

    private var fullText: String {
        SolutionTextFormatter.full(
            prompt: problem.prompt,
            solution: solution,
            modelTitle: problem.modelTitle,
            date: problem.createdAt
        )
    }

    private var siCopyText: String {
        var lines: [String] = []
        if !solution.siNote.isEmpty { lines.append(solution.siNote) }
        lines.append(contentsOf: solution.siConversions.map {
            "\($0.quantity): \($0.from) → \($0.to)"
        })
        return lines.joined(separator: "\n")
    }

    private var stepsCopyText: String {
        solution.solutionSteps.enumerated().map {
            SolutionTextFormatter.stepText($0.element, number: $0.offset + 1)
        }.joined(separator: "\n\n")
    }

    private var calculationsCopyText: String {
        solution.calculations.map {
            var line = $0.expression
            if !$0.result.isEmpty { line += " = \($0.result)" }
            if !$0.unit.isEmpty { line += " \($0.unit)" }
            return line
        }.joined(separator: "\n")
    }

    private func copyAll() {
        guard Clipboard.copy(fullText) else { return }
        withAnimation(.snappy) { copiedAll = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.snappy) { copiedAll = false }
        }
    }

    private func toggleFavorite() {
        problem.isFavorite.toggle()
        do {
            try modelContext.save()
            Haptics.light()
        } catch {
            problem.isFavorite.toggle()
            errorMessage = "Не удалось обновить избранное: \(error.localizedDescription)"
        }
    }

    private func generatePDF() {
        guard !isPreparingPDF else { return }
        isPreparingPDF = true
        Task { @MainActor in
            await Task.yield()
            do {
                let url = try SolutionPDFRenderer.temporaryPDFURL(
                    prompt: problem.prompt,
                    solution: solution,
                    modelTitle: problem.modelTitle,
                    date: problem.createdAt
                )
                pdfURL = url
                isPreparingPDF = false
                showingShareSheet = true
            } catch {
                isPreparingPDF = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func reSolve() {
        appState.prepareReSolution(prompt: problem.prompt)
        dismiss()
    }

    private var adjustedDynamicTypeSize: DynamicTypeSize {
        let sizes: [DynamicTypeSize] = [
            .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
            .accessibility1, .accessibility2, .accessibility3,
            .accessibility4, .accessibility5
        ]
        guard let index = sizes.firstIndex(of: systemDynamicTypeSize) else {
            return systemDynamicTypeSize
        }
        let adjusted = min(max(index + typeStep, 0), sizes.count - 1)
        return sizes[adjusted]
    }
}
