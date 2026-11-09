import SwiftData
import SwiftUI

@main
@MainActor
struct PhysoraApp: App {
    private let container: ModelContainer
    @State private var appState: AppState

    init() {
        let bootstrap = PersistenceController.makeBootstrap()
        self.container = bootstrap.container
        _appState = State(initialValue: AppState(persistenceMessage: bootstrap.failureMessage))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appState)
                .tint(Color.physoraAccent)
        }
        .modelContainer(container)
    }
}
