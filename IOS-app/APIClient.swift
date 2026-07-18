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

struct ChatMessage: Decodable, Identifiable, Equatable {
    let id: String
    let role: String
    let content: String
    let createdAt: Date

    var isFromUser: Bool { role == "user" }
}

private struct HistoryResponse: Decodable {
    let messages: [ChatMessage]
}

private struct ChatResponse: Decodable {
    let userMessage: ChatMessage
    let reply: ChatMessage
}

enum APIError: LocalizedError {
    case server(String)
    case invalidResponse
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .server(let message):
            return message
        case .invalidResponse:
            return "Something went wrong. Please try again."
        case .notAuthenticated:
            return "Please log in again."
        }
    }
}

/// Talks to the `backend/` API over HTTPS.
final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let keychain = KeychainHelper()

    /// Mongoose timestamps serialize as ISO 8601 with fractional seconds
    /// (e.g. "2026-07-18T13:26:16.860Z"), which JSONDecoder's built-in
    /// `.iso8601` strategy cannot parse on its own.
    private let decoder: JSONDecoder = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { valueDecoder in
            let container = try valueDecoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = withFraction.date(from: dateString) ?? withoutFraction.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }
        return decoder
    }()

    // MARK: - Auth

    func signUp(email: String, password: String) async throws -> AuthResponse {
        try await send(path: "/api/auth/signup", body: ["email": email, "password": password])
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await send(path: "/api/auth/login", body: ["email": email, "password": password])
    }

    // MARK: - Assistant

    func fetchHistory() async throws -> [ChatMessage] {
        let response: HistoryResponse = try await send(path: "/api/assistant/history", method: "GET", authorized: true)
        return response.messages
    }

    func sendMessage(_ text: String) async throws -> ChatMessage {
        let response: ChatResponse = try await send(path: "/api/assistant/chat", body: ["message": text], authorized: true)
        return response.reply
    }

    // MARK: - Networking

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String = "POST",
        body: Body,
        authorized: Bool = false
    ) async throws -> Response {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        try attachAuthorization(to: &request, required: authorized)
        return try await perform(request)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        authorized: Bool = false
    ) async throws -> Response {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        try attachAuthorization(to: &request, required: authorized)
        return try await perform(request)
    }

    private func attachAuthorization(to request: inout URLRequest, required: Bool) throws {
        guard let token = keychain.loadToken() else {
            if required { throw APIError.notAuthenticated }
            return
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "Request failed (\(httpResponse.statusCode)).")
        }

        return try decoder.decode(Response.self, from: data)
    }
}
