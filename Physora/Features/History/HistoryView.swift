import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SolvedProblem.createdAt, order: .reverse) private var problems: [SolvedProblem]

    @State private var searchText = ""
    @AppStorage("physora.historySort") private var sortRawValue = HistorySortOrder.newest.rawValue
    @State private var showingClearConfirmation = false
    @State private var errorMessage: String?

    private var sortOrder: HistorySortOrder {
        HistorySortOrder(rawValue: sortRawValue) ?? .newest
    }

    private var filteredProblems: [SolvedProblem] {
        var result = appState.historyFilter == .favorites
            ? problems.filter(\.isFavorite)
            : problems
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.prompt.localizedStandardContains(query)
                    || $0.topic.localizedStandardContains(query)
                    || $0.answerSummary.localizedStandardContains(query)
                    || $0.modelTitle.localizedStandardContains(query)
            }
        }
        return result.sorted {
            sortOrder == .newest
                ? $0.createdAt > $1.createdAt
                : $0.createdAt < $1.createdAt
        }
    }

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            ZStack {
                PhysoraBackground()
                VStack(spacing: 0) {
                    Picker("Фильтр истории", selection: $appState.historyFilter) {
                        ForEach(HistoryFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                    if problems.isEmpty {
                        emptyHistory
                    } else if filteredProblems.isEmpty {
                        emptyFilteredState
                    } else {
                        historyList
                    }
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Условие, тема или ответ")
            .navigationDestination(for: SolutionRoute.self) { route in
                SolutionLoaderView(problemID: route.id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
                if !problems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Очистить историю")
                    }
                }
            }
            .confirmationDialog(
                "Очистить всю историю?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Удалить все задачи", role: .destructive) {
                    clearHistory()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Будет удалено решений: \(problems.count). Это действие нельзя отменить.")
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

    private var historyList: some View {
        List {
            if !searchText.isEmpty {
                Text("Найдено: \(filteredProblems.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 2, trailing: 22))
            }
            ForEach(filteredProblems) { problem in
                NavigationLink(value: SolutionRoute(id: problem.id)) {
                    HistoryRow(problem: problem)
                }
                .buttonStyle(PressableScaleButtonStyle())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        toggleFavorite(problem)
                    } label: {
                        Label(
                            problem.isFavorite ? "Убрать" : "В избранное",
                            systemImage: problem.isFavorite ? "star.slash" : "star.fill"
                        )
                    }
                    .tint(.physoraAmber)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(problem)
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        toggleFavorite(problem)
                    } label: {
                        Label(
                            problem.isFavorite ? "Убрать из избранного" : "В избранное",
                            systemImage: problem.isFavorite ? "star.slash" : "star"
                        )
                    }
                    Button(role: .destructive) {
                        delete(problem)
                    } label: {
                        Label("Удалить задачу", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollIndicators(.hidden)
    }

    private var emptyHistory: some View {
        ContentUnavailableView {
            Label("История пока пуста", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Решённые задачи сохраняются на этом iPhone и будут доступны без интернета.")
        } actions: {
            Button("Решить первую задачу") {
                appState.selectedTab = .home
            }
            .buttonStyle(.glassProminent)
            .tint(.physoraAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyFilteredState: some View {
        ContentUnavailableView {
            Label(
                searchText.isEmpty ? "В избранном пусто" : "Ничего не найдено",
                systemImage: searchText.isEmpty ? "star" : "magnifyingglass"
            )
        } description: {
            Text(
                searchText.isEmpty
                    ? "Отмечайте лучшие решения звёздочкой — они появятся здесь."
                    : "Попробуйте изменить запрос или выбрать другой фильтр."
            )
        } actions: {
            if searchText.isEmpty {
                Button("Показать все задачи") {
                    appState.historyFilter = .all
                }
            } else {
                Button("Сбросить поиск") {
                    searchText = ""
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(HistorySortOrder.allCases) { order in
                Button {
                    sortRawValue = order.rawValue
                } label: {
                    Label(order.title, systemImage: order == sortOrder ? "checkmark" : order.systemImage)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Сортировка по дате")
    }

    private func toggleFavorite(_ problem: SolvedProblem) {
        problem.isFavorite.toggle()
        do {
            try modelContext.save()
            Haptics.light()
        } catch {
            problem.isFavorite.toggle()
            errorMessage = "Не удалось обновить избранное: \(error.localizedDescription)"
        }
    }

    private func delete(_ problem: SolvedProblem) {
        withAnimation {
            modelContext.delete(problem)
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Не удалось удалить задачу: \(error.localizedDescription)"
            }
        }
    }

    private func clearHistory() {
        withAnimation {
            for problem in problems {
                modelContext.delete(problem)
            }
            do {
                try modelContext.save()
                Haptics.success()
            } catch {
                errorMessage = "Не удалось очистить историю: \(error.localizedDescription)"
            }
        }
    }
}

enum HistorySortOrder: String, CaseIterable, Identifiable {
    case newest
    case oldest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: "Сначала новые"
        case .oldest: "Сначала старые"
        }
    }

    var systemImage: String {
        switch self {
        case .newest: "arrow.down"
        case .oldest: "arrow.up"
        }
    }
}

private struct HistoryRow: View {
    let problem: SolvedProblem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.physoraAccent.opacity(0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: problem.isFavorite ? "star.fill" : "function")
                    .font(.system(size: 15, weight: .semibold, design: problem.isFavorite ? .default : .serif))
                    .foregroundStyle(problem.isFavorite ? Color.physoraAmber : Color.physoraAccent)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(problem.prompt)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(problem.answerSummary)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !problem.topic.isEmpty {
                        Text(problem.topic)
                            .lineLimit(1)
                    }
                    if !problem.topic.isEmpty {
                        Circle().fill(Color.physoraSeparator).frame(width: 2.5, height: 2.5)
                    }
                    Text(problem.createdAt.physoraShortDate)
                    Text("·")
                    Text(problem.modelTitle)
                    Spacer(minLength: 0)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(15)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(problem.prompt). Ответ: \(problem.answerSummary)")
    }
}
