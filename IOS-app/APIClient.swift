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

struct Conversation: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let updatedAt: Date
}

private struct ConversationsResponse: Decodable {
    let conversations: [Conversation]
}

private struct MessagesResponse: Decodable {
    let messages: [ChatMessage]
}

private struct SendMessageBody: Encodable {
    let conversationId: String?
    let message: String
}

struct SendMessageResponse: Decodable {
    let conversationId: String
    let title: String
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

    func fetchConversations() async throws -> [Conversation] {
        let response: ConversationsResponse = try await send(path: "/api/assistant/conversations", method: "GET", authorized: true)
        return response.conversations
    }

    func deleteConversation(id: String) async throws {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent("/api/assistant/conversations/\(id)"))
        request.httpMethod = "DELETE"
        try attachAuthorization(to: &request, required: true)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "Request failed (\(httpResponse.statusCode)).")
        }
    }

    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        let response: MessagesResponse = try await send(
            path: "/api/assistant/conversations/\(conversationId)/messages",
            method: "GET",
            authorized: true
        )
        return response.messages
    }

    func sendMessage(conversationId: String?, text: String) async throws -> SendMessageResponse {
        try await send(
            path: "/api/assistant/messages",
            body: SendMessageBody(conversationId: conversationId, message: text),
            authorized: true
        )
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
