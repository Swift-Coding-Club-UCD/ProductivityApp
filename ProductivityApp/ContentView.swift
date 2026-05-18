import SwiftUI

struct ContentView: View {
    // 1. 取得我們在進入點注入的驗證管理員
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        Group {
            // 判斷目前是否有使用者登入
            if authManager.currentUser != nil {
                ProfileView()
            } else {
                AuthenticationView()
            }
        }
    }
}

