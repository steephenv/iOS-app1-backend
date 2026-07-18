//
//  ConversationListView.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

/// Marker route pushed onto the stack to start an unsaved chat — it only
/// becomes a real `Conversation` once the first message is sent.
private struct NewChatRoute: Hashable {}

struct ConversationListView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = ConversationListViewModel()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.conversations.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Chats")
            .navigationDestination(for: Conversation.self) { conversation in
                AssistantView(conversationId: conversation.id, title: conversation.title)
            }
            .navigationDestination(for: NewChatRoute.self) { _ in
                AssistantView(conversationId: nil, title: "New Chat")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if let email = auth.currentEmail {
                            Text(email)
                        }
                        Button("Sign Out", role: .destructive) {
                            auth.signOut()
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(NewChatRoute())
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.load() }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                NavigationLink(value: conversation) {
                    ConversationRow(conversation: conversation)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let conversation = viewModel.conversations[index]
                    Task { await viewModel.delete(conversation) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
            Text("No chats yet")
                .font(.headline)
            Text("Tap the compose button to start one.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.body.weight(.medium))
                .lineLimit(1)
            Text(conversation.updatedAt, format: .relative(presentation: .named))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ConversationListView()
        .environment(AuthManager())
}
