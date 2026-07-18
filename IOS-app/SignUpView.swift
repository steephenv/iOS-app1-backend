//
//  SignUpView.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(AuthManager.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
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
                    contentType: .newPassword
                )

                AuthTextField(
                    title: "Confirm Password",
                    systemImage: "lock.rotation",
                    text: $confirmPassword,
                    isSecure: true,
                    contentType: .newPassword
                )
            }

            if let errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            AuthButton(title: "Create Account", isLoading: auth.isLoading, action: submit)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Create Account")
                .font(.title2.bold())
            Text("Sign up to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private func submit() {
        errorMessage = nil
        Task {
            do {
                try await auth.signUp(
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthManager())
}
