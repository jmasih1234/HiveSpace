import SwiftUI

// MARK: - App Loading State

enum AppLoadingState: Equatable {
    case idle
    case loading(String)
    case error(String)
}

@MainActor
final class HiveSpaceStore: ObservableObject {
    @Published var account: HiveSpaceAccount
    @Published var allColonies: [Colony]
    @Published var currentUser: HSUser
    @Published var colony: Colony
    @Published var tasks: [HSTask]
    @Published var expenses: [Expense]
    @Published var activityEvents: [ActivityEvent]
    @Published var healthScore: HiveHealthScore
    @Published var choreWheels: [ChoreWheel]
    @Published var nudges: [Nudge]
    @Published var joinRequests: [ColonyJoinRequest]
    @Published var settlementRequests: [SettlementRequest]
    @Published var eventSplits: [EventSplit]
    @Published var semesterSnapshots: [SemesterSnapshot]
    @Published var messageChannels: [MessageChannel]
    @Published var messages: [HSMessage]
    @Published var directThreads: [DirectMessageThread]
    @Published var callSessions: [CallSession]
    @Published var callParticipants: [CallParticipantState]
    @Published var trips: [HiveTrip]
    @Published var availabilityPolls: [AvailabilityPoll]
    @Published var teamWorkspace: TeamWorkspace

    // Loading & error state
    @Published var loadingState: AppLoadingState = .idle
    @Published var toastMessage: String?
    @Published var isOfflineMode: Bool = true

    // Auto-save debounce
    private var saveTask: Task<Void, Never>?

    init(
        account: HiveSpaceAccount,
        allColonies: [Colony],
        currentUser: HSUser,
        colony: Colony,
        tasks: [HSTask],
        expenses: [Expense],
        activityEvents: [ActivityEvent],
        healthScore: HiveHealthScore,
        choreWheels: [ChoreWheel],
        nudges: [Nudge],
        joinRequests: [ColonyJoinRequest],
        settlementRequests: [SettlementRequest],
        eventSplits: [EventSplit],
        semesterSnapshots: [SemesterSnapshot],
        messageChannels: [MessageChannel],
        messages: [HSMessage],
        directThreads: [DirectMessageThread],
        callSessions: [CallSession],
        callParticipants: [CallParticipantState],
        trips: [HiveTrip],
        availabilityPolls: [AvailabilityPoll],
        teamWorkspace: TeamWorkspace
    ) {
        self.account = account
        self.allColonies = allColonies
        self.currentUser = currentUser
        self.colony = colony
        self.tasks = tasks
        self.expenses = expenses
        self.activityEvents = activityEvents
        self.healthScore = healthScore
        self.choreWheels = choreWheels
        self.nudges = nudges
        self.joinRequests = joinRequests
        self.settlementRequests = settlementRequests
        self.eventSplits = eventSplits
        self.semesterSnapshots = semesterSnapshots
        self.messageChannels = messageChannels
        self.messages = messages
        self.directThreads = directThreads
        self.callSessions = callSessions
        self.callParticipants = callParticipants
        self.trips = trips
        self.availabilityPolls = availabilityPolls
        self.teamWorkspace = teamWorkspace
    }

    // MARK: - Persistence

    /// Save current state to disk (debounced).
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self?.saveNow()
        }
    }

    /// Immediately persist all data to disk.
    func saveNow() async {
        let snapshot = StoreSnapshot(
            account: account,
            allColonies: allColonies,
            currentUser: currentUser,
            currentColonyID: colony.id,
            tasks: tasks,
            expenses: expenses,
            activityEvents: activityEvents,
            healthScore: healthScore,
            choreWheels: choreWheels,
            nudges: nudges,
            joinRequests: joinRequests,
            settlementRequests: settlementRequests,
            eventSplits: eventSplits,
            semesterSnapshots: semesterSnapshots,
            messageChannels: messageChannels,
            messages: messages,
            directThreads: directThreads,
            callSessions: callSessions,
            trips: trips,
            availabilityPolls: availabilityPolls,
            teamWorkspace: teamWorkspace
        )
        await PersistenceService.shared.saveSnapshot(snapshot)
    }

    /// Load data from disk. Returns true if data was found.
    static func loadFromDisk() async -> HiveSpaceStore? {
        guard let snapshot = await PersistenceService.shared.loadSnapshot() else {
            return nil
        }
        let colony = snapshot.allColonies.first(where: { $0.id == snapshot.currentColonyID }) ?? snapshot.allColonies.first!
        return HiveSpaceStore(
            account: snapshot.account,
            allColonies: snapshot.allColonies,
            currentUser: snapshot.currentUser,
            colony: colony,
            tasks: snapshot.tasks,
            expenses: snapshot.expenses,
            activityEvents: snapshot.activityEvents,
            healthScore: snapshot.healthScore,
            choreWheels: snapshot.choreWheels,
            nudges: snapshot.nudges,
            joinRequests: snapshot.joinRequests,
            settlementRequests: snapshot.settlementRequests,
            eventSplits: snapshot.eventSplits,
            semesterSnapshots: snapshot.semesterSnapshots,
            messageChannels: snapshot.messageChannels,
            messages: snapshot.messages,
            directThreads: snapshot.directThreads,
            callSessions: snapshot.callSessions,
            callParticipants: [],
            trips: snapshot.trips,
            availabilityPolls: snapshot.availabilityPolls,
            teamWorkspace: snapshot.teamWorkspace
        )
    }

    /// Show a brief toast message.
    func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    /// Attempt to sync data with the API.
    func syncWithServer() async {
        guard !isOfflineMode else { return }
        loadingState = .loading("Syncing...")

        do {
            // Fetch fresh colony data
            let colonies: [Colony] = try await NetworkService.shared.request(
                endpoint: .colonies,
                body: nil as String?,
                queryItems: nil
            )
            allColonies = colonies
            if let current = colonies.first(where: { $0.id == colony.id }) {
                colony = current
            }

            // Fetch tasks
            let freshTasks: [HSTask] = try await NetworkService.shared.request(
                endpoint: .tasks(colonyID: colony.id),
                body: nil as String?,
                queryItems: nil
            )
            tasks = freshTasks

            // Fetch expenses
            let freshExpenses: [Expense] = try await NetworkService.shared.request(
                endpoint: .expenses(colonyID: colony.id),
                body: nil as String?,
                queryItems: nil
            )
            expenses = freshExpenses

            loadingState = .idle
            scheduleSave()
        } catch is NetworkError {
            loadingState = .idle
            isOfflineMode = true
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }

    var openTasks: [HSTask] {
        tasks.filter { $0.status != .done }
    }

    var overdueTasks: [HSTask] {
        tasks.filter {
            $0.status != .done && ($0.dueDate ?? .distantFuture) < Date()
        }
    }

    var unsettledExpenses: [Expense] {
        expenses.filter { !$0.isFullySettled }
    }

    var activeChannels: [MessageChannel] {
        messageChannels.filter { $0.colonyID == colony.id }
    }

    var activeTrip: HiveTrip? {
        trips.first(where: { $0.colonyID == colony.id })
    }

    var activeAvailabilityPoll: AvailabilityPoll? {
        availabilityPolls.first(where: { $0.colonyID == colony.id })
    }

    var activeCallSession: CallSession? {
        callSessions.first(where: { $0.colonyID == colony.id && ($0.state == .active || $0.state == .incoming || $0.state == .scheduled) })
    }

    var outstandingBalanceTotal: Double {
        unsettledExpenses.reduce(0) { $0 + $1.totalOwed }
    }

    var balanceSummaries: [BalanceSummary] {
        var owed: [UUID: Double] = [:]
        var owedToThem: [UUID: Double] = [:]

        for expense in expenses {
            for split in expense.splits where split.userID != expense.paidByID {
                if split.isSettled {
                    continue
                }
                owed[split.userID, default: 0] += split.amount
                owedToThem[expense.paidByID, default: 0] += split.amount
            }
        }

        return colony.members.map { member in
            BalanceSummary(
                id: member.id,
                displayName: member.displayName,
                avatarURL: member.avatarURL,
                totalOwed: owed[member.id, default: 0],
                totalOwedToThem: owedToThem[member.id, default: 0]
            )
        }
        .sorted { abs($0.netBalance) > abs($1.netBalance) }
    }

    func memberName(for id: UUID) -> String {
        colony.members.first(where: { $0.id == id })?.displayName ?? "Someone"
    }

    func currency(_ amount: Double) -> String {
        amount.formatted(.currency(code: colony.settings.currencyCode))
    }

    func completeTask(_ task: HSTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        tasks[index].status = .done
        tasks[index].completedAt = Date()
        tasks[index].completedByID = currentUser.id
        addActivity(type: .taskCompleted, referenceName: tasks[index].title)
        recalculateHiveHealth()
    }

    func reopenTask(_ task: HSTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        tasks[index].status = .todo
        tasks[index].completedAt = nil
        tasks[index].completedByID = nil
        recalculateHiveHealth()
    }

    func toggleTaskCompletion(_ task: HSTask) {
        if task.status == .done {
            reopenTask(task)
        } else {
            completeTask(task)
        }
    }

    func rotateChore(_ chore: ChoreWheel) {
        guard let index = choreWheels.firstIndex(where: { $0.id == chore.id }) else {
            return
        }

        var updated = choreWheels[index]
        updated.rotate()
        updated.nextRotationAt = nextDate(for: updated.rotationFrequency)
        choreWheels[index] = updated

        addActivity(
            type: .choreRotated,
            referenceName: updated.choreName,
            targetName: memberName(for: updated.currentAssigneeID)
        )
        recalculateHiveHealth()
    }

    func sendNudge(for task: HSTask) {
        guard let recipientID = task.assignedToIDs.first else {
            return
        }

        nudges.insert(
            Nudge(
                id: UUID(),
                colonyID: colony.id,
                senderID: currentUser.id,
                recipientID: recipientID,
                referenceType: .task,
                referenceID: task.id,
                message: "Gentle reminder to wrap up \(task.title).",
                sentAt: Date(),
                seenAt: nil
            ),
            at: 0
        )
        addActivity(type: .nudgeSent, referenceName: task.title)
    }

    func settleExpense(_ expense: Expense, method: SettlementMethod = .inApp) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }

        expenses[index].settledAt = Date()
        expenses[index].splits = expenses[index].splits.map { split in
            var updated = split
            if updated.userID != expenses[index].paidByID {
                updated.isSettled = true
                updated.settledAt = Date()
                updated.settledVia = method
            }
            return updated
        }

        settlementRequests.insert(
            SettlementRequest(
                id: UUID(),
                colonyID: colony.id,
                fromUserID: currentUser.id,
                toUserID: expenses[index].paidByID,
                amount: expense.totalOwed,
                method: method,
                status: .confirmed,
                expenseIDs: [expense.id],
                createdAt: Date(),
                confirmedAt: Date()
            ),
            at: 0
        )

        addActivity(type: .expenseSettled, referenceName: expenses[index].title)
        recalculateHiveHealth()
    }

    func addReaction(_ emoji: String, to expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }

        expenses[index].reactions.append(
            ExpenseReaction(
                id: UUID(),
                userID: currentUser.id,
                emoji: emoji,
                reactedAt: Date()
            )
        )
    }

    func switchColony(to colony: Colony) {
        self.colony = colony
        if let preferredIndex = account.hive.colonyIDs.firstIndex(of: colony.id) {
            account.hive.preferredColonyID = account.hive.colonyIDs[preferredIndex]
        }
        didMutate()
    }

    func createColony(named name: String, type: ColonyType) {
        let newColony = Colony(
            id: UUID(),
            name: name,
            emoji: "✦",
            description: "New colony",
            joinCode: String(UUID().uuidString.prefix(6)).uppercased(),
            createdByID: currentUser.id,
            createdAt: .now,
            type: type,
            members: [
                ColonyMember(
                    id: currentUser.id,
                    displayName: currentUser.displayName,
                    username: currentUser.username,
                    avatarURL: currentUser.avatarURL,
                    role: .queen,
                    status: .active,
                    joinedAt: .now,
                    lastActiveAt: .now
                )
            ],
            settings: colony.settings
        )

        allColonies.append(newColony)
        account.hive.colonyIDs.append(newColony.id)
        switchColony(to: newColony)
    }

    func sendMessage(_ body: String, in channel: MessageChannel) {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        messages.append(
            HSMessage(
                id: UUID(),
                channelID: channel.id,
                senderID: currentUser.id,
                senderName: currentUser.displayName,
                body: body,
                sentAt: .now,
                attachments: [],
                reactions: [],
                replyToMessageID: nil
            )
        )

        if let channelIndex = messageChannels.firstIndex(where: { $0.id == channel.id }) {
            messageChannels[channelIndex].unreadCount = 0
        }
        didMutate()
    }

    func react(to message: HSMessage, emoji: String) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }

        messages[index].reactions.append(
            MessageReaction(id: UUID(), userID: currentUser.id, emoji: emoji)
        )
        didMutate()
    }

    func scheduleCall(title: String, type: CallType, date: Date) {
        callSessions.insert(
            CallSession(
                id: UUID(),
                colonyID: colony.id,
                title: title,
                type: type,
                state: .scheduled,
                startedAt: nil,
                scheduledFor: date,
                participantIDs: colony.members.map(\.id)
            ),
            at: 0
        )
    }

    func joinCall(_ call: CallSession) {
        guard let index = callSessions.firstIndex(where: { $0.id == call.id }) else {
            return
        }
        callSessions[index].state = .active
        callSessions[index].startedAt = .now
        didMutate()
    }

    func endCall(_ call: CallSession) {
        guard let index = callSessions.firstIndex(where: { $0.id == call.id }) else {
            return
        }
        callSessions[index].state = .ended
        didMutate()
    }

    func togglePacked(_ item: PackingItem, in trip: HiveTrip) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }),
              let itemIndex = trips[tripIndex].packingItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        trips[tripIndex].packingItems[itemIndex].isPacked.toggle()
        didMutate()
    }

    func vote(on option: TripPollOption, in poll: TripPoll, trip: HiveTrip) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }),
              let pollIndex = trips[tripIndex].polls.firstIndex(where: { $0.id == poll.id }),
              let optionIndex = trips[tripIndex].polls[pollIndex].options.firstIndex(where: { $0.id == option.id }) else {
            return
        }

        trips[tripIndex].polls[pollIndex].options[optionIndex].voteCount += 1
        didMutate()
    }

    func toggleAvailability(for slot: AvailabilitySlot, in poll: AvailabilityPoll) {
        guard let pollIndex = availabilityPolls.firstIndex(where: { $0.id == poll.id }) else {
            return
        }

        if let responseIndex = availabilityPolls[pollIndex].responses.firstIndex(where: { $0.userID == currentUser.id }) {
            if availabilityPolls[pollIndex].responses[responseIndex].availableSlotIDs.contains(slot.id) {
                availabilityPolls[pollIndex].responses[responseIndex].availableSlotIDs.removeAll { $0 == slot.id }
            } else {
                availabilityPolls[pollIndex].responses[responseIndex].availableSlotIDs.append(slot.id)
            }
            availabilityPolls[pollIndex].responses[responseIndex].updatedAt = Date()
        } else {
            availabilityPolls[pollIndex].responses.append(
                AvailabilityResponse(
                    id: UUID(),
                    userID: currentUser.id,
                    availableSlotIDs: [slot.id],
                    updatedAt: Date()
                )
            )
        }
    }

    func availabilityCount(for slot: AvailabilitySlot, in poll: AvailabilityPoll) -> Int {
        poll.responses.filter { $0.availableSlotIDs.contains(slot.id) }.count
    }

    func updateParticipation(_ response: EventResponse, for eventSplit: EventSplit) {
        guard let splitIndex = eventSplits.firstIndex(where: { $0.id == eventSplit.id }) else {
            return
        }

        if let participantIndex = eventSplits[splitIndex].participants.firstIndex(where: { $0.id == currentUser.id }) {
            eventSplits[splitIndex].participants[participantIndex].response = response
            eventSplits[splitIndex].participants[participantIndex].respondedAt = Date()
        }
    }

    func approve(_ request: ColonyJoinRequest) {
        guard let index = joinRequests.firstIndex(where: { $0.id == request.id }) else {
            return
        }

        joinRequests[index].status = .approved
        joinRequests[index].resolvedAt = Date()
        joinRequests[index].resolvedByID = currentUser.id
    }

    func archiveSemester() {
        let snapshot = SemesterSnapshot(
            id: UUID(),
            colonyID: colony.id,
            semesterLabel: semesterLabel(),
            archivedAt: Date(),
            createdByID: currentUser.id,
            totalExpenses: expenses.reduce(0) { $0 + $1.amount },
            tasksCompleted: tasks.filter { $0.status == .done }.count,
            topContributorID: currentUser.id,
            finalHealthScore: healthScore.score
        )

        semesterSnapshots.insert(snapshot, at: 0)
        addActivity(type: .semesterReset, referenceName: snapshot.semesterLabel)
        didMutate()
    }

    // MARK: - Create Task

    func addTask(title: String, description: String?, priority: TaskPriority, assignedToIDs: [UUID], dueDate: Date?, tags: [String]) {
        let task = HSTask(
            id: UUID(),
            colonyID: colony.id,
            title: title,
            description: description,
            status: .todo,
            priority: priority,
            assignedToIDs: assignedToIDs.isEmpty ? [currentUser.id] : assignedToIDs,
            createdByID: currentUser.id,
            createdAt: .now,
            dueDate: dueDate,
            completedAt: nil,
            completedByID: nil,
            linkedExpenseID: nil,
            recurrence: nil,
            tags: tags
        )
        tasks.insert(task, at: 0)
        addActivity(type: .taskCreated, referenceName: title)
        recalculateHiveHealth()
    }

    func deleteTask(_ task: HSTask) {
        tasks.removeAll { $0.id == task.id }
        recalculateHiveHealth()
    }

    func updateTask(_ task: HSTask, title: String, description: String?, priority: TaskPriority, status: TaskStatus, assignedToIDs: [UUID], dueDate: Date?) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].title = title
        tasks[index].description = description
        tasks[index].priority = priority
        tasks[index].status = status
        tasks[index].assignedToIDs = assignedToIDs
        tasks[index].dueDate = dueDate
        if status == .done && tasks[index].completedAt == nil {
            tasks[index].completedAt = .now
            tasks[index].completedByID = currentUser.id
        } else if status != .done {
            tasks[index].completedAt = nil
            tasks[index].completedByID = nil
        }
        recalculateHiveHealth()
    }

    // MARK: - Create Expense

    func addExpense(title: String, amount: Double, category: ExpenseCategory, paidByID: UUID, splitMethod: SplitMethod, notes: String?) {
        let memberCount = Double(colony.members.count)
        let perPerson = amount / memberCount

        let splits = colony.members.map { member in
            ExpenseSplit(
                id: UUID(),
                userID: member.id,
                amount: perPerson,
                percentage: nil,
                isSettled: member.id == paidByID,
                settledAt: member.id == paidByID ? .now : nil,
                settledVia: member.id == paidByID ? .inApp : nil
            )
        }

        let expense = Expense(
            id: UUID(),
            colonyID: colony.id,
            title: title,
            amount: amount,
            currencyCode: colony.settings.currencyCode,
            category: category,
            paidByID: paidByID,
            splits: splits,
            splitMethod: splitMethod,
            createdByID: currentUser.id,
            createdAt: .now,
            settledAt: nil,
            receiptImageURL: nil,
            linkedTaskID: nil,
            isRecurring: false,
            recurrence: nil,
            notes: notes,
            reactions: []
        )
        expenses.insert(expense, at: 0)
        addActivity(type: .expenseAdded, referenceName: title)
        recalculateHiveHealth()
    }

    func settleAllWith(_ userID: UUID, method: SettlementMethod) {
        var settledAmount: Double = 0
        for i in expenses.indices {
            for j in expenses[i].splits.indices {
                let split = expenses[i].splits[j]
                if split.userID == currentUser.id && expenses[i].paidByID == userID && !split.isSettled {
                    expenses[i].splits[j].isSettled = true
                    expenses[i].splits[j].settledAt = .now
                    expenses[i].splits[j].settledVia = method
                    settledAmount += split.amount
                }
                if split.userID == userID && expenses[i].paidByID == currentUser.id && !split.isSettled {
                    expenses[i].splits[j].isSettled = true
                    expenses[i].splits[j].settledAt = .now
                    expenses[i].splits[j].settledVia = method
                    settledAmount += split.amount
                }
            }
            if expenses[i].isFullySettled && expenses[i].settledAt == nil {
                expenses[i].settledAt = .now
            }
        }

        if settledAmount > 0 {
            settlementRequests.insert(
                SettlementRequest(
                    id: UUID(),
                    colonyID: colony.id,
                    fromUserID: currentUser.id,
                    toUserID: userID,
                    amount: settledAmount,
                    method: method,
                    status: .confirmed,
                    expenseIDs: expenses.filter { !$0.isFullySettled }.map(\.id),
                    createdAt: .now,
                    confirmedAt: .now
                ),
                at: 0
            )
            addActivity(type: .expenseSettled, referenceName: memberName(for: userID))
        }
        recalculateHiveHealth()
    }

    // MARK: - Create Trip

    func createTrip(title: String, location: String, startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        var days: [TripItineraryDay] = []
        var current = startDate
        while current <= endDate {
            days.append(TripItineraryDay(id: UUID(), date: current, events: []))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
        }

        let trip = HiveTrip(
            id: UUID(),
            colonyID: colony.id,
            title: title,
            location: location,
            startDate: startDate,
            endDate: endDate,
            itineraryDays: days,
            packingItems: [],
            polls: []
        )
        trips.append(trip)
        didMutate()
    }

    func addPackingItem(_ title: String, category: PackingCategory, isShared: Bool, to trip: HiveTrip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index].packingItems.append(
            PackingItem(id: UUID(), title: title, category: category, isShared: isShared, isPacked: false)
        )
        didMutate()
    }

    func removePackingItem(_ item: PackingItem, from trip: HiveTrip) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[tripIndex].packingItems.removeAll { $0.id == item.id }
        didMutate()
    }

    func addItineraryEvent(to trip: HiveTrip, day: TripItineraryDay, title: String, timeLabel: String, location: String, confirmation: String?) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }),
              let dayIndex = trips[tripIndex].itineraryDays.firstIndex(where: { $0.id == day.id }) else { return }
        trips[tripIndex].itineraryDays[dayIndex].events.append(
            TripItineraryEvent(id: UUID(), title: title, timeLabel: timeLabel, location: location, confirmationNumber: confirmation)
        )
        didMutate()
    }

    func addTripPoll(to trip: HiveTrip, question: String, options: [String]) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index].polls.append(
            TripPoll(
                id: UUID(),
                question: question,
                options: options.map { TripPollOption(id: UUID(), title: $0, voteCount: 0) }
            )
        )
        didMutate()
    }

    // MARK: - Create Availability Poll

    func createAvailabilityPoll(title: String, startDate: Date, numberOfDays: Int, startHour: Int, endHour: Int) {
        let cal = Calendar.current
        let days: [AvailabilityDay] = (0..<numberOfDays).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: startDate) ?? startDate
            return AvailabilityDay(
                id: UUID(),
                date: date,
                shortLabel: date.formatted(.dateTime.month(.abbreviated).day()),
                weekdayLabel: date.formatted(.dateTime.weekday(.abbreviated))
            )
        }
        let slots = days.flatMap { day in
            (startHour...endHour).map { hour in
                AvailabilitySlot(
                    id: UUID(),
                    dayID: day.id,
                    hour: hour,
                    label: DateComponents(calendar: cal, hour: hour)
                        .date?
                        .formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))) ?? "\(hour):00"
                )
            }
        }
        let poll = AvailabilityPoll(
            id: UUID(),
            colonyID: colony.id,
            title: title,
            timezoneIdentifier: TimeZone.current.identifier,
            days: days,
            slots: slots,
            participantIDs: colony.members.map(\.id),
            responses: []
        )
        availabilityPolls.insert(poll, at: 0)
        didMutate()
    }

    // MARK: - Direct Messages

    func sendDirectMessage(_ body: String, to userID: UUID) {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if let threadIndex = directThreads.firstIndex(where: {
            $0.participantIDs.contains(currentUser.id) && $0.participantIDs.contains(userID)
        }) {
            directThreads[threadIndex].lastMessagePreview = body
            directThreads[threadIndex].updatedAt = .now
        } else {
            directThreads.append(
                DirectMessageThread(
                    id: UUID(),
                    participantIDs: [currentUser.id, userID],
                    lastMessagePreview: body,
                    updatedAt: .now
                )
            )
        }
        didMutate()
    }

    // MARK: - Chore Wheel

    func addChoreWheel(name: String, frequency: RecurrenceFrequency) {
        let assignees = colony.members.map(\.id)
        choreWheels.append(
            ChoreWheel(
                id: UUID(),
                colonyID: colony.id,
                choreName: name,
                assignees: assignees,
                currentIndex: 0,
                rotationFrequency: frequency,
                lastRotatedAt: nil,
                nextRotationAt: nextDate(for: frequency)
            )
        )
        didMutate()
    }

    // MARK: - Colony

    func removeMember(_ memberID: UUID) {
        guard let index = colony.members.firstIndex(where: { $0.id == memberID }) else { return }
        colony.members[index].status = .removed
        didMutate()
    }

    func updateColonySettings(_ settings: ColonySettings) {
        colony.settings = settings
        didMutate()
    }

    // MARK: - Computed

    var totalUnreadMessages: Int {
        messageChannels.filter { $0.colonyID == colony.id }.reduce(0) { $0 + $1.unreadCount }
    }

    var pendingTaskCount: Int {
        tasks.filter { $0.status != .done && $0.colonyID == colony.id }.count
    }

    // Called after any data mutation to persist changes
    private func didMutate() {
        scheduleSave()
    }

    private func addActivity(type: ActivityType, referenceName: String, targetName: String? = nil) {
        activityEvents.insert(
            ActivityEvent(
                id: UUID(),
                colonyID: colony.id,
                actorID: currentUser.id,
                actorName: currentUser.displayName,
                type: type,
                referenceID: nil,
                metadata: ActivityMetadata(
                    referenceName: referenceName,
                    targetName: targetName,
                    amount: nil,
                    emoji: nil
                ),
                createdAt: Date()
            ),
            at: 0
        )
    }

    private func recalculateHiveHealth() {
        let taskCompletionRate = tasks.isEmpty ? 1 : Double(tasks.filter { $0.status == .done }.count) / Double(tasks.count)
        let balanceSettlementRate = expenses.isEmpty ? 1 : Double(expenses.filter { $0.isFullySettled }.count) / Double(expenses.count)
        let activeMembers = colony.members.filter {
            guard let lastActive = $0.lastActiveAt else { return false }
            return lastActive > Date().addingTimeInterval(-60 * 60 * 24 * 7)
        }.count
        let memberActivityRate = colony.members.isEmpty ? 1 : Double(activeMembers) / Double(colony.members.count)
        let choreComplianceRate = choreWheels.isEmpty ? 1 : Double(choreWheels.filter { ($0.nextRotationAt > Date()) }.count) / Double(choreWheels.count)

        healthScore.taskCompletionRate = taskCompletionRate
        healthScore.balanceSettlementRate = balanceSettlementRate
        healthScore.memberActivityRate = memberActivityRate
        healthScore.choreComplianceRate = choreComplianceRate
        healthScore.recalculate()
        didMutate()
    }

    private func nextDate(for frequency: RecurrenceFrequency) -> Date {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        }
    }

    private func semesterLabel() -> String {
        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        let season = month < 6 ? "Spring" : "Fall"
        return "\(season) \(year)"
    }
}

extension HiveSpaceStore {
    static let sample = HiveSpaceStore.makeSample()

    private static func makeSample() -> HiveSpaceStore {
        let colonyID = UUID()
        let projectColonyID = UUID()
        let tripColonyID = UUID()
        let familyColonyID = UUID()
        let you = HSUser(
            id: UUID(),
            displayName: "Avery",
            username: "@avery",
            email: "avery@hivespace.app",
            avatarURL: nil,
            colonyIDs: [colonyID, projectColonyID, tripColonyID, familyColonyID],
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 200)
        )
        let mayaID = UUID()
        let jordanID = UUID()
        let ariID = UUID()

        let members = [
            ColonyMember(id: you.id, displayName: "Avery", username: "@avery", avatarURL: nil, role: .queen, status: .active, joinedAt: .now.addingTimeInterval(-60 * 60 * 24 * 200), lastActiveAt: .now),
            ColonyMember(id: mayaID, displayName: "Maya", username: "@maya", avatarURL: nil, role: .worker, status: .active, joinedAt: .now.addingTimeInterval(-60 * 60 * 24 * 180), lastActiveAt: .now.addingTimeInterval(-60 * 30)),
            ColonyMember(id: jordanID, displayName: "Jordan", username: "@jordan", avatarURL: nil, role: .worker, status: .active, joinedAt: .now.addingTimeInterval(-60 * 60 * 24 * 160), lastActiveAt: .now.addingTimeInterval(-60 * 60 * 5)),
            ColonyMember(id: ariID, displayName: "Ari", username: "@ari", avatarURL: nil, role: .guest, status: .active, joinedAt: .now.addingTimeInterval(-60 * 60 * 24 * 120), lastActiveAt: .now.addingTimeInterval(-60 * 60 * 20))
        ]

        let colony = Colony(
            id: colonyID,
            name: "Juniper House",
            emoji: "✦",
            description: "Your shared home colony.",
            joinCode: "HIVE42",
            createdByID: you.id,
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 200),
            type: .roommates,
            members: members,
            settings: ColonySettings(
                isPublic: false,
                allowGuestView: true,
                defaultSplitMethod: .equal,
                semesterMode: true,
                nudgesEnabled: true,
                currencyCode: "USD"
            )
        )

        let projectColony = Colony(
            id: projectColonyID,
            name: "Launch Crew",
            emoji: "🚀",
            description: "Product sprint colony.",
            joinCode: "CREW88",
            createdByID: you.id,
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 90),
            type: .team,
            members: members,
            settings: colony.settings
        )

        let tripColony = Colony(
            id: tripColonyID,
            name: "Big Sur Trip",
            emoji: "🌊",
            description: "Weekend getaway planning colony.",
            joinCode: "TRIP24",
            createdByID: you.id,
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 45),
            type: .friend,
            members: members,
            settings: colony.settings
        )

        let familyColony = Colony(
            id: familyColonyID,
            name: "Rivera Family",
            emoji: "✦",
            description: "Family coordination colony.",
            joinCode: "FAM321",
            createdByID: you.id,
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 320),
            type: .family,
            members: members,
            settings: colony.settings
        )

        let tasks = [
            HSTask(id: UUID(), colonyID: colonyID, title: "Kitchen Reset", description: "Wipe counters and run the dishwasher.", status: .todo, priority: .high, assignedToIDs: [mayaID], createdByID: you.id, createdAt: .now.addingTimeInterval(-60 * 60 * 4), dueDate: .now.addingTimeInterval(60 * 60 * 2), completedAt: nil, completedByID: nil, linkedExpenseID: nil, recurrence: nil, tags: ["Cleaning"]),
            HSTask(id: UUID(), colonyID: colonyID, title: "Grocery Run", description: "Milk, eggs, fruit, and oat milk.", status: .inProgress, priority: .medium, assignedToIDs: [jordanID], createdByID: mayaID, createdAt: .now.addingTimeInterval(-60 * 60 * 8), dueDate: .now.addingTimeInterval(60 * 60 * 12), completedAt: nil, completedByID: nil, linkedExpenseID: nil, recurrence: nil, tags: ["Errands"]),
            HSTask(id: UUID(), colonyID: colonyID, title: "Utilities Check", description: "Verify autopay is active.", status: .done, priority: .low, assignedToIDs: [you.id], createdByID: you.id, createdAt: .now.addingTimeInterval(-60 * 60 * 30), dueDate: .now.addingTimeInterval(-60 * 60 * 6), completedAt: .now.addingTimeInterval(-60 * 20), completedByID: you.id, linkedExpenseID: nil, recurrence: nil, tags: ["Admin"])
        ]

        let expenses = [
            Expense(
                id: UUID(),
                colonyID: colonyID,
                title: "Groceries",
                amount: 96,
                currencyCode: "USD",
                category: .groceries,
                paidByID: you.id,
                splits: [
                    ExpenseSplit(id: UUID(), userID: you.id, amount: 24, percentage: nil, isSettled: true, settledAt: .now, settledVia: .inApp),
                    ExpenseSplit(id: UUID(), userID: mayaID, amount: 24, percentage: nil, isSettled: false, settledAt: nil, settledVia: nil),
                    ExpenseSplit(id: UUID(), userID: jordanID, amount: 24, percentage: nil, isSettled: false, settledAt: nil, settledVia: nil),
                    ExpenseSplit(id: UUID(), userID: ariID, amount: 24, percentage: nil, isSettled: false, settledAt: nil, settledVia: nil)
                ],
                splitMethod: .equal,
                createdByID: you.id,
                createdAt: .now.addingTimeInterval(-60 * 60 * 6),
                settledAt: nil,
                receiptImageURL: nil,
                linkedTaskID: nil,
                isRecurring: false,
                recurrence: nil,
                notes: "Shared fridge restock.",
                reactions: []
            ),
            Expense(
                id: UUID(),
                colonyID: colonyID,
                title: "Wi-Fi",
                amount: 78,
                currencyCode: "USD",
                category: .subscriptions,
                paidByID: mayaID,
                splits: [
                    ExpenseSplit(id: UUID(), userID: you.id, amount: 19.5, percentage: nil, isSettled: true, settledAt: .now, settledVia: .venmo),
                    ExpenseSplit(id: UUID(), userID: mayaID, amount: 19.5, percentage: nil, isSettled: true, settledAt: .now, settledVia: .inApp),
                    ExpenseSplit(id: UUID(), userID: jordanID, amount: 19.5, percentage: nil, isSettled: true, settledAt: .now, settledVia: .cashApp),
                    ExpenseSplit(id: UUID(), userID: ariID, amount: 19.5, percentage: nil, isSettled: true, settledAt: .now, settledVia: .zelle)
                ],
                splitMethod: .equal,
                createdByID: mayaID,
                createdAt: .now.addingTimeInterval(-60 * 60 * 24),
                settledAt: .now.addingTimeInterval(-60 * 60 * 4),
                receiptImageURL: nil,
                linkedTaskID: nil,
                isRecurring: true,
                recurrence: Recurrence(frequency: .monthly, interval: 1, endsOn: nil, nextOccurrence: .now.addingTimeInterval(60 * 60 * 24 * 30)),
                notes: "Monthly internet plan.",
                reactions: []
            )
        ]

        var health = HiveHealthScore(
            colonyID: colonyID,
            score: 0,
            grade: .active,
            lastUpdated: .now,
            taskCompletionRate: 0.88,
            balanceSettlementRate: 0.82,
            memberActivityRate: 0.92,
            choreComplianceRate: 0.96
        )
        health.recalculate()

        let chores = [
            ChoreWheel(
                id: UUID(),
                colonyID: colonyID,
                choreName: "Trash Night",
                assignees: [you.id, mayaID, jordanID],
                currentIndex: 1,
                rotationFrequency: .weekly,
                lastRotatedAt: .now.addingTimeInterval(-60 * 60 * 24 * 3),
                nextRotationAt: .now.addingTimeInterval(60 * 60 * 24 * 4)
            )
        ]

        let eventSplits = [
            EventSplit(
                id: UUID(),
                colonyID: colonyID,
                title: "Concert tickets 🎵",
                totalAmount: 240,
                amountPerPerson: 60,
                createdByID: mayaID,
                createdAt: .now.addingTimeInterval(-60 * 60 * 10),
                expiresAt: .now.addingTimeInterval(60 * 60 * 24 * 2),
                participants: [
                    EventParticipant(id: you.id, response: .in, respondedAt: .now.addingTimeInterval(-60 * 60)),
                    EventParticipant(id: mayaID, response: .in, respondedAt: .now.addingTimeInterval(-60 * 60 * 2)),
                    EventParticipant(id: jordanID, response: .pending, respondedAt: nil),
                    EventParticipant(id: ariID, response: .out, respondedAt: .now.addingTimeInterval(-60 * 60 * 3))
                ],
                status: .open
            )
        ]

        let joinRequests = [
            ColonyJoinRequest(
                id: UUID(),
                colonyID: colonyID,
                requesterID: UUID(),
                status: .pending,
                requestedAt: .now.addingTimeInterval(-60 * 60 * 3),
                resolvedAt: nil,
                resolvedByID: nil
            )
        ]

        let activityEvents = [
            ActivityEvent(id: UUID(), colonyID: colonyID, actorID: mayaID, actorName: "Maya", type: .taskCompleted, referenceID: nil, metadata: ActivityMetadata(referenceName: "Kitchen Reset", targetName: nil, amount: nil, emoji: nil), createdAt: .now.addingTimeInterval(-60 * 12)),
            ActivityEvent(id: UUID(), colonyID: colonyID, actorID: jordanID, actorName: "Jordan", type: .taskCreated, referenceID: nil, metadata: ActivityMetadata(referenceName: "Grocery Run", targetName: nil, amount: nil, emoji: nil), createdAt: .now.addingTimeInterval(-60 * 40)),
            ActivityEvent(id: UUID(), colonyID: colonyID, actorID: ariID, actorName: "Ari", type: .expenseSettled, referenceID: nil, metadata: ActivityMetadata(referenceName: "Wi-Fi", targetName: nil, amount: nil, emoji: nil), createdAt: .now.addingTimeInterval(-60 * 60 * 5))
        ]

        let generalChannel = MessageChannel(id: UUID(), colonyID: colonyID, name: "general", kind: .general, memberIDs: members.map(\.id), topic: "House updates", unreadCount: 0)
        let choresChannel = MessageChannel(id: UUID(), colonyID: colonyID, name: "chores", kind: .tasks, memberIDs: members.map(\.id), topic: "Task coordination", unreadCount: 2)
        let splitChannel = MessageChannel(id: UUID(), colonyID: colonyID, name: "split", kind: .expenses, memberIDs: members.map(\.id), topic: "Shared expenses", unreadCount: 1)

        let messages = [
            HSMessage(id: UUID(), channelID: generalChannel.id, senderID: mayaID, senderName: "Maya", body: "Can we reset the kitchen before guests arrive?", sentAt: .now.addingTimeInterval(-60 * 25), attachments: [], reactions: [], replyToMessageID: nil),
            HSMessage(id: UUID(), channelID: choresChannel.id, senderID: jordanID, senderName: "Jordan", body: "I’ll handle groceries if someone grabs detergent.", sentAt: .now.addingTimeInterval(-60 * 12), attachments: [], reactions: [], replyToMessageID: nil),
            HSMessage(id: UUID(), channelID: splitChannel.id, senderID: you.id, senderName: "Avery", body: "Added the grocery receipt to Split.", sentAt: .now.addingTimeInterval(-60 * 8), attachments: [], reactions: [], replyToMessageID: nil)
        ]

        let calls = [
            CallSession(id: UUID(), colonyID: colonyID, title: "Sunday Reset Call", type: .video, state: .scheduled, startedAt: nil, scheduledFor: .now.addingTimeInterval(60 * 60 * 24), participantIDs: members.map(\.id)),
            CallSession(id: UUID(), colonyID: colonyID, title: "Quick Budget Sync", type: .voice, state: .incoming, startedAt: nil, scheduledFor: nil, participantIDs: [you.id, mayaID])
        ]

        let callParticipants = members.map {
            CallParticipantState(id: $0.id, displayName: $0.displayName, isMuted: $0.id != you.id, isCameraOn: $0.id == you.id || $0.id == mayaID, isSpeaking: $0.id == mayaID)
        }

        let trip = HiveTrip(
            id: UUID(),
            colonyID: colonyID,
            title: "Big Sur Weekend",
            location: "Big Sur, CA",
            startDate: .now.addingTimeInterval(60 * 60 * 24 * 12),
            endDate: .now.addingTimeInterval(60 * 60 * 24 * 15),
            itineraryDays: [
                TripItineraryDay(
                    id: UUID(),
                    date: .now.addingTimeInterval(60 * 60 * 24 * 12),
                    events: [
                        TripItineraryEvent(id: UUID(), title: "Check-in", timeLabel: "4:00 PM", location: "Redwood Cabins", confirmationNumber: "RWC-4832"),
                        TripItineraryEvent(id: UUID(), title: "Dinner Reservation", timeLabel: "7:30 PM", location: "Sierra Table", confirmationNumber: "DIN-9211")
                    ]
                )
            ],
            packingItems: [
                PackingItem(id: UUID(), title: "First aid kit", category: .essentials, isShared: true, isPacked: true),
                PackingItem(id: UUID(), title: "Chargers", category: .travel, isShared: false, isPacked: false),
                PackingItem(id: UUID(), title: "Layered outfits", category: .outfits, isShared: false, isPacked: false)
            ],
            polls: [
                TripPoll(
                    id: UUID(),
                    question: "Which restaurant should we book?",
                    options: [
                        TripPollOption(id: UUID(), title: "Sierra Table", voteCount: 2),
                        TripPollOption(id: UUID(), title: "Cliffside Grill", voteCount: 1)
                    ]
                )
            ]
        )

        let availabilityCalendar = Calendar.current
        let availabilityStart = availabilityCalendar.date(byAdding: .day, value: 2, to: .now) ?? .now
        let availabilityDays: [AvailabilityDay] = (0..<5).map { dayOffset in
            let date = availabilityCalendar.date(byAdding: .day, value: dayOffset, to: availabilityStart) ?? availabilityStart
            return AvailabilityDay(
                id: UUID(),
                date: date,
                shortLabel: date.formatted(.dateTime.month(.abbreviated).day()),
                weekdayLabel: date.formatted(.dateTime.weekday(.abbreviated))
            )
        }
        let availabilitySlots = availabilityDays.flatMap { day in
            (8...16).map { hour in
                AvailabilitySlot(
                    id: UUID(),
                    dayID: day.id,
                    hour: hour,
                    label: DateComponents(calendar: availabilityCalendar, hour: hour)
                        .date?
                        .formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))) ?? "\(hour):00"
                )
            }
        }
        let currentUserSlots = availabilitySlots.filter { slot in
            (9...11).contains(slot.hour) || (13...16).contains(slot.hour)
        }.map(\.id)
        let mayaSlots = availabilitySlots.filter { slot in
            (slot.hour == 9 || slot.hour == 10 || slot.hour == 13 || slot.hour == 14 || slot.hour == 15)
                && slot.hour != 12
        }.map(\.id)
        let jordanSlots = availabilitySlots.filter { slot in
            (10...12).contains(slot.hour) || slot.hour == 15 || slot.hour == 16
        }.map(\.id)
        let ariSlots = availabilitySlots.filter { slot in
            (9...11).contains(slot.hour) || (14...16).contains(slot.hour)
        }.map(\.id)
        let availabilityPoll = AvailabilityPoll(
            id: UUID(),
            colonyID: colonyID,
            title: "Committee Meeting",
            timezoneIdentifier: TimeZone.current.identifier,
            days: availabilityDays,
            slots: availabilitySlots,
            participantIDs: members.map(\.id),
            responses: [
                AvailabilityResponse(id: UUID(), userID: you.id, availableSlotIDs: currentUserSlots, updatedAt: .now),
                AvailabilityResponse(id: UUID(), userID: mayaID, availableSlotIDs: mayaSlots, updatedAt: .now.addingTimeInterval(-60 * 8)),
                AvailabilityResponse(id: UUID(), userID: jordanID, availableSlotIDs: jordanSlots, updatedAt: .now.addingTimeInterval(-60 * 20)),
                AvailabilityResponse(id: UUID(), userID: ariID, availableSlotIDs: ariSlots, updatedAt: .now.addingTimeInterval(-60 * 40))
            ]
        )

        let workspace = TeamWorkspace(
            id: UUID(),
            colonyID: projectColonyID,
            channels: [
                TeamChannel(id: UUID(), title: "launch", purpose: "Go-to-market planning"),
                TeamChannel(id: UUID(), title: "design", purpose: "Assets and reviews")
            ],
            documents: [
                SharedDocument(id: UUID(), title: "Launch checklist", updatedAt: .now.addingTimeInterval(-60 * 60 * 5), ownerName: "Avery"),
                SharedDocument(id: UUID(), title: "Brand voice guide", updatedAt: .now.addingTimeInterval(-60 * 60 * 24), ownerName: "Maya")
            ],
            calendarEvents: [
                WorkspaceCalendarEvent(id: UUID(), title: "Sprint demo", date: .now.addingTimeInterval(60 * 60 * 48), location: "Zoom"),
                WorkspaceCalendarEvent(id: UUID(), title: "Content review", date: .now.addingTimeInterval(60 * 60 * 72), location: nil)
            ]
        )

        let account = HiveSpaceAccount(
            id: UUID(),
            userID: you.id,
            displayName: you.displayName,
            hive: Hive(
                id: UUID(),
                name: "Avery's Hive",
                ownerID: you.id,
                colonyIDs: [colonyID, projectColonyID, tripColonyID, familyColonyID],
                preferredColonyID: colonyID
            ),
            subscriptionTier: .plus,
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 200)
        )

        return HiveSpaceStore(
            account: account,
            allColonies: [colony, projectColony, tripColony, familyColony],
            currentUser: you,
            colony: colony,
            tasks: tasks,
            expenses: expenses,
            activityEvents: activityEvents,
            healthScore: health,
            choreWheels: chores,
            nudges: [],
            joinRequests: joinRequests,
            settlementRequests: [],
            eventSplits: eventSplits,
            semesterSnapshots: [],
            messageChannels: [generalChannel, choresChannel, splitChannel],
            messages: messages,
            directThreads: [
                DirectMessageThread(id: UUID(), participantIDs: [you.id, mayaID], lastMessagePreview: "Can you handle the receipt?", updatedAt: .now.addingTimeInterval(-60 * 20))
            ],
            callSessions: calls,
            callParticipants: callParticipants,
            trips: [trip],
            availabilityPolls: [availabilityPoll],
            teamWorkspace: workspace
        )
    }
}
