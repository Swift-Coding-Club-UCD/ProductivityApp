//
//  ContentView.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            DailyTaskView()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
