import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Binding var selectedTab: AppTab

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<22: return "Good evening,"
        default: return "Good night,"
        }
    }

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: HiveSpacing.xl) {

                    // MARK: Greeting + Actions
                    greetingHeader

                    // MARK: House Identity
                    houseIdentityCard

                    // MARK: Hive Health
                    hiveHealthSection

                    // MARK: Today Summary
                    todaySummary

                    // MARK: Tasks
                    if !store.openTasks.isEmpty {
                        taskSection
                    }

                    // MARK: Recent Activity
                    if !store.activityEvents.isEmpty {
                        activitySection
                    }

                    // MARK: Chore Wheel
                    if !store.choreWheels.isEmpty {
                        choreWheelSection
                    }
                }
                .padding(HiveSpacing.xxl)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(HiveFont.caption)
                    .foregroundStyle(HiveColor.textSecondaryFallback)

                Text("\(store.currentUser.displayName).")
                    .font(HiveFont.serif(30, weight: .semibold))
                    .foregroundStyle(HiveColor.textPrimaryFallback)
            }

            Spacer()

            HStack(spacing: HiveSpacing.md) {
                // Notification bell
                Button {
                    selectedTab = .inbox
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(HiveColor.textSecondaryFallback)
                            .frame(width: 36, height: 36)
                            .background(HiveColor.surfaceFallback)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
                            }

                        if store.totalUnreadMessages > 0 {
                            Circle()
                                .fill(HiveColor.brandFallback)
                                .frame(width: 8, height: 8)
                                .offset(x: 1, y: -1)
                        }
                    }
                }

                // Avatar
                Circle()
                    .fill(HiveColor.brandSubtleFallback)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(String(store.currentUser.displayName.prefix(1)))
                            .font(HiveFont.body(14, weight: .semibold))
                            .foregroundStyle(HiveColor.brandFallback)
                    }
            }
        }
    }

    // MARK: - House Identity Card

    private var houseIdentityCard: some View {
        NavigationLink {
            ColonyView(onSignOut: { /* handled by House tab */ })
        } label: {
            HStack(spacing: HiveSpacing.md) {
                // House thumbnail
                RoundedRectangle(cornerRadius: HiveRadius.sm, style: .continuous)
                    .fill(HiveColor.surfaceElevatedFallback)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text(store.colony.emoji)
                            .font(.system(size: 24))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(store.colony.name)
                        .font(HiveFont.serif(18, weight: .semibold))
                        .foregroundStyle(HiveColor.textPrimaryFallback)
                    Text("\(store.colony.memberCount) members")
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HiveColor.textSecondaryFallback)
            }
            .padding(HiveSpacing.lg)
            .background(HiveColor.surfaceFallback)
            .overlay {
                RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous)
                    .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous))
        }
    }

    // MARK: - Hive Health

    private var hiveHealthSection: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.sm) {
            Text("HIVE HEALTH")
                .font(HiveFont.label)
                .tracking(1.2)
                .foregroundStyle(HiveColor.textSecondaryFallback)

            HiveCard {
                HiveHealthIndicator(
                    score: store.healthScore.score,
                    grade: store.healthScore.grade.rawValue,
                    summary: healthSummary
                )
            }
        }
    }

    private var healthSummary: String {
        switch store.healthScore.grade {
        case .thriving: return "Excellent — your home is running smoothly."
        case .active: return "A great week — keep it up."
        case .sluggish: return "Things have slowed down. Time to pitch in."
        case .dormant: return "Your home needs attention."
        }
    }

    // MARK: - Today Summary

    private var todaySummary: some View {
        let tasksDueToday = store.openTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return Calendar.current.isDateInToday(due) || due < .now
        }.count
        let unsettledCount = store.unsettledExpenses.count

        return VStack(alignment: .leading, spacing: HiveSpacing.sm) {
            Text("TODAY")
                .font(HiveFont.label)
                .tracking(1.2)
                .foregroundStyle(HiveColor.textSecondaryFallback)

            HStack(spacing: HiveSpacing.lg) {
                if tasksDueToday > 0 || unsettledCount > 0 {
                    Text(todayLine(tasks: tasksDueToday, payments: unsettledCount))
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                } else {
                    Text("Nothing pressing — enjoy your day.")
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                }
            }
        }
    }

    private func todayLine(tasks: Int, payments: Int) -> String {
        var parts: [String] = []
        if tasks > 0 {
            parts.append("\(tasks) \(tasks == 1 ? "task" : "tasks") due")
        }
        if payments > 0 {
            parts.append("\(payments) \(payments == 1 ? "payment" : "payments")")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Task Section

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.sm) {
            HiveSectionHeader(title: "Upcoming Tasks", action: "See all") {
                selectedTab = .tasks
            }

            VStack(spacing: 0) {
                ForEach(Array(store.openTasks.prefix(4).enumerated()), id: \.element.id) { index, task in
                    HiveTaskRow(
                        title: task.title,
                        subtitle: taskSubtitle(task),
                        statusColor: taskStatusColor(task),
                        statusLabel: taskStatusLabel(task),
                        isCompleted: task.status == .done
                    ) {
                        store.toggleTaskCompletion(task)
                    }

                    if index < min(store.openTasks.count, 4) - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func taskSubtitle(_ task: HSTask) -> String {
        var parts: [String] = []
        if let due = task.dueDate {
            if due < .now && task.status != .done {
                parts.append("Overdue")
            } else if Calendar.current.isDateInToday(due) {
                parts.append("Due today")
            } else if Calendar.current.isDateInTomorrow(due) {
                parts.append("Due tomorrow")
            } else {
                parts.append(due.formatted(.dateTime.weekday(.wide)))
            }
        }
        if let firstAssignee = task.assignedToIDs.first {
            parts.append(store.memberName(for: firstAssignee))
        }
        return parts.joined(separator: " · ")
    }

    private func taskStatusColor(_ task: HSTask) -> Color {
        if let due = task.dueDate, due < .now, task.status != .done {
            return HiveColor.clay
        }
        if let due = task.dueDate, Calendar.current.isDateInToday(due) {
            return HiveColor.honey
        }
        return HiveColor.textSecondaryFallback
    }

    private func taskStatusLabel(_ task: HSTask) -> String? {
        if let due = task.dueDate, due < .now, task.status != .done {
            return "Overdue"
        }
        return nil
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.sm) {
            HiveSectionHeader(title: "Recent Activity")

            VStack(spacing: 0) {
                ForEach(Array(store.activityEvents.prefix(3).enumerated()), id: \.element.id) { index, event in
                    activityRow(event)

                    if index < min(store.activityEvents.count, 3) - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func activityRow(_ event: ActivityEvent) -> some View {
        HStack(alignment: .top, spacing: HiveSpacing.md) {
            Image(systemName: activityIcon(event.type))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(activityColor(event.type))
                .frame(width: 26, height: 26)
                .background(activityColor(event.type).opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.label(actorName: event.actorName, metadata: event.metadata))
                    .font(HiveFont.caption)
                    .foregroundStyle(HiveColor.textPrimaryFallback)
                Text(event.createdAt.formatted(.relative(presentation: .named)))
                    .font(HiveFont.smallDetail)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
            }

            Spacer()
        }
        .padding(.vertical, HiveSpacing.sm)
    }

    private func activityIcon(_ type: ActivityType) -> String {
        switch type {
        case .taskCreated: return "plus.circle"
        case .taskCompleted: return "checkmark.circle"
        case .taskAssigned: return "person.badge.plus"
        case .taskOverdue: return "exclamationmark.triangle"
        case .expenseAdded: return "creditcard"
        case .expenseSettled: return "checkmark.seal"
        case .nudgeSent: return "hand.wave"
        case .memberJoined: return "person.badge.plus"
        case .memberLeft: return "person.badge.minus"
        case .choreRotated: return "arrow.triangle.2.circlepath"
        case .semesterReset: return "arrow.counterclockwise.circle"
        }
    }

    private func activityColor(_ type: ActivityType) -> Color {
        switch type {
        case .taskCompleted, .expenseSettled, .memberJoined: return HiveColor.sage
        case .taskOverdue, .memberLeft: return HiveColor.clay
        case .expenseAdded: return HiveColor.brandFallback
        case .nudgeSent: return HiveColor.honey
        case .choreRotated: return HiveColor.honey
        case .taskCreated, .taskAssigned: return HiveColor.textSecondaryFallback
        case .semesterReset: return HiveColor.recurring
        }
    }

    // MARK: - Chore Wheel

    private var choreWheelSection: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.sm) {
            HiveSectionHeader(title: "Chore Wheel")

            VStack(spacing: 0) {
                ForEach(Array(store.choreWheels.enumerated()), id: \.element.id) { index, chore in
                    HStack {
                        VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                            Text(chore.choreName)
                                .font(HiveFont.bodyMedium)
                                .foregroundStyle(HiveColor.textPrimaryFallback)
                            HStack(spacing: HiveSpacing.xs) {
                                Circle()
                                    .fill(HiveColor.brandSubtleFallback)
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        Text(String(store.memberName(for: chore.currentAssigneeID).prefix(1)))
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(HiveColor.brandFallback)
                                    }
                                Text(store.memberName(for: chore.currentAssigneeID))
                                    .font(HiveFont.caption)
                                    .foregroundStyle(HiveColor.textSecondaryFallback)
                            }
                        }
                        Spacer()
                        Button("Rotate") {
                            withAnimation(.spring(response: 0.3)) {
                                store.rotateChore(chore)
                            }
                        }
                        .buttonStyle(HiveGhostButtonStyle())
                    }
                    .padding(.vertical, HiveSpacing.sm)

                    if index < store.choreWheels.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(selectedTab: .constant(.home))
            .environmentObject(HiveSpaceStore.sample)
    }
}
