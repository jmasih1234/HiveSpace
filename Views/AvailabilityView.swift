import SwiftUI

struct AvailabilityView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var selectedGroupSlotID: UUID?
    @State private var toggledDuringDrag: Set<UUID> = []
    @State private var showingCreatePoll = false

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: "Schedule",
                        title: store.activeAvailabilityPoll?.title ?? "Availability",
                        subtitle: "Time zone: \(store.activeAvailabilityPoll?.timezoneIdentifier ?? TimeZone.current.identifier)"
                    ) {
                        HStack(spacing: 10) {
                            Button {
                                showingCreatePoll = true
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(HiveTheme.pink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            ColonySwitcherButton()
                        }
                    }

                    if let poll = store.activeAvailabilityPoll {
                        summaryCard(poll)

                        availabilityPanel(title: "Your Availability") {
                            personalTimeline(poll)
                        }

                        availabilityPanel(title: "Group Matches") {
                            groupMatchBoard(poll)
                        }

                        if let selectedSlot = selectedGroupSlot(in: poll) {
                            availableMembersCard(slot: selectedSlot, poll: poll)
                        }
                    } else {
                        HiveEmptyState(
                            title: "No scheduling poll",
                            message: "Create an availability poll for this colony to coordinate meeting times.",
                            systemImage: "calendar.badge.clock"
                        )

                        Button("Create Poll") {
                            showingCreatePoll = true
                        }
                        .buttonStyle(HivePrimaryButtonStyle())
                    }
                }
                .padding(24)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Availability")
        .sheet(isPresented: $showingCreatePoll) {
            CreateAvailabilityPollSheet()
                .environmentObject(store)
        }
    }

    private func summaryCard(_ poll: AvailabilityPoll) -> some View {
        HiveCard {
            HStack(spacing: 12) {
                statBlock(title: "Days", value: "\(poll.days.count)")
                statBlock(title: "Responses", value: "\(poll.responses.count)/\(poll.participantCount)")
                statBlock(title: "Best", value: bestAvailabilityText(poll))
            }
        }
    }

    private func availabilityPanel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HiveCard {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func personalTimeline(_ poll: AvailabilityPoll) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(poll.days) { day in
                VStack(alignment: .leading, spacing: 10) {
                    dayHeader(day)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 8)], spacing: 8) {
                        ForEach(slots(for: day, in: poll)) { slot in
                            personalSlotButton(slot, poll: poll)
                        }
                    }
                }
                .padding(14)
                .background(HiveTheme.surfaceSoft.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func personalSlotButton(_ slot: AvailabilitySlot, poll: AvailabilityPoll) -> some View {
        let isAvailable = currentUserResponse(in: poll)?.availableSlotIDs.contains(slot.id) == true

        return Button {
            store.toggleAvailability(for: slot, in: poll)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isAvailable ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                Text(slot.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(isAvailable ? AnyShapeStyle(HiveTheme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.72)))
            .foregroundStyle(isAvailable ? .white : HiveTheme.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isAvailable ? Color.white.opacity(0.2) : HiveTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !toggledDuringDrag.contains(slot.id) else {
                        return
                    }
                    toggledDuringDrag.insert(slot.id)
                    store.toggleAvailability(for: slot, in: poll)
                }
                .onEnded { _ in
                    toggledDuringDrag.removeAll()
                }
        )
    }

    private func groupMatchBoard(_ poll: AvailabilityPoll) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(poll.days) { day in
                VStack(alignment: .leading, spacing: 10) {
                    dayHeader(day)

                    VStack(spacing: 8) {
                        ForEach(slots(for: day, in: poll)) { slot in
                            groupSlotRow(slot, poll: poll)
                        }
                    }
                }
                .padding(14)
                .background(HiveTheme.surfaceSoft.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func groupSlotRow(_ slot: AvailabilitySlot, poll: AvailabilityPoll) -> some View {
        let count = store.availabilityCount(for: slot, in: poll)
        let ratio = poll.participantCount == 0 ? 0 : Double(count) / Double(poll.participantCount)
        let isSelected = selectedGroupSlotID == slot.id

        return Button {
            selectedGroupSlotID = slot.id
        } label: {
            HStack(spacing: 10) {
                Text(slot.label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                    .frame(width: 58, alignment: .leading)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.78))

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(groupFill(for: ratio))
                            .frame(width: max(8, proxy.size.width * ratio))
                    }
                }
                .frame(height: 18)

                Text("\(count)/\(poll.participantCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(count == poll.participantCount ? HiveTheme.pink : HiveTheme.textSecondary)
                    .frame(width: 34, alignment: .trailing)
            }
            .padding(10)
            .background(isSelected ? Color.white.opacity(0.86) : Color.white.opacity(0.46))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? HiveTheme.pink.opacity(0.35) : HiveTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func dayHeader(_ day: AvailabilityDay) -> some View {
        HStack {
            Text(day.weekdayLabel)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
            Text(day.shortLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HiveTheme.textSecondary)
            Spacer()
        }
    }

    private func slots(for day: AvailabilityDay, in poll: AvailabilityPoll) -> [AvailabilitySlot] {
        poll.slots
            .filter { $0.dayID == day.id }
            .sorted { $0.hour < $1.hour }
    }

    private func groupFill(for ratio: Double) -> AnyShapeStyle {
        if ratio >= 1 {
            return AnyShapeStyle(HiveTheme.accentGradient)
        }

        return AnyShapeStyle(HiveTheme.purple.opacity(0.14 + (ratio * 0.5)))
    }

    private func availableMembersCard(slot: AvailabilitySlot, poll: AvailabilityPoll) -> some View {
        let availableNames = poll.responses
            .filter { $0.availableSlotIDs.contains(slot.id) }
            .map { store.memberName(for: $0.userID) }

        return HiveCard {
            Text("\(slot.label) availability")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
            Text(availableNames.isEmpty ? "No one is available." : availableNames.joined(separator: ", "))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(HiveTheme.textSecondary)
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(HiveTheme.textSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(HiveTheme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func currentUserResponse(in poll: AvailabilityPoll) -> AvailabilityResponse? {
        poll.responses.first(where: { $0.userID == store.currentUser.id })
    }

    private func selectedGroupSlot(in poll: AvailabilityPoll) -> AvailabilitySlot? {
        guard let selectedGroupSlotID else {
            return nil
        }
        return poll.slots.first(where: { $0.id == selectedGroupSlotID })
    }

    private func bestAvailabilityText(_ poll: AvailabilityPoll) -> String {
        guard let bestSlot = poll.slots.max(by: {
            store.availabilityCount(for: $0, in: poll) < store.availabilityCount(for: $1, in: poll)
        }) else {
            return "-"
        }

        return "\(store.availabilityCount(for: bestSlot, in: poll))/\(poll.participantCount)"
    }
}

// MARK: - Create Availability Poll Sheet

struct CreateAvailabilityPollSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var startDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var numberOfDays = 5
    @State private var startHour = 8
    @State private var endHour = 17

    var body: some View {
        NavigationStack {
            Form {
                Section("Poll Info") {
                    TextField("Meeting title (e.g. Team Sync)", text: $title)
                }
                Section("Date Range") {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                    Stepper("Days: \(numberOfDays)", value: $numberOfDays, in: 1...14)
                }
                Section("Time Range") {
                    Stepper("Start hour: \(startHour):00", value: $startHour, in: 0...23)
                    Stepper("End hour: \(endHour):00", value: $endHour, in: (startHour + 1)...23)
                }
                Section("Preview") {
                    Text("\(numberOfDays) days, \(endHour - startHour + 1) slots per day")
                        .foregroundStyle(HiveTheme.textSecondary)
                    Text("All \(store.colony.members.count) colony members will be invited")
                        .foregroundStyle(HiveTheme.textSecondary)
                }
            }
            .navigationTitle("New Availability Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.createAvailabilityPoll(
                            title: title,
                            startDate: startDate,
                            numberOfDays: numberOfDays,
                            startHour: startHour,
                            endHour: endHour
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AvailabilityView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
