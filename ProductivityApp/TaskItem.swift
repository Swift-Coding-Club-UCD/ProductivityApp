//
//  TaskItem.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 2/18/26.
//

import Foundation

enum TaskPriority: String, CaseIterable, Codable {
    case low
    case medium
    case high

    var label: String { rawValue.capitalized }
}

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var priority: TaskPriority
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, priority: TaskPriority, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isCompleted = isCompleted
    }
}
