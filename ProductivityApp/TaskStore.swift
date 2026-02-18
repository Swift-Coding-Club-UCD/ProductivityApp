//
//  TaskStore.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 2/18/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []

    @AppStorage("tasks_last_active_day") private var lastActiveDayISO: String = ""

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("tasks_today.json")
    }()

    init() {
        enforceDailyResetIfNeeded()
        load()
        startMidnightWatcher()
    }

    // MARK: - Derived lists
    var completedCount: Int { tasks.filter { $0.isCompleted }.count }
    var totalCount: Int { tasks.count }

    var activeTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }

    // adding tasks
    func addTask(title: String, priority: TaskPriority) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(title: trimmed, priority: priority))
        save()
    }

    func toggle(_ task: TaskItem) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].isCompleted.toggle()
        save()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    // MARK: - Daily reset
    private func enforceDailyResetIfNeeded() {
        let todayISO = Self.dayStampISO(Date())
        if lastActiveDayISO.isEmpty {
            lastActiveDayISO = todayISO
            return
        }
        if lastActiveDayISO != todayISO {
            tasks = []      // tasks disappear on new day
            save()
            lastActiveDayISO = todayISO
        }
    }

    private static func dayStampISO(_ date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    private func startMidnightWatcher() {
        let cal = Calendar.current
        let now = Date()

        guard let nextMidnight = cal.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) else { return }

        let interval = nextMidnight.timeIntervalSince(now)
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.enforceDailyResetIfNeeded()
                self?.startMidnightWatcher()
            }
        }
    }

    
    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            tasks = try JSONDecoder().decode([TaskItem].self, from: data)
        } catch {
            // no saved file yet (first run)
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // ignore for now
        }
    }
}
