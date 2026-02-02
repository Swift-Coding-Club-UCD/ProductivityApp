//
//  DailyTaskView.swift
//  ProductivityApp
//
//  Created by Ava Kaplin on 2/2/26.
//

import SwiftUI

struct TaskItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
}


struct DailyTaskView: View {
    @State private var tasks: [TaskItem] = [
        TaskItem(title: "Read ch 3"), // for testing
        TaskItem(title: "workout")
    ]

    @State private var newTaskTitle: String = ""
    
    private var finishCount: Int {tasks.filter(\.isDone).count}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today's Tasks")
                    .font(.system(size:25, weight: .bold))
                Spacer()
                
                Text("\(finishCount)/\(tasks.count) done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    
            }
            VStack(alignment: .leading, spacing: 20) {
                ForEach($tasks) { $task in
                    HStack(spacing: 16) {
                        CheckTask(isChecked: $task.isDone)
                        Text(task.title)
                            .font(.system(size: 21, weight:.medium))
                    }
                }
            }
            
            HStack (spacing: 14){
                TextField("Add a new task...", text: $newTaskTitle)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical,16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.10),lineWidth: 2))
                Button {
                    addTask()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width:62, height:62)
                        .background(LinearGradient(colors: [
                            Color(red:0.60, green: 0.23, blue: 0.96),
                            Color(red:1.00, green: 0.22, blue: 0.49)
                        ], startPoint: .bottomLeading, endPoint: .topTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top,6)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .fill(Color.yellow.opacity(0.15))
        )
        .shadow(color: Color.black.opacity(0.10), radius: 18, x:0, y:10)
    }
    
    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(title: trimmed))
        newTaskTitle = ""
    }
    
}

struct CheckTask: View {
    @Binding var isChecked: Bool
    
    var body: some View {
        Button {
            withAnimation(.spring(response:0.25, dampingFraction: 0.9)) {
                isChecked.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 3)
                .frame(width:32, height:32)
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        //Color(red: 1.0, green: 0.95, blue: 0.97).ignoresSafeArea()
        DailyTaskView()
    }
}
