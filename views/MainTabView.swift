import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: Tab = .dashboard

    enum Tab: Hashable {
        case dashboard
        case profile
        case share
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationTitle("Dashboard")
            }
            .tabItem { Label("Dashboard", systemImage: "house") }
            .tag(Tab.dashboard)

            NavigationStack {
                ProfileView()
                    .navigationTitle("Profile")
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(Tab.profile)

            NavigationStack {
                ShareView()
                    .navigationTitle("Share")
            }
            .tabItem { Label("Share", systemImage: "square.and.arrow.up") }
            .tag(Tab.share)

            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
    }
}
