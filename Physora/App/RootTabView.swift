import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showingPersistenceWarning = false

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            Tab("Главная", systemImage: "house.fill", value: AppTab.home) {
                HomeView()
            }
            Tab("История", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView()
            }
            Tab("Справочник", systemImage: "book.closed.fill", value: AppTab.reference) {
                ReferenceView()
            }
            Tab("Инструменты", systemImage: "function", value: AppTab.tools) {
                ToolsView()
            }
            Tab("Настройки", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tint(Color.physoraAccent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .preferredColorScheme(appState.theme.colorScheme)
        .alert("Локальное хранилище", isPresented: $showingPersistenceWarning) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(appState.persistenceMessage ?? "")
        }
        .onAppear {
            showingPersistenceWarning = appState.persistenceMessage != nil
        }
    }
}
