import Foundation
import Combine

final class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool
    @Published var userName: String?

    init(isAuthenticated: Bool = false, userName: String? = nil) {
        self.isAuthenticated = isAuthenticated
        self.userName = userName
    }

    func signIn(name: String) {
        userName = name
        isAuthenticated = true
    }

    func signOut() {
        userName = nil
        isAuthenticated = false
    }
}
