//
//  AuthComponents.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

/// A styled text field used across the auth screens, with a focus ring and
/// an optional password-visibility toggle.
struct AuthTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(isFocused ? Color.accentColor : .secondary)
                .frame(width: 20)

            Group {
                if isSecure && !isRevealed {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .textContentType(contentType)
            .focused($isFocused)

            if isSecure {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

/// A prominent full-width gradient action button with a loading state.
struct AuthButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 6)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.85 : 1)
        .animation(.easeOut(duration: 0.15), value: isLoading)
    }
}

/// An inline error banner shown beneath the form fields.
struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.footnote)
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

/// Soft gradient backdrop shared by the auth screens.
struct AuthBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.25), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
