//
//  AssistantView.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

struct AssistantView: View {
    @State private var viewModel: AssistantViewModel
    @State private var draft = ""
    @FocusState private var isInputFocused: Bool

    init(conversationId: String?, title: String) {
        _viewModel = State(initialValue: AssistantViewModel(conversationId: conversationId, title: title))
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            inputBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty && !viewModel.isLoadingHistory {
                        emptyState
                    }

                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isSending {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Thinking…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 4)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) {
                guard let lastId = viewModel.messages.last?.id else { return }
                withAnimation {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
            Text("Ask me anything")
                .font(.headline)
            Text("Your conversation is saved to your account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)

            Button(action: submit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? Color.accentColor : .secondary)
            }
            .disabled(!canSend)
        }
        .padding()
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSending
    }

    private func submit() {
        let text = draft
        draft = ""
        Task {
            await viewModel.send(text)
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 40) }

            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isFromUser ? Color.accentColor : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .foregroundStyle(message.isFromUser ? .white : .primary)

            if !message.isFromUser { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    NavigationStack {
        AssistantView(conversationId: nil, title: "New Chat")
    }
    .environment(AuthManager())
}
