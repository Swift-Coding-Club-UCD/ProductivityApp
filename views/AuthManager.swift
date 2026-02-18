import Foundation
import Combine
import UIKit

enum AppAuthProvider {
    case apple
    case google
    case email
}

struct CurrentUser: Identifiable {
    var id: String
    var displayName: String?
    var email: String?
    var photoURL: URL?
    var authProvider: AppAuthProvider
}

final class AuthManager: ObservableObject {
    @Published var currentUser: CurrentUser?
    @Published var isAuthenticated: Bool
    @Published var userName: String?
    
    @Published var currentStreak: Int = 0
    @Published var lastCheckInDate: Date? = nil
    
    private let streakKey = "checkin_currentStreak"
    private let lastCheckInKey = "checkin_lastCheckInDate"

    init(isAuthenticated: Bool = false, userName: String? = nil, currentUser: CurrentUser? = nil) {
        self.isAuthenticated = isAuthenticated
        self.userName = userName
        self.currentUser = currentUser
        
        if let last = UserDefaults.standard.object(forKey: lastCheckInKey) as? Date {
            self.lastCheckInDate = last
        }
        self.currentStreak = UserDefaults.standard.integer(forKey: streakKey)
    }

    func signIn(name: String) {
        userName = name
        isAuthenticated = true
    }

    @MainActor
    func updateDisplayName(_ name: String) {
        self.userName = name
        if self.currentUser == nil {
            self.currentUser = CurrentUser(id: UUID().uuidString, displayName: name, email: nil, photoURL: nil, authProvider: AppAuthProvider.email)
        } else {
            self.currentUser?.displayName = name
        }
    }

    @MainActor
    func updatePhoto(with image: UIImage) async {
        // Stub: simulate upload and set a fake local URL
        try? await Task.sleep(nanoseconds: 400_000_000)
        // In a real app, upload the image and obtain a URL
        let tempURL = URL(string: "https://example.com/profile.jpg")
        if self.currentUser == nil {
            self.currentUser = CurrentUser(id: UUID().uuidString, displayName: self.userName, email: nil, photoURL: tempURL, authProvider: AppAuthProvider.email)
        } else {
            self.currentUser?.photoURL = tempURL
        }
    }

    @MainActor
    func removePhoto() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        self.currentUser?.photoURL = nil
    }

    @MainActor
    func updatePassword(current: String, new: String) async throws {
        // Stub: simulate delay and success
        try await Task.sleep(nanoseconds: 600_000_000)
    }

    func signOut() {
        userName = nil
        isAuthenticated = false
        currentUser = nil
    }
    
    private func persistStreak() {
        UserDefaults.standard.set(self.currentStreak, forKey: streakKey)
        if let last = self.lastCheckInDate {
            UserDefaults.standard.set(last, forKey: lastCheckInKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastCheckInKey)
        }
    }
    
    private func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
    
    @MainActor
    func checkInIfNeeded(referenceDate: Date = Date()) {
        let today = Calendar.current.startOfDay(for: referenceDate)
        if let last = lastCheckInDate {
            if isSameDay(last, today) {
                // already checked in today
                return
            }
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if isSameDay(last, yesterday) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            lastCheckInDate = today
        } else {
            // first ever check-in
            currentStreak = 1
            lastCheckInDate = today
        }
        persistStreak()
    }
    
    @MainActor
    func forceCheckInToday(referenceDate: Date = Date()) {
        let today = Calendar.current.startOfDay(for: referenceDate)
        if let last = lastCheckInDate, isSameDay(last, today) {
            return
        }
        if let last = lastCheckInDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if isSameDay(last, yesterday) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        lastCheckInDate = today
        persistStreak()
    }
}
