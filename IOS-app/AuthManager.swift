//
//  AuthManager.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

/// Observable authentication state, backed by the `backend/` auth API and MongoDB.
@MainActor
@Observable
final class AuthManager {

    /// Whether a user is currently signed in.
    private(set) var isAuthenticated: Bool

    /// The email of the signed-in user, if any.
    private(set) var currentEmail: String?

    /// True while an auth request is in flight.
    private(set) var isLoading = false

    private let keychain = KeychainHelper()

    init() {
        if let email = keychain.loadEmail(), keychain.loadToken() != nil {
            currentEmail = email
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }

    // MARK: - Actions

    func login(email: String, password: String) async throws {
        try validate(email: email, password: password)
        isLoading = true
        defer { isLoading = false }
        let response = try await APIClient.shared.login(email: email, password: password)
        persist(response)
    }

    func signUp(email: String, password: String, confirmPassword: String) async throws {
        try validate(email: email, password: password)
        guard password == confirmPassword else {
            throw AuthError.passwordsDoNotMatch
        }
        isLoading = true
        defer { isLoading = false }
        let response = try await APIClient.shared.signUp(email: email, password: password)
        persist(response)
    }

    func signOut() {
        keychain.clear()
        isAuthenticated = false
        currentEmail = nil
    }

    // MARK: - Helpers

    private func persist(_ response: AuthResponse) {
        keychain.save(token: response.token, email: response.email)
        currentEmail = response.email
        isAuthenticated = true
    }

    private func validate(email: String, password: String) throws {
        guard email.contains("@"), email.contains(".") else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
    }
}

/// Errors surfaced to the user during authentication.
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case passwordsDoNotMatch

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .passwordsDoNotMatch:
            return "Passwords don't match."
        }
    }
}
