import SwiftUI

struct ShareView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var shareManager: ShareManager
    @EnvironmentObject var taskStore: TaskStore
   
    @State private var inviteEmail: String = ""
    @State private var selectedFriendEmail: String?
    @State private var statusMessage: String?

    private let appBackground = Color(red: 0.97, green: 0.96, blue: 0.94)
    private let primaryAccent = Color.cyan

    private var currentUserEmail: String {
        ShareManager.normalizedEmail(authManager.currentUser?.email ?? "")
    }

    private var currentUserDisplayName: String {
        authManager.currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? authManager.currentUser?.displayName ?? "You"
            : "You"
    }

    private var friends: [Friend] {
        shareManager.friends(for: currentUserEmail)
    }


    private var outgoingInvites: [ShareInvite] {
        shareManager.outgoingInvites(from: currentUserEmail)
    }

    private var incomingInvites: [ShareInvite] {
        shareManager.incomingInvites(for: currentUserEmail)
    }
    private var visibleSharedTasks: [SharedTask] {
        shareManager.sharedTasks(for: currentUserEmail)
    }

    var body: some View {
        ZStack {
            appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if currentUserEmail.isEmpty {
                        emailRequirementCard
                    } else {
                        friendsCard
                        invitesCard
                        shareTasksCard
                        sharedOverviewCard
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            syncSharedState()
            ensureSelectedFriend()
        }
        .onChange(of: taskStore.tasks) { _, _ in
            syncSharedState()
        }
        .onChange(of: friends.map(\.email)) { _, _ in
            ensureSelectedFriend()
        }
    }

    private var emailRequirementCard: some View {
        CardView(title: "Share Unavailable") {
            Text("This account does not have an email address yet, so invites and task sharing are disabled.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var friendsCard: some View {
        CardView(title: "Friends") {
            if friends.isEmpty {
                Text("Invite a friend to start sharing tasks and tracking progress together.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 16) {
                    ForEach(friends) { friend in
                        FriendRow(
                            name: shareManager.resolvedDisplayName(for: friend),
                            email: friend.email,
                            streak: shareManager.completedSharedTaskCount(with: friend.email, ownerEmail: currentUserEmail),
                            onRemove: {
                                shareManager.removeFriend(ownerEmail: currentUserEmail, friendEmail: friend.email)
                                statusMessage = "\(shareManager.resolvedDisplayName(for: friend)) was removed."
                            }
                        )
                    }
                }
            }
        }
    }

    private var invitesCard: some View {
        VStack(spacing: 20) {
            CardView(title: "Invite Friends") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        CustomTextField(placeholder: "friend@example.com", text: $inviteEmail)

                        Button(action: sendInvite) {
                            Text("Invite")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(
                                    inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.gray.opacity(0.3) : primaryAccent
                                )
                                .clipShape(Capsule())
                        }
                        .disabled(inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !incomingInvites.isEmpty || !outgoingInvites.isEmpty {
                CardView(title: "Pending Invites") {
                    VStack(spacing: 12) {
                        ForEach(incomingInvites) { invite in
                            InviteRow(
                                title: shareManager.resolvedDisplayName(
                                    for: Friend(ownerEmail: currentUserEmail, email: invite.fromEmail)
                                ),
                                subtitle: "\(invite.fromEmail) invited you",
                                primaryButtonTitle: "Accept",
                                primaryAction: {
                                    shareManager.acceptInvite(invite)
                                    statusMessage = "You are now connected with \(invite.fromEmail)."
                                },
                                secondaryButtonTitle: "Decline",
                                secondaryAction: {
                                    shareManager.declineInvite(invite)
                                    statusMessage = "Invite declined."
                                }
                            )
                        }

                        ForEach(outgoingInvites) { invite in
                            InviteRow(
                                title: shareManager.resolvedDisplayName(
                                    for: Friend(ownerEmail: currentUserEmail, email: invite.toEmail)
                                ),
                                subtitle: "Invite sent to \(invite.toEmail)",
                                primaryButtonTitle: "Connect",
                                primaryAction: {
                                    shareManager.acceptInvite(invite)
                                    statusMessage = "You are now connected with \(invite.toEmail)."
                                },
                                secondaryButtonTitle: "Cancel",
                                secondaryAction: {
                                    shareManager.declineInvite(invite)
                                    statusMessage = "Invite canceled."
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var shareTasksCard: some View {
        CardView(title: "Sharing Tasks") {
            if friends.isEmpty {
                Text("Connect with at least one friend before sharing tasks.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if taskStore.tasks.isEmpty {
                Text("Add a task on your dashboard, then come back here to share it with a friend.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select a friend, then choose which of your current tasks should be shared with them.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    friendPicker

                    if let selectedFriendEmail {
                        VStack(spacing: 0) {
                            ForEach(taskStore.tasks) { task in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        Text(task.priority.label)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        shareManager.toggleSharing(
                                            task: task,
                                            ownerEmail: currentUserEmail,
                                            partnerEmail: selectedFriendEmail
                                        )
                                        syncSharedState()
                                    } label: {
                                        Image(systemName: shareManager.isTaskShared(taskID: task.id, ownerEmail: currentUserEmail, partnerEmail: selectedFriendEmail) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22))
                                            .foregroundColor(
                                                shareManager.isTaskShared(taskID: task.id, ownerEmail: currentUserEmail, partnerEmail: selectedFriendEmail)
                                                ? primaryAccent : Color.gray.opacity(0.4)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 12)

                                if task.id != taskStore.tasks.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }

    private var sharedOverviewCard: some View {
        CardView(title: "Shared Tasks") {
            if visibleSharedTasks.isEmpty {
                Text("No tasks are shared yet. Pick a friend above and share a task to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(visibleSharedTasks) { task in
                        SharedTaskRow(
                            title: task.title,
                            ownerLabel: task.ownerEmail == currentUserEmail ? currentUserDisplayName : task.ownerEmail,
                            partnerLabel: task.partnerEmail == currentUserEmail ? currentUserDisplayName : task.partnerEmail,
                            isCompleted: task.isCompleted
                        )
                    }
                }
            }
        }
    }

    private var friendPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(friends) { friend in
                    let isSelected = selectedFriendEmail == friend.email
                    Button {
                        selectedFriendEmail = friend.email
                    } label: {
                        Text(shareManager.resolvedDisplayName(for: friend))
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isSelected ? primaryAccent : Color.black.opacity(0.05))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sendInvite() {
        switch shareManager.sendInvite(from: currentUserEmail, to: inviteEmail) {
        case .success:
            statusMessage = "Invite sent to \(ShareManager.normalizedEmail(inviteEmail))."
            inviteEmail = ""
        case .failure(let error):
            statusMessage = error.localizedDescription
        }
    }

    private func syncSharedState() {
        guard !currentUserEmail.isEmpty else { return }
        shareManager.syncSharedTasks(with: taskStore.tasks, ownerEmail: currentUserEmail)
    }

    private func ensureSelectedFriend() {
        let friendEmails = friends.map(\.email)
        if let selectedFriendEmail, friendEmails.contains(selectedFriendEmail) {
            return
        }
        selectedFriendEmail = friendEmails.first
    }
}

struct FriendRow: View {
    var name: String
    var email: String
    var streak: Int
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack {
            // 圓形頭像佔位符
            Circle()
                .fill(Color.cyan.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.cyan)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(email)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 新增：火焰與累計完成任務數徽章
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.subheadline)
                Text("\(streak)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15)) // 淡淡的橘色背景，讓火焰徽章更突出
            .clipShape(Capsule())

            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct InviteRow: View {
    let title: String
    let subtitle: String
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    let secondaryButtonTitle: String
    let secondaryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button(primaryButtonTitle, action: primaryAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)

                Button(secondaryButtonTitle, role: .destructive, action: secondaryAction)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
struct SharedTaskRow: View {
    let title: String
    let ownerLabel: String
    let partnerLabel: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isCompleted ? .green : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                Text("\(ownerLabel) sharing with \(partnerLabel)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(isCompleted ? "Done" : "In Progress")
                .font(.caption.weight(.semibold))
                .foregroundColor(isCompleted ? .green : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((isCompleted ? Color.green : Color.gray).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}


struct CardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            content
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color(red: 0.94, green: 0.93, blue: 0.91))
            .cornerRadius(12)
    }
}
#Preview {
    NavigationStack {
        ShareView()
            .environmentObject(AuthenticationManager())
            .environmentObject(ShareManager())
            .environmentObject(TaskStore())
    }
}
