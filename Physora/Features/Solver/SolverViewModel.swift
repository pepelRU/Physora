import Foundation
import Observation

@MainActor
@Observable
final class SolverViewModel {
    enum Phase: Int, CaseIterable, Identifiable {
        case preparing
        case waitingForAI
        case validating
        case rendering
        case saving

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .preparing: "Готовим запрос"
            case .waitingForAI: "Ожидаем ответ DeepSeek"
            case .validating: "Проверяем структуру решения"
            case .rendering: "Готовим чертежи и графики"
            case .saving: "Сохраняем в историю"
            }
        }

        var detail: String {
            switch self {
            case .preparing: "Проверяем условие и выбранные настройки."
            case .waitingForAI: "Модель решает задачу. Обычно это занимает от 15 до 90 секунд."
            case .validating: "Проверяем Дано, формулы, шаги, единицы и целостность JSON."
            case .rendering: "Строим схемы из графических примитивов средствами приложения."
            case .saving: "История хранится локально на этом устройстве."
            }
        }

        var systemImage: String {
            switch self {
            case .preparing: "slider.horizontal.3"
            case .waitingForAI: "sparkles"
            case .validating: "checkmark.shield"
            case .rendering: "scribble.variable"
            case .saving: "externaldrive"
            }
        }
    }

    var phase: Phase = .preparing
    var isBusy = false
    var errorMessage: String?

    func solve(
        problem: String,
        apiKey: String,
        modelID: String,
        preferences: SolutionPreferences,
        images: [Data] = [],
        history: [ChatMemoryTurn] = []
    ) async throws -> PhysicsSolution {
        isBusy = true
        errorMessage = nil
        phase = .preparing
        do {
            let service = AIServiceFactory.make(provider: .deepSeek, apiKey: apiKey, modelID: modelID)
            try Task.checkCancellation()
            phase = .waitingForAI
            let raw = try await service.solve(
                problem: problem,
                preferences: preferences,
                images: images,
                history: history
            )
            try Task.checkCancellation()
            phase = .validating
            let validated = try PhysicsEngine.prepare(raw, preferences: preferences)
            try Task.checkCancellation()
            phase = .rendering
            await Task.yield()
            try Task.checkCancellation()
            return validated
        } catch is CancellationError {
            phase = .preparing
            isBusy = false
            throw CancellationError()
        } catch {
            isBusy = false
            if Task.isCancelled {
                throw CancellationError()
            }
            if let aiError = error as? AIError {
                errorMessage = aiError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    func markSaving() {
        phase = .saving
    }

    func complete() {
        isBusy = false
    }

    func reset() {
        errorMessage = nil
        phase = .preparing
        isBusy = false
    }
}
