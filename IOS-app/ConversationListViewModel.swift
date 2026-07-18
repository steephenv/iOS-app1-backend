//
//  ConversationListViewModel.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

@MainActor
@Observable
final class ConversationListViewModel {
    private(set) var conversations: [Conversation] = []
    private(set) var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            conversations = try await APIClient.shared.fetchConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ conversation: Conversation) async {
        let previous = conversations
        conversations.removeAll { $0.id == conversation.id }
        do {
            try await APIClient.shared.deleteConversation(id: conversation.id)
        } catch {
            conversations = previous
            errorMessage = error.localizedDescription
        }
    }
}
