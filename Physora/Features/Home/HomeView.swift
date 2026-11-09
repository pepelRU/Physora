import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SolvedProblem.createdAt, order: .reverse) private var problems: [SolvedProblem]

    @State private var navigationPath = NavigationPath()
    @State private var solver = SolverViewModel()
    @State private var solveTask: Task<Void, Never>?
    @State private var isSolvingPresented = false
    @State private var pendingRouteID: UUID?
    @State private var activeAlert: HomeAlert?
    @State private var pendingAlert: HomeAlert?
    @State private var storageWarning: String?
    @FocusState private var isComposerFocused: Bool

    private var recentProblems: [SolvedProblem] { Array(problems.prefix(3)) }
    private var favoriteCount: Int { problems.filter(\.isFavorite).count }

    var body: some View {
        @Bindable var appState = appState
        NavigationStack(path: $navigationPath) {
            ZStack {
                PhysoraBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        greeting
                        if !appState.hasStoredAPIKey {
                            connectBanner
                        }
                        TaskComposerView(
                            text: $appState.composerDraft,
                            isFocused: $isComposerFocused,
                            onSolve: startSolving
                        )
                        if let storageWarning {
                            storageWarningBanner(storageWarning)
                        }
                        quickAccess
                        recentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandLockup(markSize: 28)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.showSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.subheadline.weight(.semibold))
                    }
                    .accessibilityLabel("Настройки")
                }
            }
            .navigationDestination(for: SolutionRoute.self) { route in
                SolutionLoaderView(problemID: route.id)
            }
            .fullScreenCover(isPresented: $isSolvingPresented, onDismiss: handleSolvingDismissed) {
                SolvingProgressView(phase: solver.phase) {
                    cancelSolving()
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .missingKey:
                    Alert(
                        title: Text("Подключите DeepSeek"),
                        message: Text("Для решения задач нужен API-ключ. Ключ хранится только в Apple Keychain и не попадает в историю или исходный код."),
                        primaryButton: .default(Text("Открыть настройки")) {
                            appState.showSettings()
                        },
                        secondaryButton: .cancel(Text("Позже"))
                    )
                case .error(let message):
                    Alert(
                        title: Text("Не удалось решить задачу"),
                        message: Text(message),
                        dismissButton: .default(Text("Понятно"))
                    )
                }
            }
        }
        .onChange(of: appState.composerFocusRequest) { _, _ in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                isComposerFocused = true
            }
        }
        .onDisappear {
            if !isSolvingPresented {
                solveTask?.cancel()
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(timeGreeting)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.physoraAccent)
                Circle()
                    .fill(Color.physoraAccent.opacity(0.4))
                    .frame(width: 3, height: 3)
                Text(Date.now.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "ru_RU"))))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Разберём задачу по физике")
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .fixedSize(horizontal: false, vertical: true)
            Text("Условие, формулы, чертёж и оформление — в одном решении.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if appState.hasStoredAPIKey {
                ConnectedPill(modelTitle: appState.modelTitle) {
                    appState.showSettings()
                }
                .padding(.top, 4)
            }
        }
    }

    private var connectBanner: some View {
        Button {
            appState.showSettings()
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "key.horizontal.fill")
                    .font(.headline)
                    .foregroundStyle(Color.physoraAmber)
                    .frame(width: 40, height: 40)
                    .background(Color.physoraAmber.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Подключите DeepSeek")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    Text("Добавьте API-ключ, чтобы решать задачи")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Text("Настроить")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
            }
            .padding(14)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.physoraAmber.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(PressableScaleButtonStyle())
    }

    private var quickAccess: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Быстрый доступ", systemImage: "square.grid.2x2")
            HStack(spacing: 10) {
                QuickAccessCard(
                    title: "История",
                    subtitle: "\(problems.count) задач",
                    systemImage: "clock.arrow.circlepath",
                    tint: .physoraAccent,
                    action: { appState.showHistory() }
                )
                QuickAccessCard(
                    title: "Избранное",
                    subtitle: "\(favoriteCount) сохранено",
                    systemImage: "star.fill",
                    tint: .physoraAmber,
                    action: { appState.showFavorites() }
                )
                QuickAccessCard(
                    title: "Настройки",
                    subtitle: appState.modelTitle,
                    systemImage: "gearshape.fill",
                    tint: .physoraMint,
                    action: { appState.showSettings() }
                )
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PhysoraSectionHeader("Последние решения", systemImage: "sparkles")
                Spacer()
                if !problems.isEmpty {
                    Button("Вся история") {
                        appState.showHistory()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
                }
            }
            if recentProblems.isEmpty {
                emptyRecent
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(recentProblems) { problem in
                        RecentSolutionCard(problem: problem)
                    }
                }
            }
        }
    }

    private var emptyRecent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 13) {
                BrandTile(size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Здесь появятся решения")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                    Text("Первая задача займёт около минуты.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                isComposerFocused = true
            } label: {
                Label("Написать условие", systemImage: "square.and.pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .physoraCard(padding: 16, cornerRadius: 22)
    }

    private func storageWarningBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.physoraAmber)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                storageWarning = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Скрыть предупреждение")
        }
        .padding(13)
        .background(Color.physoraAmber.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.physoraAmber.opacity(0.18), lineWidth: 1)
        )
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<18: return "Добрый день"
        case 18..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    private func startSolving() {
        let prompt = appState.composerDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        let key: String
        do {
            guard let stored = try KeychainManager.readAPIKey(), !stored.isEmpty else {
                activeAlert = .missingKey
                return
            }
            key = stored
        } catch {
            activeAlert = .error(error.localizedDescription)
            return
        }

        isComposerFocused = false
        storageWarning = nil
        pendingRouteID = nil
        solver.reset()
        let preferences = appState.solutionPreferences
        let modelID = appState.modelID

        isSolvingPresented = true
        solveTask?.cancel()
        solveTask = Task { @MainActor in
            do {
                let solution = try await solver.solve(
                    problem: prompt,
                    apiKey: key,
                    modelID: modelID,
                    preferences: preferences
                )
                try Task.checkCancellation()
                solver.markSaving()

                let problem = SolvedProblem(prompt: prompt, solution: solution, modelID: modelID)
                modelContext.insert(problem)
                do {
                    try modelContext.save()
                } catch {
                    storageWarning = "Решение готово, но сохранить его в историю не удалось. Данные останутся доступны только до закрытия приложения."
                }
                try Task.checkCancellation()
                pendingRouteID = problem.id
                solver.complete()
                Haptics.success()
                isSolvingPresented = false
            } catch is CancellationError {
                isSolvingPresented = false
            } catch {
                pendingRouteID = nil
                pendingAlert = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
                isSolvingPresented = false
            }
        }
    }

    private func cancelSolving() {
        solveTask?.cancel()
        solveTask = nil
        pendingRouteID = nil
        isSolvingPresented = false
    }

    private func handleSolvingDismissed() {
        if let routeID = pendingRouteID {
            pendingRouteID = nil
            navigationPath.append(SolutionRoute(id: routeID))
        }
        if let alert = pendingAlert {
            pendingAlert = nil
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                activeAlert = alert
            }
        }
    }
}

private enum HomeAlert: Identifiable {
    case missingKey
    case error(String)

    var id: String {
        switch self {
        case .missingKey: "missing-key"
        case .error(let message): "error-\(message)"
        }
    }
}
