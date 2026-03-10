import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthenticationManager())
}
