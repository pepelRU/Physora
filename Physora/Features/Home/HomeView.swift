import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SolvedProblem.createdAt, order: .reverse) private var problems: [SolvedProblem]

    @State private var navigationPath = NavigationPath()
    @State private var solver = SolverViewModel()
    @State private var solveTask: Task<Void, Never>?
    @State private var photos: [TaskPhoto] = []
    @State private var pendingPrompt: String?
    @State private var pendingPhotos: [TaskPhoto] = []
    @State private var isSending = false
    @State private var solveErrorMessage: String?
    @State private var storageWarning: String?
    @State private var activeSheet: HomeSheet?
    @State private var activeAlert: HomeAlert?
    @State private var didOpenScreenshotDestination = false
    @FocusState private var isComposerFocused: Bool

    private var chatProblems: [SolvedProblem] {
        problems.filter { $0.effectiveChatID == appState.currentChatID }
    }

    private var chronologicalProblems: [SolvedProblem] {
        Array(chatProblems).reversed()
    }

    private var suggestions: [String] {
        guard chatProblems.isEmpty, pendingPrompt == nil else { return [] }
        return [
            "Тело массой 2 кг движется с ускорением 3 м/с². Найдите силу.",
            "Найдите кинетическую энергию автомобиля 1,2 т при скорости 72 км/ч.",
            "Брусок на наклонной плоскости 30°, коэффициент трения 0,2. Найдите ускорение."
        ]
    }

    var body: some View {
        @Bindable var appState = appState
        NavigationStack(path: $navigationPath) {
            ZStack {
                PhysoraBackground()
                VStack(spacing: 0) {
                    homeHeader
                    chatScroll
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SolutionRoute.self) { route in
                SolutionLoaderView(problemID: route.id)
            }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .history:
                    HistoryView()
                case .tools:
                    ToolsView()
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .missingKey:
                    Alert(
                        title: Text("Подключите DeepSeek"),
                        message: Text("Добавьте API-ключ в настройках. Ключ хранится только в Apple Keychain."),
                        primaryButton: .default(Text("Открыть настройки")) {
                            appState.showSettings()
                        },
                        secondaryButton: .cancel(Text("Позже"))
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
    }

    // MARK: - Header

    private var homeHeader: some View {
        ZStack {
            HStack(spacing: 10) {
                circleButton(systemImage: "clock", label: "История") {
                    activeSheet = .history
                }
                circleButton(systemImage: "slider.horizontal.3", label: "Инструменты") {
                    activeSheet = .tools
                }
                Spacer(minLength: 8)
                circleButton(systemImage: "square.and.pencil", label: "Новый чат") {
                    startNewChat()
                }
            }

            BrandLockup(markSize: 26)
        }
        .padding(.horizontal, 16)
        .padding(.top, 5)
        .padding(.bottom, 7)
    }

    private func circleButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.primary)
                .frame(width: 38, height: 38)
                .background(Color.physoraSurface, in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.physoraStroke, lineWidth: 1)
                )
        }
        .buttonStyle(PressableScaleButtonStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Conversation

    private var chatScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ChatGreetingView(
                        isConnected: appState.hasStoredAPIKey,
                        onConnect: { appState.showSettings() },
                        suggestions: suggestions,
                        onSuggestion: { suggestion in
                            appState.composerDraft = suggestion
                            isComposerFocused = true
                        }
                    )

                    if let storageWarning {
                        Text(storageWarning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(chronologicalProblems) { problem in
                        if let solution = problem.solution {
                            chatTurn(problem: problem, solution: solution)
                        }
                    }

                    if let pendingPrompt {
                        ChatUserMessageView(prompt: pendingPrompt, photos: pendingPhotos)

                        if isSending {
                            ChatTypingMessageView(phase: solver.phase) {
                                cancelSolving()
                            }
                        } else if let solveErrorMessage {
                            ChatErrorMessageView(
                                message: solveErrorMessage,
                                onRetry: retrySolving,
                                onDismiss: dismissFailedMessage
                            )
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("chat-bottom")
                }
                .padding(.horizontal, 15)
                .padding(.top, 6)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .onAppear {
                scrollToBottom(proxy, animated: false)
            }
            .task {
                openScreenshotDestinationIfNeeded()
            }
            .onChange(of: chatProblems.count) { _, _ in
                scrollToBottom(proxy)
                openScreenshotDestinationIfNeeded()
            }
            .onChange(of: appState.currentChatID) { _, _ in
                scrollToBottom(proxy, animated: false)
            }
            .onChange(of: pendingPrompt) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: isSending) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: solveErrorMessage) { _, _ in
                scrollToBottom(proxy)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatComposerView(
                text: $appState.composerDraft,
                photos: $photos,
                isFocused: $isComposerFocused,
                isSending: isSending,
                onSend: sendMessage
            )
        }
    }

    private func chatTurn(problem: SolvedProblem, solution: PhysicsSolution) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ChatUserMessageView(prompt: problem.prompt)
            ChatSolutionMessageView(problem: problem, solution: solution) {
                navigationPath.append(SolutionRoute(id: problem.id))
            }
        }
    }

    // MARK: - Sending

    private func sendMessage() {
        guard !isSending else { return }
        let prompt = appState.composerDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = photos
        guard !prompt.isEmpty || !attachments.isEmpty else { return }

        let key: String
        do {
            guard let stored = try KeychainManager.readAPIKey(), !stored.isEmpty else {
                activeAlert = .missingKey
                return
            }
            key = stored
        } catch {
            activeAlert = .missingKey
            return
        }

        appState.composerDraft = ""
        photos = []
        pendingPrompt = prompt
        pendingPhotos = attachments
        solveErrorMessage = nil
        storageWarning = nil
        isSending = true
        isComposerFocused = false
        solver.reset()
        beginSolve(prompt: prompt, photos: attachments, key: key)
    }

    private func beginSolve(prompt: String, photos: [TaskPhoto], key: String) {
        solveTask?.cancel()
        let preferences = appState.solutionPreferences
        let modelID = appState.modelID
        let chatID = appState.currentChatID
        let history = chatProblems
            .sorted { $0.createdAt < $1.createdAt }
            .suffix(8)
            .map {
                ChatMemoryTurn(
                    prompt: $0.prompt,
                    answer: $0.answerSummary,
                    topic: $0.topic
                )
            }

        solveTask = Task { @MainActor in
            do {
                let solution = try await solver.solve(
                    problem: prompt,
                    apiKey: key,
                    modelID: modelID,
                    preferences: preferences,
                    images: photos.map(\.data),
                    history: history
                )
                try Task.checkCancellation()
                solver.markSaving()

                let transcribed = solution.problemStatement.trimmingCharacters(in: .whitespacesAndNewlines)
                let storedPrompt = transcribed.isEmpty ? prompt : transcribed
                let effectiveModelID = photos.isEmpty ? modelID : "deepseek-flash"
                let problem = SolvedProblem(
                    prompt: storedPrompt.isEmpty ? "Задача на фотографии" : storedPrompt,
                    solution: solution,
                    modelID: effectiveModelID,
                    chatID: chatID
                )
                modelContext.insert(problem)
                do {
                    try modelContext.save()
                } catch {
                    storageWarning = "Решение готово, но сохранить его в историю не удалось."
                }
                try Task.checkCancellation()

                solver.complete()
                isSending = false
                pendingPrompt = nil
                pendingPhotos = []
                solveErrorMessage = nil
                Haptics.success()
            } catch is CancellationError {
                isSending = false
                solver.reset()
            } catch {
                solver.reset()
                isSending = false
                solveErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func retrySolving() {
        guard !isSending, let prompt = pendingPrompt else { return }
        let key: String
        do {
            guard let stored = try KeychainManager.readAPIKey(), !stored.isEmpty else {
                activeAlert = .missingKey
                return
            }
            key = stored
        } catch {
            activeAlert = .missingKey
            return
        }
        solveErrorMessage = nil
        isSending = true
        solver.reset()
        beginSolve(prompt: prompt, photos: pendingPhotos, key: key)
    }

    private func cancelSolving() {
        solveTask?.cancel()
        solveTask = nil
        isSending = false
        solver.reset()
        appState.composerDraft = pendingPrompt ?? ""
        photos = pendingPhotos
        pendingPrompt = nil
        pendingPhotos = []
        solveErrorMessage = nil
    }

    private func dismissFailedMessage() {
        appState.composerDraft = pendingPrompt ?? ""
        photos = pendingPhotos
        pendingPrompt = nil
        pendingPhotos = []
        solveErrorMessage = nil
    }

    private func startNewChat() {
        solveTask?.cancel()
        solveTask = nil
        isSending = false
        solver.reset()
        photos = []
        pendingPrompt = nil
        pendingPhotos = []
        solveErrorMessage = nil
        storageWarning = nil
        navigationPath = NavigationPath()
        appState.startNewChat()
        Haptics.light()
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            if animated {
                withAnimation(.snappy(duration: 0.28)) {
                    proxy.scrollTo("chat-bottom", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("chat-bottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Screenshot automation

    @MainActor
    private func openScreenshotDestinationIfNeeded() {
        #if DEBUG
        guard ScreenshotMode.isActive, !didOpenScreenshotDestination else { return }
        guard let destination = ScreenshotMode.screen else { return }

        if chronologicalProblems.isEmpty && destination != .history && destination != .tools {
            return
        }

        didOpenScreenshotDestination = true
        switch destination {
        case .solution:
            guard let first = chronologicalProblems.first else { return }
            navigationPath.append(SolutionRoute(id: first.id))
        case .history:
            activeSheet = .history
        case .tools:
            activeSheet = .tools
        }
        #endif
    }
}

private enum HomeSheet: String, Identifiable {
    case history
    case tools

    var id: String { rawValue }
}

private enum HomeAlert: Identifiable {
    case missingKey

    var id: String { "missing-key" }
}
