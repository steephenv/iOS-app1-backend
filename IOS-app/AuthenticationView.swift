//
//  AuthenticationView.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

/// Hosts the login and sign-up screens behind a shared gradient backdrop,
/// switching between them with a sliding pill selector.
struct AuthenticationView: View {
    private enum Screen: CaseIterable {
        case login
        case signUp

        var title: String {
            switch self {
            case .login: return "Log In"
            case .signUp: return "Sign Up"
            }
        }
    }

    @State private var screen: Screen = .login
    @Namespace private var pillNamespace

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 20) {
                    branding
                    selector
                    card
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var branding: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
            Text("Assistant")
                .font(.largeTitle.bold())
        }
    }

    private var selector: some View {
        HStack(spacing: 4) {
            ForEach(Screen.allCases, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        screen = option
                    }
                } label: {
                    Text(option.title)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if screen == option {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor)
                                    .matchedGeometryEffect(id: "pill", in: pillNamespace)
                            }
                        }
                        .foregroundStyle(screen == option ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private var card: some View {
        Group {
            switch screen {
            case .login:
                LoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            case .signUp:
                SignUpView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 20)
    }
}

#Preview {
    AuthenticationView()
        .environment(AuthManager())
}
