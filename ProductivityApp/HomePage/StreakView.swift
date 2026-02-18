//
//  StreakView.swift
//  ProductivityApp
//
//

import SwiftUI

struct StreakView: View {
    private let streakText = Color(red: 0.38, green: 0.20, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(streakText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("7")
                            .font(.system(size: 40, weight: .semibold))
                        Text("days")
                            .font(.headline)
                    }
                    .foregroundColor(streakText)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 54, height: 54)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(streakText)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Progress")
                        .fontWeight(.medium)
                    Spacer()
                    Text("1/3 tasks")
                        .fontWeight(.bold)
                }
                .foregroundColor(streakText)
                
                // Custom Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(streakText.opacity(0.2))
                        Capsule()
                            .fill(streakText)
                            .frame(width: geo.size.width * 0.33) // 1 out of 3
                    }
                }
                .frame(height: 8)
                
                Text("Complete 2 more tasks to maintain your streak")
                    .font(.footnote)
                    .foregroundColor(streakText)
            }
            
            Divider()
                .background(streakText.opacity(0.25))
            
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Longest streak: **12 days**")
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(streakText)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.yellow]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
    }
}


#Preview {
    StreakView()
}
