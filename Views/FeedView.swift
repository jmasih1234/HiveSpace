import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var store: HiveSpaceStore

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: "Colony",
                        title: "Feed",
                        subtitle: "All activity, updates, and nudges"
                    ) {
                        ColonySwitcherButton()
                    }

                    // Health Score Quick View
                    HiveCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hive Health")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                                HStack(spacing: 6) {
                                    Text("\(store.healthScore.score)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(HiveTheme.textPrimary)
                                    Text(store.healthScore.grade.rawValue)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(HiveTheme.surfaceSoft)
                                        .clipShape(Capsule())
                                        .foregroundStyle(HiveTheme.textSecondary)
                                }
                            }
                            Spacer()
                            ProgressView(value: Double(store.healthScore.score), total: 100)
                                .tint(HiveTheme.pink)
                                .frame(width: 80)
                        }
                    }

                    // Nudges
                    if !store.nudges.isEmpty {
                        HiveSectionTitle(title: "Recent Nudges", trailing: "\(store.nudges.count)")

                        ForEach(store.nudges) { nudge in
                            HiveCard {
                                HStack(spacing: 10) {
                                    Image(systemName: "hand.wave.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(HiveTheme.magenta)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(store.memberName(for: nudge.senderID)) nudged \(store.memberName(for: nudge.recipientID))")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(HiveTheme.textPrimary)
                                        if let message = nudge.message {
                                            Text(message)
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .foregroundStyle(HiveTheme.textSecondary)
                                        }
                                        Text(nudge.sentAt.formatted(.relative(presentation: .named)))
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundStyle(HiveTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    // Activity Feed
                    HiveSectionTitle(title: "Activity Feed", trailing: "\(store.activityEvents.count) events")

                    if store.activityEvents.isEmpty {
                        HiveEmptyState(
                            title: "No activity yet",
                            message: "Complete tasks, settle expenses, or nudge a hivemate to start the feed.",
                            systemImage: "bubble.left.and.bubble.right.fill"
                        )
                    }

                    ForEach(store.activityEvents) { event in
                        HiveCard {
                            HStack(alignment: .top, spacing: 10) {
                                activityIcon(for: event.type)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 6) {
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

                    // Settlement History
                    if !store.settlementRequests.isEmpty {
                        HiveSectionTitle(title: "Settlement History")

                        ForEach(store.settlementRequests) { settlement in
                            HiveCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(store.memberName(for: settlement.fromUserID)) paid \(store.memberName(for: settlement.toUserID))")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(HiveTheme.textPrimary)
                                        Text("\(settlement.method.rawValue) • \(settlement.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundStyle(HiveTheme.textSecondary)
                                    }
                                    Spacer()
                                    Text(store.currency(settlement.amount))
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(HiveTheme.green)
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Feed")
    }

    private func activityIcon(for type: ActivityType) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case .taskCreated: return ("plus.circle.fill", HiveTheme.purple)
            case .taskCompleted: return ("checkmark.circle.fill", HiveTheme.green)
            case .taskAssigned: return ("person.fill.badge.plus", HiveTheme.purple)
            case .taskOverdue: return ("exclamationmark.triangle.fill", HiveTheme.red)
            case .expenseAdded: return ("creditcard.fill", HiveTheme.pink)
            case .expenseSettled: return ("checkmark.seal.fill", HiveTheme.green)
            case .nudgeSent: return ("hand.wave.fill", HiveTheme.magenta)
            case .memberJoined: return ("person.badge.plus", HiveTheme.green)
            case .memberLeft: return ("person.badge.minus", HiveTheme.red)
            case .choreRotated: return ("arrow.triangle.2.circlepath", HiveTheme.yellow)
            case .semesterReset: return ("arrow.counterclockwise.circle.fill", HiveTheme.purple)
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.12))
            .clipShape(Circle())
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
