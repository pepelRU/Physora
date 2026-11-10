import SwiftUI

// MARK: - Greeting and suggestions

struct ChatGreetingView: View {
    let isConnected: Bool
    let onConnect: () -> Void
    let suggestions: [String]
    let onSuggestion: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 10) {
                BrandTile(size: 30)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Physora")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Привет! Пришли задачу текстом или фото — оформлю решение как в тетради.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !isConnected {
                        Button(action: onConnect) {
                            HStack(spacing: 5) {
                                Image(systemName: "key")
                                    .font(.caption2.weight(.semibold))
                                Text("Подключить DeepSeek")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .overlay(Capsule().strokeBorder(Color.physoraStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !suggestions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            onSuggestion(suggestion)
                        } label: {
                            HStack(alignment: .center, spacing: 10) {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Color.physoraSurface,
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PressableScaleButtonStyle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - User message

struct ChatUserMessageView: View {
    let prompt: String
    var photos: [TaskPhoto] = []

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 44)
            VStack(alignment: .leading, spacing: 9) {
                if !prompt.isEmpty {
                    Text(prompt)
                        .font(.body)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !photos.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(photos) { photo in
                                if let image = photo.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .grayscale(1)
                                        .frame(width: 74, height: 74)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Assistant solution

struct ChatSolutionMessageView: View {
    let problem: SolvedProblem
    let solution: PhysicsSolution
    let onOpen: () -> Void

    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                BrandTile(size: 24)
                Text("Physora")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if !solution.topic.isEmpty {
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(solution.topic)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Text(problem.createdAt.physoraShortDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if appState.showAnalysis, !solution.problemAnalysis.isEmpty {
                assistantTextBlock(title: "Анализ", text: solution.problemAnalysis)
            }

            PhysicsNotebookSheet(solution: solution)

            if appState.showExtraExplanations, !solution.explanation.isEmpty {
                assistantTextBlock(title: "Пояснение", text: solution.explanation)
            }

            HStack {
                Spacer()
                Button(action: onOpen) {
                    HStack(spacing: 5) {
                        Text("Открыть решение")
                        Image(systemName: "arrow.up.right")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .overlay(Capsule().strokeBorder(Color.physoraStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func assistantTextBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 3)
    }
}

// MARK: - In-progress assistant state

struct ChatTypingMessageView: View {
    let phase: SolverViewModel.Phase
    let onCancel: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            BrandTile(size: 30)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Text("Physora")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ProgressView()
                        .controlSize(.mini)
                }
                Text(phase.title)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.opacity)
                Text(phase.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("DeepSeek не передаёт промежуточные статусы модели. Здесь показана реальная обработка приложением.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Отменить", action: onCancel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                    .padding(.top, 2)
            }
            .padding(14)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
            Spacer(minLength: 20)
        }
        .animation(.snappy(duration: 0.25), value: phase)
        .transition(.opacity)
    }
}

struct ChatErrorMessageView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            BrandTile(size: 30)
            VStack(alignment: .leading, spacing: 8) {
                Text("Не удалось получить решение")
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    Button("Повторить", action: onRetry)
                        .font(.caption.weight(.semibold))
                    Button("Убрать", action: onDismiss)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
            Spacer(minLength: 20)
        }
    }
}
