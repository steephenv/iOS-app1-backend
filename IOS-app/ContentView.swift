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
                AssistantView()
            } else {
                AuthenticationView()
            }
        }
        .environment(auth)
    }
}

#Preview {
    ContentView()
}
