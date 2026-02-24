//
//  ProductivityAppApp.swift
//  ProductivityApp
//
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

