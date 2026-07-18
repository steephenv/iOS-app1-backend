//
//  APIClient.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import Foundation

enum APIConfig {
    /// Base URL of the backend in `backend/`, deployed on Render.
    static let baseURL = URL(string: "https://ios-app-backend.onrender.com")!
}

struct AuthResponse: Decodable {
    let token: String
    let email: String
}

enum APIError: LocalizedError {
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .server(let message):
            return message
        case .invalidResponse:
            return "Something went wrong. Please try again."
        }
    }
}

/// Talks to the `backend/` auth API over HTTPS.
final class APIClient {
    static let shared = APIClient()
    private init() {}

    func signUp(email: String, password: String) async throws -> AuthResponse {
        try await post(path: "/api/auth/signup", body: ["email": email, "password": password])
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await post(path: "/api/auth/login", body: ["email": email, "password": password])
    }

    private func post(path: String, body: [String: String]) async throws -> AuthResponse {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "Request failed (\(httpResponse.statusCode)).")
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
}
