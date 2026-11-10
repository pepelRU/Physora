import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SolvedProblem.createdAt, order: .reverse) private var problems: [SolvedProblem]

    @State private var searchText = ""
    @State private var showingClearConfirmation = false
    @State private var errorMessage: String?

    private var chatGroups: [ChatGroup] {
        let grouped = Dictionary(grouping: problems) { $0.effectiveChatID }
        return grouped.compactMap { id, items in
            let ordered = items.sorted { $0.createdAt < $1.createdAt }
            guard let first = ordered.first, let last = ordered.last else { return nil }
            return ChatGroup(
                id: id,
                title: first.prompt,
                preview: last.answerSummary,
                topic: first.topic,
                date: last.createdAt,
                count: ordered.count,
                problems: ordered
            )
        }
        .sorted { $0.date > $1.date }
    }

    private var filteredGroups: [ChatGroup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return chatGroups }
        return chatGroups.filter { group in
            group.title.localizedStandardContains(query)
                || group.preview.localizedStandardContains(query)
                || group.topic.localizedStandardContains(query)
                || group.problems.contains {
                    $0.prompt.localizedStandardContains(query)
                        || $0.answerSummary.localizedStandardContains(query)
                }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PhysoraBackground()

                if problems.isEmpty {
                    emptyState
                } else if filteredGroups.isEmpty {
                    emptySearchState
                } else {
                    chatList
                }
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Найти чат или задачу")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Закрыть чаты")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.startNewChat()
                        dismiss()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Новый чат")
                }
                if !problems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Очистить все чаты")
                    }
                }
            }
            .confirmationDialog(
                "Очистить все чаты?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Удалить все чаты", role: .destructive) {
                    clearAll()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Будет удалено задач: \(problems.count). Это действие нельзя отменить.")
            }
            .alert(
                "Ошибка",
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
    }

    private var chatList: some View {
        List {
            ForEach(filteredGroups) { group in
                Button {
                    appState.openChat(group.id)
                    Haptics.light()
                    dismiss()
                } label: {
                    ChatGroupRow(
                        group: group,
                        isCurrent: group.id == appState.currentChatID
                    )
                }
                .buttonStyle(PressableScaleButtonStyle())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(group)
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        delete(group)
                    } label: {
                        Label("Удалить чат", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Чатов пока нет", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Начните новый чат и пришлите задачу текстом или фотографией.")
        } actions: {
            Button("Новый чат") {
                appState.startNewChat()
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .tint(.physoraAccent)
        }
    }

    private var emptySearchState: some View {
        ContentUnavailableView {
            Label("Ничего не найдено", systemImage: "magnifyingglass")
        } description: {
            Text("Попробуйте изменить запрос.")
        } actions: {
            Button("Сбросить поиск") {
                searchText = ""
            }
        }
    }

    private func delete(_ group: ChatGroup) {
        withAnimation {
            for problem in group.problems {
                modelContext.delete(problem)
            }
            if group.id == appState.currentChatID {
                appState.startNewChat()
            }
            do {
                try modelContext.save()
                Haptics.success()
            } catch {
                errorMessage = "Не удалось удалить чат: \(error.localizedDescription)"
            }
        }
    }

    private func clearAll() {
        withAnimation {
            for problem in problems {
                modelContext.delete(problem)
            }
            appState.startNewChat()
            do {
                try modelContext.save()
                Haptics.success()
            } catch {
                errorMessage = "Не удалось очистить чаты: \(error.localizedDescription)"
            }
        }
    }
}

private struct ChatGroup: Identifiable {
    let id: UUID
    let title: String
    let preview: String
    let topic: String
    let date: Date
    let count: Int
    let problems: [SolvedProblem]
}

private struct ChatGroupRow: View {
    let group: ChatGroup
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                Circle()
                    .fill(Color.physoraSurfaceMuted)
                    .frame(width: 42, height: 42)
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(group.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    if isCurrent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }

                Text(group.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if !group.topic.isEmpty {
                        Text(group.topic)
                            .lineLimit(1)
                    }
                    Text("·")
                    Text(group.date.physoraShortDate)
                    Text("·")
                    Text("\(group.count) \(solutionsWord(group.count))")
                    Spacer(minLength: 0)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(15)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .strokeBorder(isCurrent ? Color.primary.opacity(0.35) : Color.physoraStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.title). Задач: \(group.count)")
    }

    private func solutionsWord(_ count: Int) -> String {
        let remainder100 = count % 100
        let remainder10 = count % 10
        if (11...14).contains(remainder100) { return "решений" }
        switch remainder10 {
        case 1: return "решение"
        case 2, 3, 4: return "решения"
        default: return "решений"
        }
    }
}
