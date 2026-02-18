//
//  ProductivityAppApp.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 1/21/26.
//

import SwiftUI
import GoogleSignIn

@main
struct ProductivityAppApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var shareManager = ShareManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authManager)
                .environmentObject(shareManager)
        }
    }
}

