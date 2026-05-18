import Foundation
import SwiftUI
import Combine

struct Friend: Identifiable, Hashable, Codable {
    let id: String
    let ownerEmail: String
    let email: String
    var displayName: String?
    
    init(ownerEmail: String, email: String, displayName: String? = nil) {
            let normalizedOwner = ShareManager.normalizedEmail(ownerEmail)
            let normalizedFriend = ShareManager.normalizedEmail(email)
            self.id = "\(normalizedOwner)|\(normalizedFriend)"
            self.ownerEmail = normalizedOwner
            self.email = normalizedFriend
            self.displayName = displayName
        }
}

struct ShareInvite: Identifiable, Hashable, Codable {
    enum Status: String, Codable {
        case pending
        case accepted
        case declined
    }

    let id: UUID
    let fromEmail: String
    let toEmail: String
    var message: String?
    var status: Status

    init(
            id: UUID = UUID(),
            fromEmail: String,
            toEmail: String,
            message: String? = nil,
            status: Status = .pending
        ) {
            self.id = id
            self.fromEmail = ShareManager.normalizedEmail(fromEmail)
            self.toEmail = ShareManager.normalizedEmail(toEmail)
            self.message = message
            self.status = status
    }
}

struct SharedTask: Identifiable, Hashable, Codable {
    let id: UUID
    let sourceTaskID: UUID
    var title: String
    var ownerEmail: String
    var partnerEmail: String
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        sourceTaskID: UUID,
        title: String,
        ownerEmail: String,
        partnerEmail: String,
        isCompleted: Bool = false
        ) {
        self.id = id
        self.sourceTaskID = sourceTaskID
        self.title = title
        self.ownerEmail = ShareManager.normalizedEmail(ownerEmail)
        self.partnerEmail = ShareManager.normalizedEmail(partnerEmail)
        self.isCompleted = isCompleted
    }
}

@MainActor
final class ShareManager: ObservableObject {
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var invites: [ShareInvite] = []
    @Published private(set) var sharedTasks: [SharedTask] = []

    private let storageKey = "share_manager_storage_v2"

    init() {
        load()
    }

    static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func friends(for ownerEmail: String) -> [Friend] {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        return friends
            .filter { $0.ownerEmail == normalizedOwner }
            .sorted {
                resolvedDisplayName(for: $0).localizedCaseInsensitiveCompare(resolvedDisplayName(for: $1)) == .orderedAscending
            }
    }

    func outgoingInvites(from email: String) -> [ShareInvite] {
        let normalizedEmail = Self.normalizedEmail(email)
        return invites.filter { $0.fromEmail == normalizedEmail && $0.status == .pending }
    }

    func incomingInvites(for email: String) -> [ShareInvite] {
        let normalizedEmail = Self.normalizedEmail(email)
        return invites.filter { $0.toEmail == normalizedEmail && $0.status == .pending }
    }

    func allInvites(for email: String) -> [ShareInvite] {
        let normalizedEmail = Self.normalizedEmail(email)
        return invites.filter { $0.fromEmail == normalizedEmail || $0.toEmail == normalizedEmail }
    }

    func sendInvite(from fromEmail: String, to toEmail: String, message: String? = nil) -> Result<Void, ShareError> {
        let sender = Self.normalizedEmail(fromEmail)
        let recipient = Self.normalizedEmail(toEmail)

        guard !sender.isEmpty else { return .failure(.missingCurrentUserEmail) }
        guard Self.isValidEmail(recipient) else { return .failure(.invalidEmail) }
        guard sender != recipient else { return .failure(.cannotInviteYourself) }
        guard !isFriend(email: recipient, for: sender) else { return .failure(.alreadyFriends) }

        let duplicatePendingInvite = invites.contains {
            $0.status == .pending &&
            (($0.fromEmail == sender && $0.toEmail == recipient) ||
             ($0.fromEmail == recipient && $0.toEmail == sender))
        }

        guard !duplicatePendingInvite else { return .failure(.inviteAlreadyPending) }

        invites.append(
            ShareInvite(
                fromEmail: sender,
                toEmail: recipient,
                message: sanitizedMessage(message)
            )
        )
        save()
        return .success(())
    }

    func acceptInvite(_ invite: ShareInvite) {
        guard let index = invites.firstIndex(where: { $0.id == invite.id }) else { return }
        invites[index].status = .accepted

        let senderName = displayNameGuess(from: invites[index].fromEmail)
        let recipientName = displayNameGuess(from: invites[index].toEmail)

        addFriend(ownerEmail: invites[index].fromEmail, friendEmail: invites[index].toEmail, displayName: recipientName)
        addFriend(ownerEmail: invites[index].toEmail, friendEmail: invites[index].fromEmail, displayName: senderName)
        save()
    }

    func declineInvite(_ invite: ShareInvite) {
        guard let index = invites.firstIndex(where: { $0.id == invite.id }) else { return }
        invites[index].status = .declined
        save()
    }

    func removeFriend(ownerEmail: String, friendEmail: String) {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let normalizedFriend = Self.normalizedEmail(friendEmail)

        friends.removeAll {
            ($0.ownerEmail == normalizedOwner && $0.email == normalizedFriend) ||
            ($0.ownerEmail == normalizedFriend && $0.email == normalizedOwner)
        }

        sharedTasks.removeAll {
            let samePair =
                ($0.ownerEmail == normalizedOwner && $0.partnerEmail == normalizedFriend) ||
                ($0.ownerEmail == normalizedFriend && $0.partnerEmail == normalizedOwner)
            return samePair
        }

        save()
    }

    func sharedTasks(for email: String) -> [SharedTask] {
        let normalizedEmail = Self.normalizedEmail(email)
        return sharedTasks
            .filter { $0.ownerEmail == normalizedEmail || $0.partnerEmail == normalizedEmail }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func sharedTasks(between ownerEmail: String, and friendEmail: String) -> [SharedTask] {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let normalizedFriend = Self.normalizedEmail(friendEmail)
        return sharedTasks.filter { $0.ownerEmail == normalizedOwner && $0.partnerEmail == normalizedFriend }
    }

    func isTaskShared(taskID: UUID, ownerEmail: String, partnerEmail: String) -> Bool {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let normalizedFriend = Self.normalizedEmail(partnerEmail)
        return sharedTasks.contains {
            $0.sourceTaskID == taskID &&
            $0.ownerEmail == normalizedOwner &&
            $0.partnerEmail == normalizedFriend
        }
    }

    func toggleSharing(task: TaskItem, ownerEmail: String, partnerEmail: String) {
        if isTaskShared(taskID: task.id, ownerEmail: ownerEmail, partnerEmail: partnerEmail) {
            unshareTask(taskID: task.id, ownerEmail: ownerEmail, partnerEmail: partnerEmail)
        } else {
            createSharedTask(task: task, ownerEmail: ownerEmail, partnerEmail: partnerEmail)
        }
    }

    func createSharedTask(task: TaskItem, ownerEmail: String, partnerEmail: String) {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let normalizedFriend = Self.normalizedEmail(partnerEmail)

        guard isFriend(email: normalizedFriend, for: normalizedOwner) else { return }
        guard !isTaskShared(taskID: task.id, ownerEmail: normalizedOwner, partnerEmail: normalizedFriend) else { return }

        sharedTasks.append(
            SharedTask(
                sourceTaskID: task.id,
                title: task.title,
                ownerEmail: normalizedOwner,
                partnerEmail: normalizedFriend,
                isCompleted: task.isCompleted
            )
        )
        save()
    }

    func unshareTask(taskID: UUID, ownerEmail: String, partnerEmail: String) {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let normalizedFriend = Self.normalizedEmail(partnerEmail)
        sharedTasks.removeAll {
            $0.sourceTaskID == taskID &&
            $0.ownerEmail == normalizedOwner &&
            $0.partnerEmail == normalizedFriend
        }
        save()
    }

    func syncSharedTasks(with tasks: [TaskItem], ownerEmail: String) {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let taskLookup = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        var didChange = false

        for index in sharedTasks.indices {
            guard sharedTasks[index].ownerEmail == normalizedOwner else { continue }

            if let sourceTask = taskLookup[sharedTasks[index].sourceTaskID] {
                if sharedTasks[index].title != sourceTask.title {
                    sharedTasks[index].title = sourceTask.title
                    didChange = true
                }
                if sharedTasks[index].isCompleted != sourceTask.isCompleted {
                    sharedTasks[index].isCompleted = sourceTask.isCompleted
                    didChange = true
                }
            }
        }

        let idsToKeep = Set(tasks.map(\.id))
        let beforeCount = sharedTasks.count
        sharedTasks.removeAll {
            $0.ownerEmail == normalizedOwner && !idsToKeep.contains($0.sourceTaskID)
        }
        didChange = didChange || beforeCount != sharedTasks.count

        if didChange {
            save()
        }
    }

    func completedSharedTaskCount(with friendEmail: String, ownerEmail: String) -> Int {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let normalizedFriend = Self.normalizedEmail(friendEmail)
        return sharedTasks.filter {
            (($0.ownerEmail == normalizedOwner && $0.partnerEmail == normalizedFriend) ||
             ($0.ownerEmail == normalizedFriend && $0.partnerEmail == normalizedOwner)) &&
            $0.isCompleted
        }.count
    }

    func resolvedDisplayName(for friend: Friend) -> String {
        if let name = friend.displayName, !name.isEmpty {
            return name
        }
        return displayNameGuess(from: friend.email)
    }

    private func addFriend(ownerEmail: String, friendEmail: String, displayName: String?) {
        let friend = Friend(ownerEmail: ownerEmail, email: friendEmail, displayName: displayName)
        guard !friends.contains(where: { $0.id == friend.id }) else { return }
        friends.append(friend)
    }

    private func isFriend(email: String, for ownerEmail: String) -> Bool {
        let normalizedOwner = Self.normalizedEmail(ownerEmail)
        let normalizedFriend = Self.normalizedEmail(email)
        return friends.contains { $0.ownerEmail == normalizedOwner && $0.email == normalizedFriend }
    }

    private func displayNameGuess(from email: String) -> String {
        let localPart = email.split(separator: "@").first.map(String.init) ?? email
        let words = localPart
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }

        return words.isEmpty ? email : words.joined(separator: " ")
    }

    private func sanitizedMessage(_ message: String?) -> String? {
        guard let message else { return nil }
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func save() {
        let snapshot = Snapshot(friends: friends, invites: invites, sharedTasks: sharedTasks)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else {
            return
        }

        friends = snapshot.friends
        invites = snapshot.invites
        sharedTasks = snapshot.sharedTasks
    }
}

extension ShareManager {
    enum ShareError: LocalizedError {
        case missingCurrentUserEmail
        case invalidEmail
        case cannotInviteYourself
        case alreadyFriends
        case inviteAlreadyPending

        var errorDescription: String? {
            switch self {
            case .missingCurrentUserEmail:
                return "Your account does not have an email address yet."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .cannotInviteYourself:
                return "You cannot invite yourself."
            case .alreadyFriends:
                return "This friend is already connected."
            case .inviteAlreadyPending:
                return "An invite between these accounts is already pending."
            }
        }
    }
}

private extension ShareManager {
    struct Snapshot: Codable {
        var friends: [Friend]
        var invites: [ShareInvite]
        var sharedTasks: [SharedTask]
    }
}
