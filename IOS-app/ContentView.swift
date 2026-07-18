//
//  ContentView.swift
//  IOS-app
//
//  Created by Steephen Varghese on 18/07/26.
//

import SwiftUI

struct ContentView: View {
    @State private var auth = AuthManager()

    var body: some View {
        Group {
            if auth.isAuthenticated {
                HomeView()
            } else {
                AuthenticationView()
            }
        }
        .environment(auth)
    }
}

/// Placeholder landing screen shown after a successful sign-in.
struct HomeView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("You're signed in")
                .font(.title.bold())
            if let email = auth.currentEmail {
                Text(email)
                    .foregroundStyle(.secondary)
            }
            Button("Sign Out") {
                auth.signOut()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
