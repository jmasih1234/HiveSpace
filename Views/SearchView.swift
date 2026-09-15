import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        Text("Search tasks, expenses, messages, trips, and members.")
                            .foregroundStyle(HiveTheme.textSecondary)
                    }
                } else {
                    if !matchingTasks.isEmpty {
                        Section("Tasks") {
                            ForEach(matchingTasks) { task in
                                HStack {
                                    Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(task.status == .done ? HiveTheme.green : HiveTheme.textSecondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                        if let desc = task.description {
                                            Text(desc)
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(HiveTheme.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !matchingExpenses.isEmpty {
                        Section("Expenses") {
                            ForEach(matchingExpenses) { expense in
                                HStack {
                                    Text(expense.category.emoji)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(expense.title)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                        Text(store.currency(expense.amount))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(HiveTheme.textSecondary)
                                    }
                                    Spacer()
                                    if expense.isFullySettled {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(HiveTheme.green)
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                        }
                    }

                    if !matchingMessages.isEmpty {
                        Section("Messages") {
                            ForEach(matchingMessages) { message in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.senderName)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(HiveTheme.pink)
                                    Text(message.body)
                                        .font(.system(size: 14, design: .rounded))
                                        .lineLimit(2)
                                    Text(message.sentAt.formatted(.relative(presentation: .named)))
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundStyle(HiveTheme.textSecondary)
                                }
                            }
                        }
                    }

                    if !matchingMembers.isEmpty {
                        Section("Members") {
                            ForEach(matchingMembers) { member in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(HiveTheme.surfaceSoft)
                                        .frame(width: 30, height: 30)
                                        .overlay {
                                            Text(String(member.displayName.prefix(1)).uppercased())
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(HiveTheme.pink)
                                        }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.displayName)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                        Text("@\(member.username)")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(HiveTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    if !matchingTrips.isEmpty {
                        Section("Trips") {
                            ForEach(matchingTrips) { trip in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trip.title)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                    Text(trip.location)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(HiveTheme.textSecondary)
                                }
                            }
                        }
                    }

                    if matchingTasks.isEmpty && matchingExpenses.isEmpty && matchingMessages.isEmpty && matchingMembers.isEmpty && matchingTrips.isEmpty {
                        Section {
                            Text("No results for \"\(query)\"")
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search HiveSpace")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var matchingTasks: [HSTask] {
        guard !normalizedQuery.isEmpty else { return [] }
        return store.tasks.filter {
            $0.title.lowercased().contains(normalizedQuery)
            || ($0.description?.lowercased().contains(normalizedQuery) ?? false)
            || $0.tags.contains(where: { $0.lowercased().contains(normalizedQuery) })
        }
    }

    private var matchingExpenses: [Expense] {
        guard !normalizedQuery.isEmpty else { return [] }
        return store.expenses.filter {
            $0.title.lowercased().contains(normalizedQuery)
            || ($0.notes?.lowercased().contains(normalizedQuery) ?? false)
            || $0.category.rawValue.lowercased().contains(normalizedQuery)
        }
    }

    private var matchingMessages: [HSMessage] {
        guard !normalizedQuery.isEmpty else { return [] }
        return store.messages.filter {
            $0.body.lowercased().contains(normalizedQuery)
            || $0.senderName.lowercased().contains(normalizedQuery)
        }.prefix(20).map { $0 }
    }

    private var matchingMembers: [ColonyMember] {
        guard !normalizedQuery.isEmpty else { return [] }
        return store.colony.members.filter {
            $0.displayName.lowercased().contains(normalizedQuery)
            || $0.username.lowercased().contains(normalizedQuery)
        }
    }

    private var matchingTrips: [HiveTrip] {
        guard !normalizedQuery.isEmpty else { return [] }
        return store.trips.filter {
            $0.title.lowercased().contains(normalizedQuery)
            || $0.location.lowercased().contains(normalizedQuery)
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(HiveSpaceStore.sample)
}
