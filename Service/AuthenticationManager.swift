//
//  AuthenticationManager.swift
//  UserAuthentication
//
//  Created by David Estrella on 1/24/26.
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import Combine
import GoogleSignIn

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // For Apple Sign In
    private var currentNonce: String?

    // UserDefaults keys
    private let userKey = "currentUser"
    private let emailUsersKey = "emailUsers"
    private let googleEmailsKey = "googleEmails"
    private let appleEmailsKey = "appleEmails"

    init() {
        loadStoredUser()
    }

    // MARK: - Persistence

    private func loadStoredUser() {
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    private func saveUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
        self.currentUser = user
        self.isAuthenticated = true
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userKey)
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }

    // MARK: - Apple Sign In

    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                var displayName: String?
                if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                    displayName = "\(givenName) \(familyName)"
                }

                // Check if we already have stored data for this user
                let storedEmail = UserDefaults.standard.string(forKey: "apple_email_\(userID)")
                let storedName = UserDefaults.standard.string(forKey: "apple_name_\(userID)")

                // Store new data if available
                if let email = email {
                    UserDefaults.standard.set(email, forKey: "apple_email_\(userID)")
                    // Store Apple email to prevent duplicate accounts
                    saveAppleEmail(email)
                } else if let storedEmail = storedEmail {
                    // Ensure stored email is also in the Apple emails set
                    saveAppleEmail(storedEmail)
                }
                if let displayName = displayName {
                    UserDefaults.standard.set(displayName, forKey: "apple_name_\(userID)")
                }

                let user = User(
                    id: userID,
                    email: email ?? storedEmail,
                    displayName: displayName ?? storedName,
                    authProvider: .apple
                )

                saveUser(user)
            }
        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                // User canceled, don't show error
            } else {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller"
            isLoading = false
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let profile = result.user.profile else {
                errorMessage = "Unable to get user profile from Google"
                isLoading = false
                return
            }

            // Store Google email to prevent duplicate accounts
            saveGoogleEmail(profile.email)

            let user = User(
                id: result.user.userID ?? UUID().uuidString,
                email: profile.email,
                displayName: profile.name,
                photoURL: profile.imageURL(withDimension: 200),
                authProvider: .google
            )

            saveUser(user)
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                // User canceled, don't show error
            } else {
                errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    // MARK: - Email/Password Sign In

    func signUpWithEmail(email: String, password: String, displayName: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        // Validate inputs
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return false
        }

        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name"
            isLoading = false
            return false
        }

        // Check if email is already used by Google Sign-In
        if isEmailUsedByGoogle(email) {
            errorMessage = "This email is already associated with a Google account. Please sign in with Google instead."
            isLoading = false
            return false
        }

        // Check if email is already used by Apple Sign-In
        if isEmailUsedByApple(email) {
            errorMessage = "This email is already associated with an Apple account. Please sign in with Apple instead."
            isLoading = false
            return false
        }

        // Check if user already exists with email/password
        var emailUsers = loadEmailUsers()

        if emailUsers.keys.contains(email.lowercased()) {
            errorMessage = "An account with this email already exists"
            isLoading = false
            return false
        }

        // Create new user
        let userID = UUID().uuidString
        let passwordHash = sha256(password)

        let userData: [String: String] = [
            "id": userID,
            "email": email.lowercased(),
            "displayName": displayName,
            "passwordHash": passwordHash
        ]

        emailUsers[email.lowercased()] = userData
        saveEmailUsers(emailUsers)

        let user = User(
            id: userID,
            email: email,
            displayName: displayName,
            authProvider: .email
        )

        saveUser(user)
        isLoading = false
        return true
    }

    func signInWithEmail(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        // Validate inputs
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            isLoading = false
            return false
        }

        // Check credentials
        let emailUsers = loadEmailUsers()

        guard let userData = emailUsers[email.lowercased()] else {
            errorMessage = "No account found with this email"
            isLoading = false
            return false
        }

        let passwordHash = sha256(password)

        guard userData["passwordHash"] == passwordHash else {
            errorMessage = "Incorrect password"
            isLoading = false
            return false
        }

        let user = User(
            id: userData["id"] ?? UUID().uuidString,
            email: userData["email"],
            displayName: userData["displayName"],
            authProvider: .email
        )

        saveUser(user)
        isLoading = false
        return true
    }

    // MARK: - Email User Storage

    private func loadEmailUsers() -> [String: [String: String]] {
        if let data = UserDefaults.standard.data(forKey: emailUsersKey),
           let users = try? JSONDecoder().decode([String: [String: String]].self, from: data) {
            return users
        }
        return [:]
    }

    private func saveEmailUsers(_ users: [String: [String: String]]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: emailUsersKey)
        }
    }

    // MARK: - Google Email Storage

    private func loadGoogleEmails() -> Set<String> {
        if let data = UserDefaults.standard.data(forKey: googleEmailsKey),
           let emails = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return emails
        }
        return []
    }

    private func saveGoogleEmail(_ email: String) {
        var emails = loadGoogleEmails()
        emails.insert(email.lowercased())
        if let data = try? JSONEncoder().encode(emails) {
            UserDefaults.standard.set(data, forKey: googleEmailsKey)
        }
    }

    private func isEmailUsedByGoogle(_ email: String) -> Bool {
        let googleEmails = loadGoogleEmails()
        return googleEmails.contains(email.lowercased())
    }

    // MARK: - Apple Email Storage

    private func loadAppleEmails() -> Set<String> {
        if let data = UserDefaults.standard.data(forKey: appleEmailsKey),
           let emails = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return emails
        }
        return []
    }

    private func saveAppleEmail(_ email: String) {
        var emails = loadAppleEmails()
        emails.insert(email.lowercased())
        if let data = try? JSONEncoder().encode(emails) {
            UserDefaults.standard.set(data, forKey: appleEmailsKey)
        }
    }

    private func isEmailUsedByApple(_ email: String) -> Bool {
        let appleEmails = loadAppleEmails()
        return appleEmails.contains(email.lowercased())
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
