//
//  HomeView.swift
//  ProductivityApp
//
//

import SwiftUI

struct HomeView: View {
    @StateObject private var store = TaskStore()
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.92).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    HomeHeaderView()
                        .padding(.horizontal)

                    StreakView(store: store)
                        .padding(.horizontal)

                    TaskCardView(store: store)
                        .padding(.horizontal)

                    DeadlineView()
                        .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
        }
    }
}

private struct HomeHeaderView: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: 44, height: 44)
                Image(systemName: "teddybear.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("APP NAME HERE")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                Text("possible subtext")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.73, green: 0.49, blue: 0.33),
                            Color(red: 0.58, green: 0.34, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
}

