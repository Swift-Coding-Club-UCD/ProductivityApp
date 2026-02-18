import SwiftUI

struct ShareView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var shareManager: ShareManager

    @State private var friendEmail: String = ""
    @State private var inviteEmail: String = ""
    @State private var inviteMessage: String = ""
    @State private var newTaskTitle: String = ""
    @State private var selectedPartner: String? = nil

    private var currentUserEmail: String? {
        authManager.currentUser?.email
    }

    var body: some View {
        List {
            Section("Add Friend") {
                HStack {
                    TextField("friend@example.com", text: $friendEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    Button("Add") {
                        addFriend()
                    }
                    .disabled(friendEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section("Invites") {
                HStack(alignment: .top) {
                    TextField("invitee@example.com", text: $inviteEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    Button("Send") { sendInvite() }
                        .disabled(currentUserEmail == nil || inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                TextField("Message (optional)", text: $inviteMessage)
                
                if shareManager.invites.isEmpty {
                    Text("No invites yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(shareManager.invites) { invite in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("From: \(invite.fromEmail)")
                                Text("To: \(invite.toEmail)")
                                    .foregroundStyle(.secondary)
                                Text("Status: \(invite.status.rawValue)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                if let msg = invite.message, !msg.isEmpty {
                                    Text("\"\(msg)\"")
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if invite.status == .pending, let myEmail = currentUserEmail, invite.toEmail.lowercased() == myEmail.lowercased() {
                                Button("Accept") { shareManager.acceptInvite(invite) }
                                Button("Decline") { shareManager.declineInvite(invite) }
                                    .tint(.red)
                            }
                        }
                    }
                }
            }

            Section("Friends") {
                if shareManager.friends.isEmpty {
                    Text("No friends yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(shareManager.friends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.displayName ?? friend.id)
                                Text(friend.id)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                shareManager.removeFriend(email: friend.id)
                            } label: { Image(systemName: "trash") }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPartner = friend.id }
                    }
                }
            }

            Section("Shared Tasks") {
                if let email = currentUserEmail {
                    let tasks = shareManager.tasks(for: email)
                    if tasks.isEmpty {
                        Text("No shared tasks yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tasks) { task in
                            HStack {
                                Button(action: { shareManager.toggleTask(task) }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                }
                                .buttonStyle(.plain)
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                    Text("With: \(task.partnerEmail == email ? task.ownerEmail : task.partnerEmail)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Text("Sign in to see shared tasks")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Create Shared Task") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Task title", text: $newTaskTitle)
                    Picker("Partner", selection: $selectedPartner) {
                        Text("Select a friend").tag(String?.none)
                        ForEach(shareManager.friends) { friend in
                            Text(friend.displayName ?? friend.id).tag(String?.some(friend.id))
                        }
                    }
                    Button("Create Task") { createTask() }
                        .disabled(currentUserEmail == nil || newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPartner == nil)
                }
            }
        }
        .navigationTitle("Share")
    }

    private func addFriend() {
        let email = friendEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return }
        shareManager.addFriend(email: email)
        friendEmail = ""
    }

    private func sendInvite() {
        guard let myEmail = currentUserEmail else { return }
        let to = inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !to.isEmpty else { return }
        shareManager.sendInvite(from: myEmail, to: to, message: inviteMessage.isEmpty ? nil : inviteMessage)
        inviteEmail = ""
        inviteMessage = ""
    }

    private func createTask() {
        guard let myEmail = currentUserEmail, let partner = selectedPartner else { return }
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        shareManager.createSharedTask(title: title, ownerEmail: myEmail, partnerEmail: partner)
        newTaskTitle = ""
        selectedPartner = nil
    }
}

#Preview {
    NavigationStack {
        ShareView()
            .environmentObject(AuthManager(isAuthenticated: true, currentUser: CurrentUser(id: "1", displayName: "Me", email: "me@example.com", photoURL: nil, authProvider: .email)))
            .environmentObject(ShareManager())
    }
}
