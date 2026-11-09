import Foundation
import SwiftData

@Model
final class SolvedProblem {
    @Attribute(.unique) var id: UUID
    var prompt: String
    var topic: String
    var answerSummary: String
    var createdAt: Date
    var modelID: String
    var isFavorite: Bool
    var solutionData: Data

    init(
        id: UUID = UUID(),
        prompt: String,
        solution: PhysicsSolution,
        modelID: String,
        createdAt: Date = .now,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.prompt = prompt
        self.topic = solution.topic
        self.answerSummary = solution.resultPreview
        self.createdAt = createdAt
        self.modelID = modelID
        self.isFavorite = isFavorite
        self.solutionData = (try? JSONEncoder().encode(solution)) ?? Data()
    }

    var solution: PhysicsSolution? {
        guard !solutionData.isEmpty else { return nil }
        return try? JSONDecoder().decode(PhysicsSolution.self, from: solutionData)
    }

    var modelTitle: String {
        AIModelInfo.title(for: modelID)
    }

    var hasReadableSolution: Bool {
        solution != nil
    }

    func update(with solution: PhysicsSolution) {
        topic = solution.topic
        answerSummary = solution.resultPreview
        solutionData = (try? JSONEncoder().encode(solution)) ?? solutionData
    }
}
