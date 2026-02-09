//
//  User.swift
//  UserAuthentication
//
//  Created by David Estrella on 1/24/26.
//

import Foundation

enum AuthProvider: String, Codable {
    case apple
    case google
    case email
}

struct User: Identifiable, Codable {
    let id: String
    var email: String?
    var displayName: String?
    var photoURL: URL?
    var authProvider: AuthProvider

    init(id: String, email: String? = nil, displayName: String? = nil, photoURL: URL? = nil, authProvider: AuthProvider) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.authProvider = authProvider
    }
}
