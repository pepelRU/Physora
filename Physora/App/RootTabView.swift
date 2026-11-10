import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    @State private var showingPersistenceWarning = false

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            Tab("Главная", systemImage: "house.fill", value: AppTab.home) {
                HomeView()
            }
            Tab("Справочник", systemImage: "book.closed.fill", value: AppTab.reference) {
                ReferenceView()
            }
            Tab("Настройки", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tint(Color.physoraAccent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(
            \.dynamicTypeSize,
            appState.interfaceSize.adjusted(systemDynamicTypeSize)
        )
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
