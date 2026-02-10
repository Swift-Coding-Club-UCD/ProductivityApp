import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            // Dashboard placeholder
            NavigationStack {
                Text("Dashboard (Coming Soon)")
                    .navigationTitle("Dashboard")
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }

            // Profile tab with ProfileView
            NavigationStack {
                ProfileView()
                    .navigationTitle("Profile")
                    .environmentObject(authManager)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }

            // Share tab (placeholder)
            NavigationStack {
                Text("Share (Coming Soon)")
                    .navigationTitle("Share")
            }
            .tabItem {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}
