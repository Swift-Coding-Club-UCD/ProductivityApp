//
//  ViewA.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 1/25/26.
//

import SwiftUI

struct ViewA: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem() {
                    Image(systemName: "house")
                    Text("Home")
                }
            ViewB()
                .tabItem() {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
            ViewC()
                .tabItem() {
                    Image(systemName: "slider.horizontal.3")
                    Text("Settings")
                }
        }
            
    }
}

#Preview {
    ViewA()
}
