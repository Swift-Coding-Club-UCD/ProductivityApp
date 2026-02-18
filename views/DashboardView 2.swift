import SwiftUI

struct DashboardScreen: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Check-in Header
                VStack(spacing: 8) {
                    Text("Streak: \(authManager.currentStreak) days")
                        .font(.headline)
                    ProgressView(value: min(Double(authManager.currentStreak), 30), total: 30)
                    Text("\(authManager.currentStreak) / 30")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Check in") {
                        authManager.checkInIfNeeded()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                // Greeting Section
                VStack(alignment: .leading) {
                    Text("Welcome back!")
                        .font(.largeTitle)
                        .bold()
                    Text("Here's what's happening today.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Stats")
                        .font(.title2)
                        .bold()
                    // Example stat placeholders
                    HStack {
                        VStack {
                            Text("Tasks Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("12")
                                .font(.title3)
                                .bold()
                        }
                        Spacer()
                        VStack {
                            Text("Hours Logged")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("5.5")
                                .font(.title3)
                                .bold()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

                // Recent Activity Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activity")
                        .font(.title2)
                        .bold()
                    // Placeholder for recent activity list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Finished 'SwiftUI Tutorial'")
                        Text("• Completed daily check-in")
                        Text("• Added new task: 'Buy groceries'")
                    }
                    .font(.body)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

                // Quick Actions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.title2)
                        .bold()
                    HStack {
                        Button(action: {
                            // Action 1
                        }) {
                            Label("New Task", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: {
                            // Action 2
                        }) {
                            Label("View Stats", systemImage: "chart.bar")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            authManager.checkInIfNeeded()
        }
    }
}

#Preview {
    DashboardScreen()
        .environmentObject(AuthManager())
}
