import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Binding var selectedTab: AppTab

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: "Good Morning, \(store.currentUser.displayName)",
                        title: store.colony.name,
                        subtitle: "Colony dashboard"
                    ) {
                        ColonySwitcherButton()
                    }

                    colonyCodeCard
                    heroCard
                    summaryCards
                    quickActions
                    if !store.choreWheels.isEmpty {
                        choreWheelSection
                    }
                    upcomingTasks
                    latestActivity
                }
                .padding(24)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var colonyCodeCard: some View {
        HiveCard {
            HiveSectionTitle(title: "Colony Code")
            HStack {
                Text(store.colony.joinCode)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = store.colony.joinCode
                }
                .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.textPrimary))
            }
        }
    }

    private var heroCard: some View {
        HiveCard {
            HiveSectionTitle(title: "Hive Health")

            HStack(alignment: .bottom, spacing: 6) {
                Text("\(store.healthScore.score)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                Text("/100")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(HiveTheme.textSecondary)
                Spacer()
                Text(store.healthScore.grade.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .foregroundStyle(HiveTheme.textPrimary)
                    .clipShape(Capsule())
            }

            ProgressView(value: Double(store.healthScore.score), total: 100)
                .tint(HiveTheme.pink)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)

            HStack(spacing: 12) {
                statChip(value: "\(store.openTasks.count)", label: "open\ntasks")
                statChip(value: store.currency(store.outstandingBalanceTotal), label: "owed")
                statChip(value: "\(store.colony.memberCount)/\(store.colony.members.count)", label: "active")
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            dashboardCard(
                title: "Outstanding",
                value: store.currency(store.outstandingBalanceTotal),
                subtitle: "Need to settle",
                icon: "creditcard.fill",
                accent: HiveTheme.pink
            )

            dashboardCard(
                title: "Pending nudges",
                value: "\(store.nudges.count)",
                subtitle: "Gentle reminders",
                icon: "bell.fill",
                accent: HiveTheme.magenta
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Quick Actions")

            HStack(spacing: 12) {
                actionCard("Open Tasks", icon: "checklist", color: HiveTheme.pink) {
                    selectedTab = .tasks
                }
                actionCard("Open Messages", icon: "message.fill", color: HiveTheme.purple) {
                    selectedTab = .messages
                }
                actionCard("View Split", icon: "wallet.bifold.fill", color: HiveTheme.magenta) {
                    selectedTab = .split
                }
            }
        }
    }

    private var upcomingTasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Upcoming Tasks")
                Spacer()
                Button("See all") {
                    selectedTab = .tasks
                }
                .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
            }

            ForEach(store.openTasks.prefix(3)) { task in
                HiveCard {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                HiveStatusDot(color: task.status == .todo ? HiveTheme.red : HiveTheme.yellow)
                                Text(task.status == .todo ? "OVERDUE" : task.status.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .tracking(1.2)
                                    .foregroundStyle(task.status == .todo ? HiveTheme.red : HiveTheme.yellow)
                            }

                            Text(task.title)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                            Text(task.description ?? "No task notes.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)

                            HStack {
                                Text(store.memberName(for: task.assignedToIDs.first ?? store.currentUser.id))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                                Spacer()
                                Button("Nudge") {
                                    store.sendNudge(for: task)
                                }
                                .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
                            }
                        }

                        Spacer()

                        Button {
                            store.completeTask(task)
                        } label: {
                            Image(systemName: "circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var latestActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Latest Activity")
                Spacer()
                Button("Open More") {
                    selectedTab = .more
                }
                .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
            }

            ForEach(store.activityEvents.prefix(3)) { event in
                HiveCard {
                    HStack(alignment: .top, spacing: 10) {
                        HiveStatusDot(color: HiveTheme.pink)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.type.label(actorName: event.actorName, metadata: event.metadata))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                            Text(event.createdAt.formatted(.relative(presentation: .named)))
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var choreWheelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Chore Wheel")

            ForEach(store.choreWheels) { chore in
                HiveCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(chore.choreName)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(HiveTheme.surfaceSoft)
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        Text(String(store.memberName(for: chore.currentAssigneeID).prefix(1)))
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundStyle(HiveTheme.pink)
                                    }
                                Text(store.memberName(for: chore.currentAssigneeID))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                            }
                        }
                        Spacer()
                        Button("Rotate") {
                            withAnimation(.spring(response: 0.3)) {
                                store.rotateChore(chore)
                            }
                        }
                        .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(HiveTheme.textPrimary)
    }

    private func dashboardCard(title: String, value: String, subtitle: String, icon: String, accent: Color) -> some View {
        HiveCard {
            Image(systemName: icon)
                .foregroundStyle(accent)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(HiveTheme.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(HiveTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionCard(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HiveCard {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(HiveTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(HiveTheme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        HomeView(selectedTab: .constant(.home))
            .environmentObject(HiveSpaceStore.sample)
    }
}
