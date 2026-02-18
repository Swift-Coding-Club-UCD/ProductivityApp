import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Dashboard (Coming Soon)")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .navigationTitle("Dashboard")
    }
}
