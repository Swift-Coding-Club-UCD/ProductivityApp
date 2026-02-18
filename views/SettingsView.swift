import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("settings_notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("settings_appearance") private var appearance: Appearance = .system
    @State private var isConfirmingResetStreak: Bool = false
    @State private var isConfirmingSignOut: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Enable Notifications", systemImage: "bell")
                    }
                    Picker(selection: $appearance) {
                        ForEach(Appearance.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    } label: {
                        Label("Appearance", systemImage: "moon.circle")
                    }
                }

                Section(header: Text("Account")) {
                    if let email = authManager.currentUser?.email {
                        HStack {
                            Label("Email", systemImage: "envelope")
                            Spacer()
                            Text(email).foregroundStyle(.secondary)
                        }
                    }
                    Button(role: .destructive) {
                        isConfirmingSignOut = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section(header: Text("Check-in"), footer: Text("Current streak: \(authManager.currentStreak) days")) {
                    Button {
                        isConfirmingResetStreak = true
                    } label: {
                        Label("Reset Streak", systemImage: "arrow.counterclockwise")
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersionString).foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset Check-in Streak?", isPresented: $isConfirmingResetStreak, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    resetStreak()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear your current streak and last check-in date.")
            }
            .alert("Sign Out", isPresented: $isConfirmingSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .preferredColorScheme(appearance.colorScheme)
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "v\(version) (\(build))"
    }

    private func resetStreak() {
        // Clear AuthManager's streak-related values
        authManager.currentStreak = 0
        authManager.lastCheckInDate = nil
        // Also clear persisted values in UserDefaults to keep consistency
        UserDefaults.standard.removeObject(forKey: "checkin_currentStreak")
        UserDefaults.standard.removeObject(forKey: "checkin_lastCheckInDate")
    }
}

// MARK: - Appearance

enum Appearance: String, CaseIterable, Codable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthManager())
    }
}
