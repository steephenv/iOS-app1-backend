//
//  AssistantViewModel.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

/// Observable chat state for the assistant screen, backed by the
/// `backend/` API and Gemini.
@MainActor
@Observable
final class AssistantViewModel {
    private(set) var messages: [ChatMessage] = []
    private(set) var isSending = false
    private(set) var isLoadingHistory = false
    var errorMessage: String?

    func loadHistory() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            messages = try await APIClient.shared.fetchHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil

        let userMessage = ChatMessage(id: UUID().uuidString, role: "user", content: trimmed, createdAt: Date())
        messages.append(userMessage)

        isSending = true
        defer { isSending = false }
        do {
            let reply = try await APIClient.shared.sendMessage(trimmed)
            messages.append(reply)
        } catch {
            errorMessage = error.localizedDescription
            messages.removeAll { $0.id == userMessage.id }
        }
    }
}
