import Foundation
import SwiftData

enum PersistenceController {
    struct Bootstrap {
        let container: ModelContainer
        let failureMessage: String?
    }

    @MainActor
    static func makeBootstrap() -> Bootstrap {
        do {
            return Bootstrap(container: try makeContainer(inMemory: false), failureMessage: nil)
        } catch {
            do {
                return Bootstrap(
                    container: try makeContainer(inMemory: true),
                    failureMessage: "Не удалось открыть локальную историю. Задачи сохранятся только до закрытия приложения."
                )
            } catch {
                // ModelContainer can only fail here if the schema itself is invalid.
                fatalError("Не удалось инициализировать SwiftData: \(error.localizedDescription)")
            }
        }
    }

    private static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([SolvedProblem.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
