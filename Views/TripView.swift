import SwiftUI

struct TripView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var selectedTripTab = 0
    @State private var showingCreateTrip = false
    @State private var showingAddPacking = false
    @State private var showingAddEvent = false
    @State private var showingAddPoll = false
    @State private var selectedDay: TripItineraryDay?

    var body: some View {
        Group {
            if let trip = store.activeTrip {
                HiveScreen {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                HivePageHeader(
                                    eyebrow: "Trip",
                                    title: trip.title,
                                    subtitle: trip.location
                                )

                                ColonySwitcherButton()
                            }

                            tripHeroCard(trip)

                            Picker("Trip", selection: $selectedTripTab) {
                                Text("Itinerary").tag(0)
                                Text("Split").tag(1)
                                Text("Packing").tag(2)
                                Text("Polls").tag(3)
                            }
                            .pickerStyle(.segmented)

                            switch selectedTripTab {
                            case 0:
                                itineraryView(trip)
                            case 1:
                                splitView(trip)
                            case 2:
                                packingView(trip)
                            default:
                                pollsView(trip)
                            }
                        }
                        .padding(24)
                        .padding(.bottom, 120)
                    }
                }
            } else {
                HiveScreen {
                    VStack(spacing: 20) {
                        HiveEmptyState(
                            title: "No trip yet",
                            message: "Plan your next adventure with your colony.",
                            systemImage: "suitcase.rolling.fill"
                        )

                        Button("Create Trip") {
                            showingCreateTrip = true
                        }
                        .buttonStyle(HivePrimaryButtonStyle())
                    }
                    .padding(24)
                    Spacer()
                }
            }
        }
        .navigationTitle("Trips")
        .sheet(isPresented: $showingCreateTrip) {
            CreateTripSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAddPacking) {
            if let trip = store.activeTrip {
                AddPackingItemSheet(trip: trip)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            if let trip = store.activeTrip, let day = selectedDay {
                AddItineraryEventSheet(trip: trip, day: day)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showingAddPoll) {
            if let trip = store.activeTrip {
                AddTripPollSheet(trip: trip)
                    .environmentObject(store)
            }
        }
    }

    private func tripHeroCard(_ trip: HiveTrip) -> some View {
        HiveCard {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ColonyBadge(colonyName: trip.title, size: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Weekend Plan")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.4)
                                .foregroundStyle(HiveTheme.textSecondary)
                            Text(trip.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Text(trip.location)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                tripStatCard(
                    label: "Dates",
                    value: tripDateRange(trip),
                    accent: HiveTheme.pink
                )
                tripStatCard(
                    label: "Stops",
                    value: "\(trip.itineraryDays.flatMap(\.events).count)",
                    accent: HiveTheme.purple
                )
                tripStatCard(
                    label: "Packed",
                    value: "\(trip.packingItems.filter(\.isPacked).count)/\(trip.packingItems.count)",
                    accent: HiveTheme.green
                )
            }
        }
    }

    private func itineraryView(_ trip: HiveTrip) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if trip.itineraryDays.isEmpty {
                HiveEmptyState(
                    title: "No itinerary",
                    message: "Create a trip with dates to build your itinerary.",
                    systemImage: "calendar"
                )
            }

            ForEach(trip.itineraryDays) { day in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(day.date.formatted(date: .complete, time: .omitted))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)
                        Spacer()
                        Button {
                            selectedDay = day
                            showingAddEvent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(HiveTheme.pink)
                        }
                    }

                    if day.events.isEmpty {
                        Text("No events for this day yet")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(HiveTheme.textSecondary)
                    }

                    ForEach(day.events) { event in
                        HiveCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(event.title)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Text("\(event.timeLabel) • \(event.location)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                                if let confirmation = event.confirmationNumber {
                                    HStack(spacing: 6) {
                                        Image(systemName: "ticket.fill")
                                            .font(.system(size: 11))
                                        Text("Confirmation: \(confirmation)")
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(HiveTheme.pink)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func splitView(_ trip: HiveTrip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let tripExpenses = store.expenses.filter { $0.colonyID == trip.colonyID }
            let total = tripExpenses.reduce(0) { $0 + $1.amount }

            HiveCard {
                Text("Trip total")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textSecondary)
                Text(store.currency(total))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                Text("Per person: \(store.currency(total / Double(max(store.colony.memberCount, 1))))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(HiveTheme.textSecondary)
            }

            if tripExpenses.isEmpty {
                HiveEmptyState(
                    title: "No trip expenses",
                    message: "Add expenses from the Split tab to track trip costs.",
                    systemImage: "creditcard"
                )
            } else {
                ForEach(tripExpenses) { expense in
                    HiveCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(expense.category.emoji) \(expense.title)")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Text(store.currency(expense.amount))
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                            }
                            Spacer()
                            if expense.isFullySettled {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HiveTheme.green)
                            }
                        }
                    }
                }
            }
        }
    }

    private func packingView(_ trip: HiveTrip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HiveCard {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Packing Progress")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)
                        Text("\(trip.packingItems.filter(\.isPacked).count) of \(trip.packingItems.count) items packed")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(HiveTheme.textSecondary)
                    }
                    Spacer()
                    Button {
                        showingAddPacking = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(HiveTheme.pink)
                    }
                }
                ProgressView(value: Double(trip.packingItems.filter(\.isPacked).count), total: max(1, Double(trip.packingItems.count)))
                    .tint(HiveTheme.pink)
            }

            let grouped = Dictionary(grouping: trip.packingItems, by: \.category)
            ForEach(PackingCategory.allCases, id: \.self) { category in
                if let items = grouped[category], !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(HiveTheme.textSecondary)

                        ForEach(items) { item in
                            HiveCard {
                                HStack(spacing: 12) {
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            store.togglePacked(item, in: trip)
                                        }
                                    } label: {
                                        Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(item.isPacked ? HiveTheme.green : HiveTheme.textSecondary)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(item.isPacked ? HiveTheme.textSecondary : HiveTheme.textPrimary)
                                            .strikethrough(item.isPacked)
                                        Text(item.isShared ? "Shared" : "Personal")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundStyle(HiveTheme.textSecondary)
                                    }

                                    Spacer()

                                    Button {
                                        store.removePackingItem(item, from: trip)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundStyle(HiveTheme.red.opacity(0.6))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func pollsView(_ trip: HiveTrip) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Polls")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                Spacer()
                Button {
                    showingAddPoll = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(HiveTheme.pink)
                }
            }

            if trip.polls.isEmpty {
                HiveEmptyState(
                    title: "No polls yet",
                    message: "Create a poll to decide on plans together.",
                    systemImage: "chart.bar.fill"
                )
            }

            ForEach(trip.polls) { poll in
                HiveCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(poll.question)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)

                        let totalVotes = poll.options.reduce(0) { $0 + $1.voteCount }

                        ForEach(poll.options) { option in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    store.vote(on: option, in: poll, trip: trip)
                                }
                            } label: {
                                HStack {
                                    Text(option.title)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                    Spacer()
                                    Text("\(option.voteCount)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(HiveTheme.pink)
                                }
                                .padding(14)
                                .background {
                                    GeometryReader { proxy in
                                        let ratio = totalVotes > 0 ? Double(option.voteCount) / Double(totalVotes) : 0
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(HiveTheme.pink.opacity(0.08))
                                            .frame(width: proxy.size.width * ratio)
                                    }
                                }
                                .background(HiveTheme.surface)
                                .foregroundStyle(HiveTheme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(HiveTheme.border, lineWidth: 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func tripStatCard(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(HiveTheme.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func tripDateRange(_ trip: HiveTrip) -> String {
        let start = trip.startDate.formatted(.dateTime.month(.abbreviated).day())
        let end = trip.endDate.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) - \(end)"
    }
}

// MARK: - Create Trip Sheet

struct CreateTripSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var location = ""
    @State private var startDate = Date().addingTimeInterval(60 * 60 * 24 * 7)
    @State private var endDate = Date().addingTimeInterval(60 * 60 * 24 * 10)

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip name", text: $title)
                    TextField("Location", text: $location)
                }
                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.createTrip(title: title, location: location, startDate: startDate, endDate: endDate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Packing Item Sheet

struct AddPackingItemSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    let trip: HiveTrip
    @State private var title = ""
    @State private var category: PackingCategory = .essentials
    @State private var isShared = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $title)
                Picker("Category", selection: $category) {
                    ForEach(PackingCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                Toggle("Shared item", isOn: $isShared)
            }
            .navigationTitle("Add Packing Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addPackingItem(title, category: category, isShared: isShared, to: trip)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Itinerary Event Sheet

struct AddItineraryEventSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    let trip: HiveTrip
    let day: TripItineraryDay
    @State private var title = ""
    @State private var timeLabel = ""
    @State private var location = ""
    @State private var confirmation = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Event name", text: $title)
                    TextField("Time (e.g. 4:00 PM)", text: $timeLabel)
                    TextField("Location", text: $location)
                }
                Section("Optional") {
                    TextField("Confirmation number", text: $confirmation)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addItineraryEvent(
                            to: trip,
                            day: day,
                            title: title,
                            timeLabel: timeLabel,
                            location: location,
                            confirmation: confirmation.isEmpty ? nil : confirmation
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

// MARK: - Add Trip Poll Sheet

struct AddTripPollSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    let trip: HiveTrip
    @State private var question = ""
    @State private var options = ["", ""]

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("What should we decide?", text: $question)
                }
                Section("Options") {
                    ForEach(options.indices, id: \.self) { index in
                        TextField("Option \(index + 1)", text: $options[index])
                    }
                    Button("Add Option") {
                        options.append("")
                    }
                }
            }
            .navigationTitle("New Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let validOptions = options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        store.addTripPoll(to: trip, question: question, options: validOptions)
                        dismiss()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || options.filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).count < 2)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TripView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
