import PhotosUI
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Binding var selectedTab: AppTab
    @State private var selectedBackgroundItem: PhotosPickerItem?
    @State private var customHeroImage: UIImage?
    @State private var backgroundPickerError: String?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<22: return "Good evening,"
        default: return "Good night,"
        }
    }

    private var firstName: String {
        store.currentUser.displayName
            .split(separator: " ")
            .first
            .map(String.init) ?? store.currentUser.displayName
    }

    private var tasksDueToday: Int {
        store.openTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return Calendar.current.isDateInToday(due) || due < .now
        }.count
    }

    private var heroSubtitle: String {
        if tasksDueToday > 0 {
            return "\(tasksDueToday) \(tasksDueToday == 1 ? "thing needs" : "things need") attention today."
        }

        if !store.unsettledExpenses.isEmpty {
            return "A few shared expenses are ready to settle."
        }

        return "A more organized home is a happier home."
    }

    private var upcomingPlan: HomePlanSummary {
        if let trip = store.activeTrip {
            return HomePlanSummary(title: "Trip", value: trip.title, icon: "suitcase.rolling")
        }

        if let call = store.activeCallSession {
            return HomePlanSummary(title: "Call", value: call.title, icon: call.type == .video ? "video.fill" : "phone.fill")
        }

        if let poll = store.activeAvailabilityPoll {
            return HomePlanSummary(title: "Plan", value: poll.title, icon: "calendar.badge.clock")
        }

        return HomePlanSummary(title: "People", value: "\(store.colony.memberCount) at home", icon: "person.3.fill")
    }

    private var latestMessagePreview: HomeMessagePreview? {
        guard let message = store.messages.sorted(by: { $0.sentAt > $1.sentAt }).first else {
            return nil
        }
        return HomeMessagePreview(
            senderName: message.senderName,
            body: message.body,
            sentAt: message.sentAt
        )
    }

    var body: some View {
        HiveScreen {
            GeometryReader { proxy in
                let contentWidth = max(0, proxy.size.width - (HiveSpacing.lg * 2))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HiveSpacing.xl) {
                        HomeHeroSection(
                            greeting: greeting,
                            firstName: firstName,
                            subtitle: heroSubtitle,
                            colonyName: store.colony.name,
                            memberNames: store.colony.members.map(\.displayName),
                            unreadCount: store.totalUnreadMessages,
                            taskValue: tasksDueToday == 0 ? "Clear" : "\(tasksDueToday) due",
                            expenseValue: store.unsettledExpenses.isEmpty ? "Settled" : store.currency(store.outstandingBalanceTotal),
                            plan: upcomingPlan,
                            customImage: customHeroImage,
                            selectedBackgroundItem: $selectedBackgroundItem,
                            canResetBackground: customHeroImage != nil,
                            onNotifications: { selectedTab = .inbox },
                            onTasks: { selectedTab = .tasks },
                            onExpenses: { selectedTab = .expenses },
                            onPlan: { selectedTab = upcomingPlan.title == "Call" ? .calls : .house },
                            onResetBackground: resetHeroBackground
                        )

                        if let backgroundPickerError {
                            Text(backgroundPickerError)
                                .font(HiveFont.caption)
                                .foregroundStyle(HiveColor.coral)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HouseholdSnapshotCard(
                            score: store.healthScore.score,
                            grade: store.healthScore.grade.rawValue,
                            summary: healthSummary,
                            values: healthSparklineValues,
                            onOpenHouse: { selectedTab = .house }
                        )

                        HomeActivitySection(
                            events: Array(store.activityEvents.prefix(3)),
                            latestMessage: latestMessagePreview,
                            labelForEvent: activityLabel,
                            tintForEvent: activityColor
                        )

                        if !store.openTasks.isEmpty {
                            HomeTaskPreviewSection(
                                tasks: Array(store.openTasks.prefix(3)),
                                memberName: store.memberName,
                                onOpenTasks: { selectedTab = .tasks },
                                onToggleTask: { task in
                                    store.toggleTaskCompletion(task)
                                }
                            )
                        }
                    }
                    .frame(width: contentWidth)
                    .padding(.horizontal, HiveSpacing.lg)
                    .padding(.top, HiveSpacing.md)
                    .padding(.bottom, 180)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            customHeroImage = HomeBackgroundImageService.loadImage()
        }
        .onChange(of: selectedBackgroundItem) { item in
            guard let item else { return }

            Task {
                await updateHeroBackground(from: item)
            }
        }
    }

    private var healthSummary: String {
        switch store.healthScore.grade {
        case .thriving: return "Your home is running beautifully."
        case .active: return "A steady week. Keep the rhythm."
        case .sluggish: return "A few routines need attention."
        case .dormant: return "Start with one shared win today."
        }
    }

    private var healthSparklineValues: [Double] {
        [
            store.healthScore.taskCompletionRate,
            store.healthScore.balanceSettlementRate,
            store.healthScore.memberActivityRate,
            store.healthScore.choreComplianceRate,
            Double(store.healthScore.score) / 100
        ]
    }

    private func activityLabel(_ event: ActivityEvent) -> String {
        event.type
            .label(actorName: event.actorName, metadata: event.metadata)
            .replacingOccurrences(of: " ✓", with: "")
            .replacingOccurrences(of: " 👋", with: "")
            .replacingOccurrences(of: " 🎓", with: "")
    }

    private func activityColor(_ event: ActivityEvent) -> Color {
        switch event.type {
        case .taskCompleted, .expenseSettled, .memberJoined:
            return HiveColor.successAccent
        case .taskOverdue, .memberLeft:
            return HiveColor.attentionAccent
        case .expenseAdded:
            return HiveColor.premiumAccent
        case .nudgeSent, .choreRotated:
            return HiveColor.honey
        case .taskCreated, .taskAssigned:
            return HiveColor.secondaryLightText
        case .semesterReset:
            return HiveColor.recurring
        }
    }

    @MainActor
    private func updateHeroBackground(from item: PhotosPickerItem) async {
        backgroundPickerError = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                backgroundPickerError = "That image could not be loaded."
                return
            }

            customHeroImage = try HomeBackgroundImageService.saveImageData(data)
        } catch {
            backgroundPickerError = "Choose a different image for the Home background."
        }
    }

    private func resetHeroBackground() {
        HomeBackgroundImageService.deleteImage()
        customHeroImage = nil
        selectedBackgroundItem = nil
        backgroundPickerError = nil
    }
}

private struct HomePlanSummary {
    let title: String
    let value: String
    let icon: String
}

private struct HomeMessagePreview {
    let senderName: String
    let body: String
    let sentAt: Date
}

private struct HomeHeroSection: View {
    let greeting: String
    let firstName: String
    let subtitle: String
    let colonyName: String
    let memberNames: [String]
    let unreadCount: Int
    let taskValue: String
    let expenseValue: String
    let plan: HomePlanSummary
    let customImage: UIImage?
    @Binding var selectedBackgroundItem: PhotosPickerItem?
    let canResetBackground: Bool
    let onNotifications: () -> Void
    let onTasks: () -> Void
    let onExpenses: () -> Void
    let onPlan: () -> Void
    let onResetBackground: () -> Void

    var body: some View {
        HivePhotoHero(
            imageName: "home_hero_interior",
            customImage: customImage,
            accessibilityLabel: "Warm shared living room",
            height: 500
        ) {
            VStack(alignment: .leading, spacing: 0) {
                HomeHeroChrome(
                    colonyName: colonyName,
                    firstName: firstName,
                    unreadCount: unreadCount,
                    onNotifications: onNotifications
                )

                HomeBackgroundControls(
                    selectedBackgroundItem: $selectedBackgroundItem,
                    canResetBackground: canResetBackground,
                    onResetBackground: onResetBackground
                )
                .padding(.horizontal, HiveSpacing.lg)
                .padding(.top, HiveSpacing.sm)

                Spacer()

                VStack(alignment: .leading, spacing: HiveSpacing.md) {
                    HiveMemberStack(names: memberNames, size: 30, style: .photo)

                    VStack(alignment: .leading, spacing: HiveSpacing.sm) {
                        Text(greeting)
                        Text("\(firstName).")
                    }
                    .font(HiveFont.heroGreeting)
                    .foregroundStyle(HiveColor.photoTextPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.74)
                    .frame(maxWidth: 250, alignment: .leading)

                    Text(subtitle)
                        .font(HiveFont.bodyRegular)
                        .foregroundStyle(HiveColor.photoTextSecondary)
                        .lineSpacing(3)
                        .frame(maxWidth: 260, alignment: .leading)
                }
                .padding(.horizontal, HiveSpacing.lg)
                .padding(.bottom, HiveSpacing.xl)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: HiveSpacing.sm
                ) {
                    HiveStatusChip(
                        title: "Tasks",
                        value: taskValue,
                        systemImage: "checkmark.circle.fill",
                        tint: HiveColor.sand,
                        action: onTasks
                    )

                    HiveStatusChip(
                        title: "Expenses",
                        value: expenseValue,
                        systemImage: "creditcard.fill",
                        tint: HiveColor.softTeal,
                        action: onExpenses
                    )

                    HiveStatusChip(
                        title: plan.title,
                        value: plan.value,
                        systemImage: plan.icon,
                        tint: HiveColor.coral,
                        action: onPlan
                    )
                    .gridCellColumns(2)
                }
                .padding(.horizontal, HiveSpacing.md)
                .padding(.bottom, HiveSpacing.md)
            }
        }
    }
}

private struct HomeBackgroundControls: View {
    @Binding var selectedBackgroundItem: PhotosPickerItem?
    let canResetBackground: Bool
    let onResetBackground: () -> Void

    var body: some View {
        HStack(spacing: HiveSpacing.sm) {
            Spacer()

            PhotosPicker(
                selection: $selectedBackgroundItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Background", systemImage: "photo.on.rectangle.angled")
                    .font(HiveFont.label)
                    .foregroundStyle(HiveColor.primaryLightText)
                    .labelStyle(.iconOnly)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.30))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }
            }
            .accessibilityLabel("Choose Home background")

            if canResetBackground {
                Button(action: onResetBackground) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HiveColor.primaryLightText)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.30))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Restore default Home background")
            }
        }
    }
}

private struct HomeHeroChrome: View {
    let colonyName: String
    let firstName: String
    let unreadCount: Int
    let onNotifications: () -> Void

    var body: some View {
        HStack(spacing: HiveSpacing.md) {
            HStack(spacing: HiveSpacing.sm) {
                HiveLogoMark(size: 28, shadowOpacity: 0.04)
                Text("HiveSpace")
                    .font(HiveFont.body(17, weight: .semibold))
                    .foregroundStyle(HiveColor.photoTextPrimary)
            }
            .accessibilityLabel("HiveSpace")

            Spacer()

            Text(colonyName)
                .font(HiveFont.label)
                .foregroundStyle(HiveColor.secondaryLightText)
                .lineLimit(1)

            Button(action: onNotifications) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HiveColor.primaryLightText)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.28))
                        .clipShape(Circle())

                    if unreadCount > 0 {
                        Circle()
                            .fill(HiveColor.coral)
                            .frame(width: 8, height: 8)
                            .offset(x: -1, y: 1)
                    }
                }
            }
            .accessibilityLabel(unreadCount > 0 ? "\(unreadCount) unread notifications" : "Notifications")

            HiveAvatar(name: firstName, size: 36, style: .photo)
        }
        .padding(.horizontal, HiveSpacing.lg)
        .padding(.top, HiveSpacing.lg)
    }
}

private struct HouseholdSnapshotCard: View {
    let score: Int
    let grade: String
    let summary: String
    let values: [Double]
    let onOpenHouse: () -> Void

    var body: some View {
        Button(action: onOpenHouse) {
            VStack(alignment: .leading, spacing: HiveSpacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                        Text("House Snapshot")
                            .font(HiveFont.label)
                            .tracking(1.2)
                            .foregroundStyle(HiveColor.secondaryLightText)
                        Text("\(score)%")
                            .font(HiveFont.metricLarge)
                            .foregroundStyle(HiveColor.primaryLightText)
                        Text(summary)
                            .font(HiveFont.caption)
                            .foregroundStyle(HiveColor.secondaryLightText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: HiveSpacing.md) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(HiveColor.secondaryLightText)
                        HiveMetricSparkline(values: values, tint: HiveColor.livingAccent)
                    }
                }

                HStack(spacing: HiveSpacing.sm) {
                    Text(grade)
                        .font(HiveFont.captionMedium)
                        .foregroundStyle(HiveColor.primaryLightText)
                        .padding(.horizontal, HiveSpacing.md)
                        .padding(.vertical, HiveSpacing.xs)
                        .background(HiveColor.livingAccent.opacity(0.20))
                        .clipShape(RoundedRectangle(cornerRadius: HiveRadius.sm, style: .continuous))

                    Text("Tasks, finances, activity, and chores")
                        .font(HiveFont.smallDetail)
                        .foregroundStyle(HiveColor.secondaryLightText)
                        .lineLimit(1)
                }
            }
            .padding(HiveSpacing.lg)
            .background(
                LinearGradient(
                    colors: [HiveColor.darkElevatedSurface, HiveColor.darkInsetSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HiveRadius.lg, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HomeActivitySection: View {
    let events: [ActivityEvent]
    let latestMessage: HomeMessagePreview?
    let labelForEvent: (ActivityEvent) -> String
    let tintForEvent: (ActivityEvent) -> Color

    var body: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.md) {
            HiveSectionHeader(title: "Around the Home")

            VStack(spacing: 0) {
                if let latestMessage {
                    HiveActivityRow(
                        actorName: latestMessage.senderName,
                        message: "\(latestMessage.senderName): \(latestMessage.body)",
                        timestamp: latestMessage.sentAt,
                        tint: HiveColor.livingAccent
                    )
                }

                ForEach(events) { event in
                    if latestMessage != nil || event.id != events.first?.id {
                        Divider()
                            .overlay(HiveColor.borderFallback)
                    }

                    HiveActivityRow(
                        actorName: event.actorName,
                        message: labelForEvent(event),
                        timestamp: event.createdAt,
                        tint: tintForEvent(event)
                    )
                }
            }
            .padding(.horizontal, HiveSpacing.md)
            .padding(.vertical, HiveSpacing.xs)
            .background(HiveColor.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous)
                    .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
            }
        }
    }
}

private struct HomeTaskPreviewSection: View {
    let tasks: [HSTask]
    let memberName: (UUID) -> String
    let onOpenTasks: () -> Void
    let onToggleTask: (HSTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.md) {
            HiveSectionHeader(title: "What Matters Today", action: "Tasks", onAction: onOpenTasks)

            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    HiveTaskRow(
                        title: task.title,
                        subtitle: subtitle(for: task),
                        statusColor: statusColor(for: task),
                        statusLabel: statusLabel(for: task),
                        isCompleted: task.status == .done
                    ) {
                        onToggleTask(task)
                    }

                    if index < tasks.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, HiveSpacing.md)
            .padding(.vertical, HiveSpacing.xs)
            .background(HiveColor.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous)
                    .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
            }
        }
    }

    private func subtitle(for task: HSTask) -> String {
        var parts: [String] = []
        if let dueDate = task.dueDate {
            if dueDate < .now && task.status != .done {
                parts.append("Overdue")
            } else if Calendar.current.isDateInToday(dueDate) {
                parts.append("Due today")
            } else if Calendar.current.isDateInTomorrow(dueDate) {
                parts.append("Due tomorrow")
            } else {
                parts.append(dueDate.formatted(.dateTime.weekday(.wide)))
            }
        }

        if let assignee = task.assignedToIDs.first {
            parts.append(memberName(assignee))
        }

        return parts.joined(separator: " · ")
    }

    private func statusColor(for task: HSTask) -> Color {
        if let dueDate = task.dueDate, dueDate < .now, task.status != .done {
            return HiveColor.attentionAccent
        }

        if let dueDate = task.dueDate, Calendar.current.isDateInToday(dueDate) {
            return HiveColor.honey
        }

        return HiveColor.textSecondaryFallback
    }

    private func statusLabel(for task: HSTask) -> String? {
        if let dueDate = task.dueDate, dueDate < .now, task.status != .done {
            return "Overdue"
        }

        return nil
    }
}

#Preview {
    NavigationStack {
        HomeView(selectedTab: .constant(.home))
            .environmentObject(HiveSpaceStore.sample)
    }
}
