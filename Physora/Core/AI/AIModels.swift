import Foundation

// MARK: - Structured physics solution

/// The complete, validated response returned by an AI provider.
/// Every block is separate so the renderer never has to parse prose or raw
/// Markdown in order to display a school-style solution.
struct PhysicsSolution: Codable, Hashable, Sendable {
    var schemaVersion: Int = 1
    var topic: String = ""
    var isPhysicsProblem: Bool = true
    var problemStatement: String = ""
    var problemAnalysis: String = ""
    var given: [GivenQuantity] = []
    var find: [FindQuantity] = []
    var siNote: String = ""
    var siConversions: [SIConversion] = []
    var formulas: [FormulaReference] = []
    var solutionSteps: [SolutionStep] = []
    var calculations: [CalculationLine] = []
    var diagrams: [DiagramSpec] = []
    var graphs: [PhysicsGraph] = []
    var finalAnswer: [AnswerQuantity] = []
    var explanation: String = ""
    var warnings: [String] = []
    var needsDiagram: Bool = false

    enum CodingKeys: String, CodingKey {
        case schemaVersion, topic, isPhysicsProblem, problemStatement, problemAnalysis
        case given, find, siNote, siConversions, formulas, solutionSteps
        case calculations, diagrams, graphs, finalAnswer, explanation
        case warnings, needsDiagram
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        topic = c.flexibleString(forKey: .topic)
        isPhysicsProblem = try c.decodeIfPresent(Bool.self, forKey: .isPhysicsProblem) ?? true
        problemStatement = c.flexibleString(forKey: .problemStatement)
        problemAnalysis = c.flexibleString(forKey: .problemAnalysis)
        given = c.lossyArray(forKey: .given)
        find = c.lossyArray(forKey: .find)
        siNote = c.flexibleString(forKey: .siNote)
        siConversions = c.lossyArray(forKey: .siConversions)
        formulas = c.lossyArray(forKey: .formulas)
        solutionSteps = c.lossyArray(forKey: .solutionSteps)
        calculations = c.lossyArray(forKey: .calculations)
        diagrams = c.lossyArray(forKey: .diagrams)
        graphs = c.lossyArray(forKey: .graphs)
        finalAnswer = c.answers(forKey: .finalAnswer)
        explanation = c.flexibleString(forKey: .explanation)
        warnings = c.stringArray(forKey: .warnings)
        needsDiagram = try c.decodeIfPresent(Bool.self, forKey: .needsDiagram) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(topic, forKey: .topic)
        try c.encode(isPhysicsProblem, forKey: .isPhysicsProblem)
        try c.encode(problemStatement, forKey: .problemStatement)
        try c.encode(problemAnalysis, forKey: .problemAnalysis)
        try c.encode(given, forKey: .given)
        try c.encode(find, forKey: .find)
        try c.encode(siNote, forKey: .siNote)
        try c.encode(siConversions, forKey: .siConversions)
        try c.encode(formulas, forKey: .formulas)
        try c.encode(solutionSteps, forKey: .solutionSteps)
        try c.encode(calculations, forKey: .calculations)
        try c.encode(diagrams, forKey: .diagrams)
        try c.encode(graphs, forKey: .graphs)
        try c.encode(finalAnswer, forKey: .finalAnswer)
        try c.encode(explanation, forKey: .explanation)
        try c.encode(warnings, forKey: .warnings)
        try c.encode(needsDiagram, forKey: .needsDiagram)
    }

    var hasVisibleContent: Bool {
        !problemStatement.isEmpty
            || !problemAnalysis.isEmpty
            || !given.isEmpty
            || !find.isEmpty
            || !formulas.isEmpty
            || !solutionSteps.isEmpty
            || !diagrams.isEmpty
            || !graphs.isEmpty
            || !finalAnswer.isEmpty
            || !explanation.isEmpty
    }

    var answerSummary: String {
        guard !finalAnswer.isEmpty else {
            return warnings.isEmpty ? "Ответ не сформирован" : warnings[0]
        }
        return finalAnswer
            .map { "\($0.symbol) = \($0.value) \($0.unit)".trimmingCharacters(in: .whitespaces) }
            .joined(separator: "; ")
    }

    /// A short line used in lists and notifications.
    var resultPreview: String {
        let trimmed = answerSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 120 {
            return String(trimmed.prefix(117)) + "…"
        }
        return trimmed
    }
}

struct GivenQuantity: Codable, Hashable, Sendable {
    var symbol: String
    var value: String
    var unit: String
    var note: String

    init(symbol: String, value: String, unit: String, note: String = "") {
        self.symbol = symbol
        self.value = value
        self.unit = unit
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        symbol = c.flexibleString(forKey: .symbol)
        value = c.flexibleString(forKey: .value)
        unit = c.flexibleString(forKey: .unit)
        note = c.flexibleString(forKey: .note)
    }
}

struct FindQuantity: Codable, Hashable, Sendable {
    var symbol: String
    var description: String
    var unit: String

    init(symbol: String, description: String, unit: String = "") {
        self.symbol = symbol
        self.description = description
        self.unit = unit
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        symbol = c.flexibleString(forKey: .symbol)
        description = c.flexibleString(forKey: .description)
        unit = c.flexibleString(forKey: .unit)
    }
}

struct SIConversion: Codable, Hashable, Sendable {
    var quantity: String
    var from: String
    var to: String
    var note: String

    init(quantity: String, from: String, to: String, note: String = "") {
        self.quantity = quantity
        self.from = from
        self.to = to
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        quantity = c.flexibleString(forKey: .quantity)
        from = c.flexibleString(forKey: .from)
        to = c.flexibleString(forKey: .to)
        note = c.flexibleString(forKey: .note)
    }
}

struct FormulaReference: Codable, Hashable, Sendable {
    var name: String
    var expression: String
    var variables: String
    var note: String

    init(name: String, expression: String, variables: String = "", note: String = "") {
        self.name = name
        self.expression = expression
        self.variables = variables
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.flexibleString(forKey: .name)
        expression = c.flexibleString(forKey: .expression)
        variables = c.flexibleString(forKey: .variables)
        note = c.flexibleString(forKey: .note)
    }
}

struct SolutionStep: Codable, Hashable, Sendable {
    var title: String
    var explanation: String
    var formula: String
    var calculation: String
    var result: String

    init(
        title: String,
        explanation: String = "",
        formula: String = "",
        calculation: String = "",
        result: String = ""
    ) {
        self.title = title
        self.explanation = explanation
        self.formula = formula
        self.calculation = calculation
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = c.flexibleString(forKey: .title)
        explanation = c.flexibleString(forKey: .explanation)
        formula = c.flexibleString(forKey: .formula)
        calculation = c.flexibleString(forKey: .calculation)
        result = c.flexibleString(forKey: .result)
    }

    var copyText: String {
        [
            title,
            explanation,
            formula.isEmpty ? nil : "Формула: \(formula)",
            calculation.isEmpty ? nil : "Вычисление: \(calculation)",
            result.isEmpty ? nil : "Результат: \(result)"
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
    }
}

struct CalculationLine: Codable, Hashable, Sendable {
    var expression: String
    var result: String
    var unit: String
    var note: String

    init(expression: String, result: String, unit: String = "", note: String = "") {
        self.expression = expression
        self.result = result
        self.unit = unit
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        expression = c.flexibleString(forKey: .expression)
        result = c.flexibleString(forKey: .result)
        unit = c.flexibleString(forKey: .unit)
        note = c.flexibleString(forKey: .note)
    }
}

struct AnswerQuantity: Codable, Hashable, Sendable {
    var symbol: String
    var value: String
    var unit: String

    init(symbol: String, value: String, unit: String = "") {
        self.symbol = symbol
        self.value = value
        self.unit = unit
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        symbol = c.flexibleString(forKey: .symbol)
        value = c.flexibleString(forKey: .value)
        unit = c.flexibleString(forKey: .unit)
    }
}

// MARK: - AI requests and responses

struct SolutionPreferences: Sendable, Equatable {
    var explanationDetail: ExplanationDetail
    var autoSI: Bool
    var buildDiagrams: Bool
    var showExtraExplanations: Bool
    var showAnalysis: Bool
    var showSeparateFormulas: Bool
    var showSeparateCalculations: Bool

    static let standard = SolutionPreferences(
        explanationDetail: .concise,
        autoSI: true,
        buildDiagrams: true,
        showExtraExplanations: false,
        showAnalysis: false,
        showSeparateFormulas: false,
        showSeparateCalculations: false
    )

    var russianDetail: String {
        switch explanationDetail {
        case .concise: "кратко, но с обязательными шагами"
        case .standard: "подробно, как в хорошей школьной тетради"
        case .detailed: "максимально подробно, с пояснением каждого преобразования"
        }
    }
}

enum ExplanationDetail: String, CaseIterable, Codable, Identifiable, Sendable {
    case concise
    case standard
    case detailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .concise: "Кратко"
        case .standard: "Стандартно"
        case .detailed: "Подробно"
        }
    }

    var subtitle: String {
        switch self {
        case .concise: "Только ключевые шаги"
        case .standard: "Школьное оформление"
        case .detailed: "Каждое преобразование"
        }
    }
}

struct AIModelInfo: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String

    static let deepSeekOptions: [AIModelInfo] = [
        AIModelInfo(id: "deepseek-flash", name: "DeepSeek Flash"),
        AIModelInfo(id: "deepseek-v4-pro", name: "DeepSeek V4 Pro")
    ]

    static func title(for id: String) -> String {
        deepSeekOptions.first(where: { $0.id == id })?.name ?? id
    }
}

struct ConnectionCheck: Sendable, Equatable {
    let models: [AIModelInfo]
    let latency: TimeInterval
    let checkedAt: Date
}

enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case deepSeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deepSeek: "DeepSeek"
        }
    }
}

// MARK: - Errors

enum AIError: LocalizedError, Sendable {
    case missingAPIKey
    case invalidResponse
    case emptyResponse
    case malformedJSON
    case notPhysics(String)
    case unauthorized
    case insufficientBalance
    case rateLimited
    case serverUnavailable
    case requestTimedOut
    case offline
    case http(status: Int, message: String)
    case cancelled
    case modelUnavailable(String)
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Добавьте API-ключ DeepSeek в настройках."
        case .invalidResponse:
            "DeepSeek вернул ответ, который не удалось прочитать."
        case .emptyResponse:
            "Модель вернула пустой ответ. Попробуйте отправить задачу ещё раз."
        case .malformedJSON:
            "Модель вернула решение в неверном формате. Попробуйте ещё раз — Physora автоматически проверяет структуру ответа."
        case .notPhysics(let explanation):
            explanation.isEmpty
                ? "Эта задача не похожа на задачу по физике."
                : explanation
        case .unauthorized:
            "Неверный API-ключ DeepSeek. Проверьте ключ в настройках."
        case .insufficientBalance:
            "На балансе DeepSeek недостаточно средств. Пополните баланс и повторите попытку."
        case .rateLimited:
            "Слишком много запросов к DeepSeek. Подождите немного и попробуйте снова."
        case .serverUnavailable:
            "Сервер DeepSeek временно недоступен. Повторите попытку позже."
        case .requestTimedOut:
            "DeepSeek не успел ответить за отведённое время. Попробуйте ещё раз."
        case .offline:
            "Нет подключения к интернету. Проверьте сеть и попробуйте снова."
        case .http(let status, let message):
            message.isEmpty
                ? "Ошибка DeepSeek (код \(status)). Попробуйте ещё раз."
                : "Ошибка DeepSeek (\(status)): \(message)"
        case .cancelled:
            "Решение отменено."
        case .modelUnavailable(let model):
            "Выбранная модель \(model) недоступна для этого ключа."
        case .underlying(let message):
            message
        }
    }
}

// MARK: - Tolerant decoding helpers

private struct LossyDecodable<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

private extension KeyedDecodingContainer {
    func flexibleString(forKey key: Key) -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Self.numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        return ""
    }

    func lossyArray<Value: Decodable>(forKey key: Key) -> [Value] {
        guard let wrapped = try? decode([LossyDecodable<Value>].self, forKey: key) else {
            return []
        }
        return wrapped.compactMap(\.value)
    }

    func answers(forKey key: Key) -> [AnswerQuantity] {
        if let array = try? decode([LossyDecodable<AnswerQuantity>].self, forKey: key) {
            return array.compactMap(\.value)
        }
        if let single = try? decode(AnswerQuantity.self, forKey: key) {
            return [single]
        }
        return []
    }

    func stringArray(forKey key: Key) -> [String] {
        (try? decode([String].self, forKey: key)) ?? []
    }

    static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 12
        formatter.usesGroupingSeparator = false
        return formatter
    }
}
