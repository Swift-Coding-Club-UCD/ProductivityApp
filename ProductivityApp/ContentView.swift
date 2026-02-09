//
//  ContentView.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    // 1. 取得我們在進入點注入的驗證管理員
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        Group {
            // 2. 判斷目前是否有使用者登入
            if authManager.currentUser != nil {
                // 已登入：前往主畫面
                HomeView()
            } else {
                // 未登入：前往登入畫面
                AuthenticationView()
            }
        }
    }
}
