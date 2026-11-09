import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showingPersistenceWarning = false

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: AppTab.home) {
                HomeView()
            }
            Tab(AppTab.history.title, systemImage: AppTab.history.icon, value: AppTab.history) {
                HistoryView()
            }
            Tab(AppTab.reference.title, systemImage: AppTab.reference.icon, value: AppTab.reference) {
                ReferenceView()
            }
            Tab(AppTab.tools.title, systemImage: AppTab.tools.icon, value: AppTab.tools) {
                ToolsView()
            }
            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: AppTab.settings) {
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
