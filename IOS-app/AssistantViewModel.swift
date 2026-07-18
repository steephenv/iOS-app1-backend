//
//  AssistantViewModel.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

/// Observable chat state for a single conversation, backed by the
/// `backend/` API and Gemini. `conversationId` starts as `nil` for a chat
/// that hasn't been saved yet — it's adopted from the server's response
/// once the first message is sent.
@MainActor
@Observable
final class AssistantViewModel {
    private(set) var conversationId: String?
    private(set) var title: String
    private(set) var messages: [ChatMessage] = []
    private(set) var isSending = false
    private(set) var isLoadingHistory = false
    var errorMessage: String?

    init(conversationId: String?, title: String) {
        self.conversationId = conversationId
        self.title = title
    }

    func loadHistory() async {
        guard let conversationId else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            messages = try await APIClient.shared.fetchMessages(conversationId: conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil

        let optimisticMessage = ChatMessage(id: UUID().uuidString, role: "user", content: trimmed, createdAt: Date())
        messages.append(optimisticMessage)

        isSending = true
        defer { isSending = false }
        do {
            let response = try await APIClient.shared.sendMessage(conversationId: conversationId, text: trimmed)
            conversationId = response.conversationId
            title = response.title
            messages.append(response.reply)
        } catch {
            errorMessage = error.localizedDescription
            messages.removeAll { $0.id == optimisticMessage.id }
        }
    }
}
