import Foundation
import Security

enum KeychainError: LocalizedError {
    case unhandled(OSStatus)
    case unexpectedData

    var errorDescription: String? {
        switch self {
        case .unhandled(let status):
            let text = SecCopyErrorMessageString(status, nil) as String? ?? "неизвестная ошибка"
            return "Не удалось получить доступ к связке ключей: \(text)."
        case .unexpectedData:
            return "Сохранённый ключ имеет неверный формат."
        }
    }
}

/// Small, non-synchronizing Keychain wrapper used only for the DeepSeek key.
enum KeychainManager {
    private static let service = "com.pepelru.physora.deepseek"
    private static let account = "api-key"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
    }

    static func saveAPIKey(_ key: String) throws {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw KeychainError.unexpectedData }
        guard let data = normalized.data(using: .utf8) else { throw KeychainError.unexpectedData }

        let query = baseQuery
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }

        if updateStatus != errSecItemNotFound {
            throw KeychainError.unhandled(updateStatus)
        }

        var addQuery = query
        addQuery.merge(attributes) { _, new in new }
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unhandled(addStatus)
        }
    }

    static func readAPIKey() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = kCFBooleanTrue as Any
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func hasAPIKey() -> Bool {
        (try? readAPIKey()) != nil
    }

    static func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }

    static func maskedKeyPreview() -> String? {
        do {
            guard let key = try readAPIKey() else { return nil }
            return "••••••••••••\(key.suffix(4))"
        } catch {
            return nil
        }
    }
}
