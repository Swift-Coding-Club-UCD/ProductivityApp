//
//  TaskCardView.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 2/18/26.
//

import SwiftUI

struct TaskCardView: View {
    @ObservedObject var store: TaskStore

    @State private var newTitle: String = ""
    @State private var selectedPriority: TaskPriority = .medium

    var body: some View {
        VStack(spacing: 14) {
            header
            addRow
            priorityPicker
            taskList
        }
        
        
        .padding(20)
        // makes card start small and grow with tasks
        .frame(minHeight: 200)          // starting size
        .frame(maxHeight: 500)       // prevents taking whole screen

        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(red: 1.00, green: 0.99, blue: 0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(.separator).opacity(0.6), lineWidth: 1)
        )
    
    }

    private var header: some View {
        HStack {
            Text("Today's Tasks")
                .font(.title3.weight(.semibold))

            Spacer()

            HStack(spacing: 10) {
                Text("\(store.completedCount)/\(store.totalCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Capsule().fill(Color(.systemTeal)))
        }
    }

    private var addRow: some View {
        HStack(spacing: 12) {
            TextField("Add a new task...", text: $newTitle)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.95, green: 0.92, blue: 0.86))
                )

            Button {
                store.addTask(title: newTitle, priority: selectedPriority)
                newTitle = ""
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemTeal))
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var priorityPicker: some View {
        HStack(spacing: 10) {
            ForEach(TaskPriority.allCases, id: \.self) { p in
                Button {
                    selectedPriority = p
                } label: {
                    Text(p.label)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(selectedPriority == p ? Color(.systemBackground) : Color(.label))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule().fill(selectedPriority == p ? priorityPickColor(p) : Color(.secondarySystemGroupedBackground))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var taskList: some View {
        ScrollView {
            VStack(spacing: 10) {

                // Uncompleted
                ForEach(store.activeTasks) { task in
                    TaskRow(
                        task: task,
                        onToggle: { store.toggle(task) },
                        onDelete: { store.delete(task) }
                    )
                }

                if !store.completedTasks.isEmpty {
                    Divider().padding(.vertical, 6)

                    Text("Completed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(store.completedTasks) { task in
                        TaskRow(
                            task: task,
                            onToggle: { store.toggle(task) },
                            onDelete: { store.delete(task) }
                        )
                    }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxHeight: 340)
    }

    private func priorityPickColor(_ p: TaskPriority) -> Color {
        switch p {
        case .low: return Color(.systemGreen)
        case .medium: return Color(.systemYellow)
        case .high: return Color(.systemRed)
        }
    }
}

// one task row card
private struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? Color(.systemTeal) : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 18, weight: .semibold))
                .strikethrough(task.isCompleted, color: Color(.secondaryLabel))
                .opacity(task.isCompleted ? 0.45 : 1.0)

            Spacer()

            Text(task.priority.rawValue)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 11)
                .background(priorityBadgeColor)
                .clipShape(Capsule())

            // Trash on every task (completed + uncompleted)
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.97, green: 0.95, blue: 0.90))
        )
        .shadow(color: .clear, radius: 0)
    }

    private var priorityBadgeColor: Color {
        switch task.priority {
        case .low: return Color(.systemGreen)
        case .medium: return Color(.systemYellow)
        case .high: return Color(.systemRed)
        }
    }
}



