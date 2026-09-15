import Foundation
import RunMusicCore

#if canImport(Security)
import Security

public enum KeychainTokenStoreError: Error, Sendable, Equatable {
    case unexpectedStatus(OSStatus)
    case invalidData
}

public actor KeychainOAuthTokenStore: OAuthTokenStoring {
    private let service: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(service: String) {
        self.service = service
    }

    public func load(provider: String) throws -> OAuthTokenSet? {
        var query = baseQuery(provider: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainTokenStoreError.unexpectedStatus(status) }
        guard let data = result as? Data else { throw KeychainTokenStoreError.invalidData }
        return try decoder.decode(OAuthTokenSet.self, from: data)
    }

    public func save(_ tokens: OAuthTokenSet, provider: String) throws {
        let data = try encoder.encode(tokens)
        let query = baseQuery(provider: provider)
        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var insertion = query
            insertion[kSecValueData as String] = data
            insertion[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(insertion as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainTokenStoreError.unexpectedStatus(addStatus) }
        } else if updateStatus != errSecSuccess {
            throw KeychainTokenStoreError.unexpectedStatus(updateStatus)
        }
    }

    public func remove(provider: String) throws {
        let status = SecItemDelete(baseQuery(provider: provider) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery(provider: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
            kSecAttrSynchronizable as String: false
        ]
    }
}
#endif
