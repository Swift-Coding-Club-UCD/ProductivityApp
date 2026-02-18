import Foundation
import SwiftUI
import Combine

struct Friend: Identifiable, Hashable {
    let id: String // use email as id for simplicity
    var displayName: String?
}

struct ShareInvite: Identifiable, Hashable {
    enum Status: String { case pending, accepted, declined }
    let id: UUID
    let fromEmail: String
    let toEmail: String
    var message: String?
    var status: Status

    init(fromEmail: String, toEmail: String, message: String? = nil, status: Status = .pending) {
        self.id = UUID()
        self.fromEmail = fromEmail
        self.toEmail = toEmail
        self.message = message
        self.status = status
    }
}

struct SharedTask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var ownerEmail: String
    var partnerEmail: String
    var isCompleted: Bool

    init(title: String, ownerEmail: String, partnerEmail: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.ownerEmail = ownerEmail
        self.partnerEmail = partnerEmail
        self.isCompleted = isCompleted
    }
}

final class ShareManager: ObservableObject {
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var invites: [ShareInvite] = []
    @Published private(set) var sharedTasks: [SharedTask] = []

    func addFriend(email: String, displayName: String? = nil) {
        let key = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !friends.contains(where: { $0.id == key }) else { return }
        friends.append(Friend(id: key, displayName: displayName))
    }

    func removeFriend(email: String) {
        let key = email.lowercased()
        friends.removeAll { $0.id == key }
        // Also clean up tasks involving this friend
        sharedTasks.removeAll { $0.partnerEmail.lowercased() == key || $0.ownerEmail.lowercased() == key }
    }

    func sendInvite(from fromEmail: String, to toEmail: String, message: String? = nil) {
        let invite = ShareInvite(fromEmail: fromEmail, toEmail: toEmail, message: message, status: .pending)
        invites.append(invite)
    }

    func acceptInvite(_ invite: ShareInvite) {
        guard let idx = invites.firstIndex(of: invite) else { return }
        invites[idx].status = .accepted
        // When accepted, add each other as friends
        addFriend(email: invite.fromEmail)
        addFriend(email: invite.toEmail)
    }

    func declineInvite(_ invite: ShareInvite) {
        guard let idx = invites.firstIndex(of: invite) else { return }
        invites[idx].status = .declined
    }

    func createSharedTask(title: String, ownerEmail: String, partnerEmail: String) {
        let task = SharedTask(title: title, ownerEmail: ownerEmail, partnerEmail: partnerEmail)
        sharedTasks.append(task)
    }

    func toggleTask(_ task: SharedTask) {
        guard let idx = sharedTasks.firstIndex(of: task) else { return }
        sharedTasks[idx].isCompleted.toggle()
    }

    func tasks(for email: String) -> [SharedTask] {
        let key = email.lowercased()
        return sharedTasks.filter { $0.ownerEmail.lowercased() == key || $0.partnerEmail.lowercased() == key }
    }
}

