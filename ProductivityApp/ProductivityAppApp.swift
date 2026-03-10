//
//  ProductivityAppApp.swift
//  ProductivityApp
//
//


import SwiftUI
import GoogleSignIn

@main
struct ProductivityAppApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var shareManager = ShareManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(shareManager)
        }
    }
}

