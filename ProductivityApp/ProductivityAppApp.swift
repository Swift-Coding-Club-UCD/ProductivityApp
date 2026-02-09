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
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
