//
//  DeadlineView.swift
//  ProductivityApp
//
//

import SwiftUI

private struct DeadlineItem: Identifiable {
    let id = UUID()
    let title: String
    let dueDate: Date?
    let color: Color
}

struct DeadlineView: View {
    @State private var isExpanded = false
    @State private var newTitle = ""
    @State private var newDue = ""
    @State private var deadlines: [DeadlineItem] = [
        DeadlineItem(title: "Math Homework", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), color: .orange),
        DeadlineItem(title: "History Essay", dueDate: Self.nextWeekday(6), color: .pink), // Friday
        DeadlineItem(title: "Chemistry Quiz", dueDate: Self.nextWeekday(2), color: .mint) // Monday
    ]

    private var sortedDeadlines: [DeadlineItem] {
        deadlines.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (.some(l), .some(r)):
                return l < r
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }

    private var visibleDeadlines: [DeadlineItem] {
        isExpanded ? sortedDeadlines : Array(sortedDeadlines.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Deadlines")
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(Color(.systemTeal))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            ForEach(visibleDeadlines) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))
                        Text(Self.dueText(for: item.dueDate))
                            .font(.footnote)
                            .foregroundStyle(Color(.secondaryLabel))
                    }

                    Spacer()

                    Button {
                        deadlines.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.97, green: 0.95, blue: 0.90))
                )
                .shadow(color: .clear, radius: 0)
            }

            if isExpanded {
                VStack(spacing: 10) {
                    TextField("Task name", text: $newTitle)
                        .textFieldStyle(.roundedBorder)

                    TextField("Due date", text: $newDue)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let due = newDue.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty else { return }
                        deadlines.insert(
                            DeadlineItem(
                                title: title,
                                dueDate: Self.parseDueDate(from: due),
                                color: .blue
                            )
                            , at: 0
                        )
                        newTitle = ""
                        newDue = ""
                    } label: {
                        Text("Add Deadline")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color(.systemTeal))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 1.00, green: 0.99, blue: 0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
        )
    }

    private static func dueText(for dueDate: Date?) -> String {
        guard let dueDate else { return "Due Soon" }
        let cal = Calendar.current
        if cal.isDateInToday(dueDate) { return "Due Today" }
        if cal.isDateInTomorrow(dueDate) { return "Due Tomorrow" }

        let startToday = cal.startOfDay(for: Date())
        let startDue = cal.startOfDay(for: dueDate)
        if let days = cal.dateComponents([.day], from: startToday, to: startDue).day,
           days >= 2, days <= 6 {
            let weekday = DateFormatter()
            weekday.dateFormat = "EEEE"
            return "Due \(weekday.string(from: dueDate))"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Due \(formatter.string(from: dueDate))"
    }

    private static func parseDueDate(from input: String) -> Date? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let lower = trimmed.lowercased()
        let cal = Calendar.current
        let now = Date()

        if lower == "today" { return now }
        if lower == "tomorrow" { return cal.date(byAdding: .day, value: 1, to: now) }

        let weekdayMap: [String: Int] = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7
        ]
        if let weekday = weekdayMap[lower] {
            return nextWeekday(weekday)
        }

        let formats = ["M/d/yyyy", "M/d/yy", "M/d", "MM/dd/yyyy", "MM/dd/yy", "MM/dd"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let parsed = formatter.date(from: trimmed) {
                if format == "M/d" || format == "MM/dd" {
                    let comps = cal.dateComponents([.month, .day], from: parsed)
                    var candidate = cal.date(from: DateComponents(
                        year: cal.component(.year, from: now),
                        month: comps.month,
                        day: comps.day
                    ))
                    if let candidateDate = candidate, candidateDate < cal.startOfDay(for: now) {
                        candidate = cal.date(byAdding: .year, value: 1, to: candidateDate)
                    }
                    return candidate
                }
                return parsed
            }
        }

        return nil
    }

    private static func nextWeekday(_ weekday: Int) -> Date? {
        let cal = Calendar.current
        let today = Date()
        return cal.nextDate(
            after: today,
            matching: DateComponents(weekday: weekday),
            matchingPolicy: .nextTimePreservingSmallerComponents
        )
    }
}


#Preview {
    DeadlineView()
}
