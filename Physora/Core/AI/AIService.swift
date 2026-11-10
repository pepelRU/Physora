import Foundation

/// Abstraction shared by every AI provider. A new provider only needs to
/// implement this protocol and be returned by the factory.
protocol AIService: Sendable {
    var provider: AIProvider { get }
    var modelID: String { get }

    func solve(
        problem: String,
        preferences: SolutionPreferences,
        images: [Data],
        history: [ChatMemoryTurn]
    ) async throws -> PhysicsSolution
    func checkConnection() async throws -> ConnectionCheck
}

enum AIServiceFactory {
    static func make(provider: AIProvider, apiKey: String, modelID: String) -> any AIService {
        switch provider {
        case .deepSeek:
            DeepSeekService(apiKey: apiKey, modelID: modelID)
        }
    }
}
