//
//  LoginView.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            header

            VStack(spacing: 14) {
                AuthTextField(
                    title: "Email",
                    systemImage: "envelope",
                    text: $email,
                    keyboard: .emailAddress,
                    contentType: .emailAddress
                )

                AuthTextField(
                    title: "Password",
                    systemImage: "lock",
                    text: $password,
                    isSecure: true,
                    contentType: .password
                )
            }

            if let errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            AuthButton(title: "Log In", isLoading: auth.isLoading, action: submit)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Welcome Back")
                .font(.title2.bold())
            Text("Log in to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private func submit() {
        errorMessage = nil
        Task {
            do {
                try await auth.login(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
