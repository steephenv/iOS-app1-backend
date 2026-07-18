//
//  KeychainHelper.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import Foundation
import Security

/// Minimal Keychain wrapper for persisting the auth token and email securely on-device.
struct KeychainHelper {
    private let service = Bundle.main.bundleIdentifier ?? "IOS-app"
    private let tokenKey = "authToken"
    private let emailKey = "authEmail"

    func save(token: String, email: String) {
        set(token, forKey: tokenKey)
        set(email, forKey: emailKey)
    }

    func loadToken() -> String? { get(tokenKey) }
    func loadEmail() -> String? { get(emailKey) }

    func clear() {
        delete(tokenKey)
        delete(emailKey)
    }

    private func set(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
