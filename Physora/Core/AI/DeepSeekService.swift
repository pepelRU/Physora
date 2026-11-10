import Foundation

/// Official DeepSeek chat-completions client.
///
/// Endpoint and request fields follow https://api-docs.deepseek.com/api/create-chat-completion
/// and https://api-docs.deepseek.com/api/list-models (checked 2026).
/// The API key is held only in memory for the lifetime of this actor and is
/// never written to logs, UserDefaults or the SwiftData store.
actor DeepSeekService: AIService {
    nonisolated let provider: AIProvider = .deepSeek
    nonisolated let modelID: String

    private let apiKey: String
    private let baseURL = URL(string: "https://api.deepseek.com")!
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let maximumHTTPAttempts = 3

    init(apiKey: String, modelID: String, session: URLSession? = nil) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.modelID = modelID
        self.session = session ?? Self.makeSession()
    }

    // MARK: - Public API

    func solve(
        problem: String,
        preferences: SolutionPreferences,
        images: [Data]
    ) async throws -> PhysicsSolution {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let trimmed = problem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !images.isEmpty else { throw AIError.emptyResponse }
        guard images.count <= 4 else {
            throw AIError.underlying("К задаче можно приложить не более четырёх фотографий.")
        }

        let requestModelID = images.isEmpty ? modelID : "deepseek-flash"
        let system = AIPromptBuilder.systemPrompt(preferences: preferences)
        let userText = AIPromptBuilder.userPrompt(
            problem: trimmed,
            preferences: preferences,
            imageCount: images.count
        )

        var firstMessages: [ChatMessage] = [
            ChatMessage(role: "system", text: system)
        ]
        if images.isEmpty {
            firstMessages.append(ChatMessage(role: "user", text: userText))
        } else {
            var parts = [ChatContentPart.text(userText)]
            for image in images {
                parts.append(.image(jpegData: image, detail: "high"))
            }
            firstMessages.append(ChatMessage(role: "user", parts: parts))
        }
        var messages = firstMessages

        var lastParseError: Error = AIError.malformedJSON
        for attempt in 0..<2 {
            try Task.checkCancellation()
            let content = try await requestCompletion(messages: messages, modelID: requestModelID)
            do {
                var solution = try decodeSolution(from: content)
                solution = try PhysicsEngine.prepare(solution, preferences: preferences)
                return solution
            } catch let error as AIError {
                if case .notPhysics = error { throw error }
                if attempt == 0, isRetryableParseFailure(error) {
                    lastParseError = error
                    messages.append(ChatMessage(role: "assistant", text: String(content.prefix(24_000))))
                    messages.append(ChatMessage(role: "user", text: AIPromptBuilder.repairPrompt()))
                    continue
                }
                throw error
            } catch {
                if attempt == 0 {
                    lastParseError = error
                    messages.append(ChatMessage(role: "assistant", text: String(content.prefix(24_000))))
                    messages.append(ChatMessage(role: "user", text: AIPromptBuilder.repairPrompt()))
                    continue
                }
                throw lastParseError
            }
        }
        throw lastParseError
    }

    func checkConnection() async throws -> ConnectionCheck {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let started = Date()
        let url = baseURL.appendingPathComponent("models")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 35

        let data = try await perform(request: request)
        let response: ModelsResponse
        do {
            response = try decoder.decode(ModelsResponse.self, from: data)
        } catch {
            throw AIError.invalidResponse
        }
        let models = response.data.map {
            AIModelInfo(id: $0.id, name: $0.name?.isEmpty == false ? ($0.name ?? $0.id) : $0.id)
        }
        guard !models.isEmpty else { throw AIError.invalidResponse }
        guard models.contains(where: { $0.id == modelID }) else {
            throw AIError.modelUnavailable(modelID)
        }
        return ConnectionCheck(models: models, latency: Date().timeIntervalSince(started), checkedAt: Date())
    }

    // MARK: - Chat request

    private func requestCompletion(messages: [ChatMessage], modelID: String) async throws -> String {
        let body = ChatRequest(
            model: modelID,
            messages: messages,
            thinking: ChatRequest.Thinking(type: "enabled"),
            reasoningEffort: "high",
            maxTokens: 32_768,
            responseFormat: ChatRequest.ResponseFormat(type: "json_object"),
            stream: false
        )

        let payload: Data
        do {
            payload = try encoder.encode(body)
        } catch {
            throw AIError.underlying("Не удалось подготовить запрос к DeepSeek.")
        }

        let url = baseURL.appendingPathComponent("chat").appendingPathComponent("completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 150

        let data = try await perform(request: request)
        let response: ChatResponse
        do {
            response = try decoder.decode(ChatResponse.self, from: data)
        } catch {
            throw AIError.invalidResponse
        }

        guard let choice = response.choices.first else {
            throw AIError.emptyResponse
        }
        if choice.finishReason == "length" {
            throw AIError.invalidResponse
        }
        guard let content = choice.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw AIError.emptyResponse
        }
        return content
    }

    // MARK: - Networking and retries

    private func perform(request: URLRequest) async throws -> Data {
        var lastError: Error = AIError.invalidResponse

        for attempt in 0..<maximumHTTPAttempts {
            try Task.checkCancellation()
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw AIError.invalidResponse
                }
                if (200..<300).contains(http.statusCode) {
                    return data
                }

                let serverMessage = Self.serverMessage(from: data)
                let mapped = Self.mapHTTPError(status: http.statusCode, message: serverMessage)
                let canRetry = Self.isRetryable(status: http.statusCode)
                guard canRetry, attempt < maximumHTTPAttempts - 1 else {
                    throw mapped
                }
                lastError = mapped
                let delay = Self.retryDelay(attempt: attempt, response: http)
                try await Task.sleep(for: .seconds(delay))
            } catch is CancellationError {
                throw AIError.cancelled
            } catch let error as AIError {
                throw error
            } catch let error as URLError {
                switch error.code {
                case .cancelled:
                    throw AIError.cancelled
                case .notConnectedToInternet, .networkConnectionLost:
                    guard attempt < maximumHTTPAttempts - 1 else {
                        throw AIError.offline
                    }
                    lastError = AIError.offline
                    try await Task.sleep(for: .seconds(attempt == 0 ? 1.0 : 3.0))
                case .timedOut:
                    throw AIError.requestTimedOut
                case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                    guard attempt < maximumHTTPAttempts - 1 else {
                        throw AIError.offline
                    }
                    lastError = AIError.offline
                    try await Task.sleep(for: .seconds(attempt == 0 ? 1.0 : 3.0))
                default:
                    throw AIError.underlying("Не удалось связаться с DeepSeek. Проверьте подключение к интернету.")
                }
            } catch {
                throw AIError.underlying("Не удалось выполнить запрос к DeepSeek.")
            }
        }
        throw lastError
    }

    private static func mapHTTPError(status: Int, message: String) -> AIError {
        switch status {
        case 401: .unauthorized
        case 402: .insufficientBalance
        case 429: .rateLimited
        case 500, 502, 503, 504: .serverUnavailable
        default: .http(status: status, message: String(message.prefix(280)))
        }
    }

    private static func isRetryable(status: Int) -> Bool {
        status == 429 || (500...599).contains(status)
    }

    private func isRetryableParseFailure(_ error: AIError) -> Bool {
        switch error {
        case .malformedJSON, .emptyResponse, .invalidResponse:
            return true
        default:
            return false
        }
    }

    private static func retryDelay(attempt: Int, response: HTTPURLResponse) -> Double {
        if let value = response.value(forHTTPHeaderField: "Retry-After"), let seconds = Double(value) {
            return min(max(seconds, 1), 8)
        }
        return attempt == 0 ? 1.5 : 4.0
    }

    private static func serverMessage(from data: Data) -> String {
        struct Envelope: Decodable {
            struct Detail: Decodable { let message: String? }
            let error: Detail?
        }
        if let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
           let message = envelope.error?.message {
            return message.replacingOccurrences(of: "\n", with: " ")
        }
        return ""
    }

    // MARK: - Response decoding

    private func decodeSolution(from content: String) throws -> PhysicsSolution {
        var text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            if let newline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: newline)...])
            }
            if let fence = text.range(of: "```", options: .backwards) {
                text = String(text[..<fence.lowerBound])
            }
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstBrace = text.firstIndex(of: "{"),
              let lastBrace = text.lastIndex(of: "}"),
              firstBrace <= lastBrace else {
            throw AIError.malformedJSON
        }
        let json = String(text[firstBrace...lastBrace])
        guard let data = json.data(using: .utf8) else { throw AIError.malformedJSON }

        do {
            return try decoder.decode(PhysicsSolution.self, from: data)
        } catch {
            throw AIError.malformedJSON
        }
    }

    // MARK: - Session

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 150
        configuration.timeoutIntervalForResource = 240
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }
}

// MARK: - Wire types

private struct ChatMessage: Encodable, Sendable {
    enum MessageContent: Encodable, Sendable {
        case text(String)
        case parts([ChatContentPart])

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let text):
                try container.encode(text)
            case .parts(let parts):
                try container.encode(parts)
            }
        }
    }

    let role: String
    let content: MessageContent

    init(role: String, text: String) {
        self.role = role
        self.content = .text(text)
    }

    init(role: String, parts: [ChatContentPart]) {
        self.role = role
        self.content = .parts(parts)
    }
}

private struct ChatContentPart: Encodable, Sendable {
    struct ImageURL: Encodable, Sendable {
        let url: String
        let detail: String?
    }

    let type: String
    let text: String?
    let imageURL: ImageURL?

    enum CodingKeys: String, CodingKey {
        case type, text
        case imageURL = "image_url"
    }

    static func text(_ value: String) -> ChatContentPart {
        ChatContentPart(type: "text", text: value, imageURL: nil)
    }

    static func image(jpegData: Data, detail: String) -> ChatContentPart {
        let encoded = jpegData.base64EncodedString()
        return ChatContentPart(
            type: "image_url",
            text: nil,
            imageURL: ImageURL(url: "data:image/jpeg;base64,\(encoded)", detail: detail)
        )
    }
}

private struct ChatRequest: Encodable {
    struct Thinking: Encodable { let type: String }
    struct ResponseFormat: Encodable { let type: String }

    let model: String
    let messages: [ChatMessage]
    let thinking: Thinking
    let reasoningEffort: String
    let maxTokens: Int
    let responseFormat: ResponseFormat
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, thinking, stream
        case reasoningEffort = "reasoning_effort"
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
    }
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    let choices: [Choice]
    let model: String?
}

private struct ModelsResponse: Decodable {
    struct RemoteModel: Decodable {
        let id: String
        let name: String?
    }
    let data: [RemoteModel]
}
