import Foundation

// MARK: - Persistence Service

/// Handles all local data storage using JSON files in the app's documents directory.
/// Each data domain is stored as a separate file for efficient partial reads/writes.
actor PersistenceService {
    static let shared = PersistenceService()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HiveSpace", isDirectory: true)
    }

    private init() {
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HiveSpace", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    // MARK: - Generic Save/Load

    func save<T: Encodable>(_ value: T, to key: StorageKey) throws {
        let data = try encoder.encode(value)
        let url = documentsURL.appendingPathComponent(key.filename)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    func load<T: Decodable>(_ type: T.Type, from key: StorageKey) throws -> T {
        let url = documentsURL.appendingPathComponent(key.filename)
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }

    func exists(_ key: StorageKey) -> Bool {
        fileManager.fileExists(atPath: documentsURL.appendingPathComponent(key.filename).path)
    }

    func delete(_ key: StorageKey) throws {
        let url = documentsURL.appendingPathComponent(key.filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func clearAll() throws {
        if fileManager.fileExists(atPath: documentsURL.path) {
            try fileManager.removeItem(at: documentsURL)
            try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Storage Keys

enum StorageKey: String, CaseIterable {
    case account
    case colonies
    case currentColonyID
    case tasks
    case expenses
    case activityEvents
    case healthScore
    case choreWheels
    case nudges
    case joinRequests
    case settlementRequests
    case eventSplits
    case semesterSnapshots
    case messageChannels
    case messages
    case directThreads
    case callSessions
    case trips
    case availabilityPolls
    case teamWorkspace
    case userProfile
    case authToken

    var filename: String { "\(rawValue).json" }
}

// MARK: - Persistence-Backed Store Snapshot

/// A complete snapshot of the store's state, used for bulk save/restore.
struct StoreSnapshot: Codable {
    let account: HiveSpaceAccount
    let allColonies: [Colony]
    let currentUser: HSUser
    let currentColonyID: UUID
    let tasks: [HSTask]
    let expenses: [Expense]
    let activityEvents: [ActivityEvent]
    let healthScore: HiveHealthScore
    let choreWheels: [ChoreWheel]
    let nudges: [Nudge]
    let joinRequests: [ColonyJoinRequest]
    let settlementRequests: [SettlementRequest]
    let eventSplits: [EventSplit]
    let semesterSnapshots: [SemesterSnapshot]
    let messageChannels: [MessageChannel]
    let messages: [HSMessage]
    let directThreads: [DirectMessageThread]
    let callSessions: [CallSession]
    let trips: [HiveTrip]
    let availabilityPolls: [AvailabilityPoll]
    let teamWorkspace: TeamWorkspace
}

// MARK: - Convenience Extensions

extension PersistenceService {
    func saveSnapshot(_ snapshot: StoreSnapshot) async {
        do {
            try save(snapshot.account, to: .account)
            try save(snapshot.allColonies, to: .colonies)
            try save(snapshot.currentColonyID, to: .currentColonyID)
            try save(snapshot.tasks, to: .tasks)
            try save(snapshot.expenses, to: .expenses)
            try save(snapshot.activityEvents, to: .activityEvents)
            try save(snapshot.healthScore, to: .healthScore)
            try save(snapshot.choreWheels, to: .choreWheels)
            try save(snapshot.nudges, to: .nudges)
            try save(snapshot.joinRequests, to: .joinRequests)
            try save(snapshot.settlementRequests, to: .settlementRequests)
            try save(snapshot.eventSplits, to: .eventSplits)
            try save(snapshot.semesterSnapshots, to: .semesterSnapshots)
            try save(snapshot.messageChannels, to: .messageChannels)
            try save(snapshot.messages, to: .messages)
            try save(snapshot.directThreads, to: .directThreads)
            try save(snapshot.callSessions, to: .callSessions)
            try save(snapshot.trips, to: .trips)
            try save(snapshot.availabilityPolls, to: .availabilityPolls)
            try save(snapshot.teamWorkspace, to: .teamWorkspace)
            try save(snapshot.currentUser, to: .userProfile)
        } catch {
            print("[PersistenceService] Save failed: \(error)")
        }
    }

    func loadSnapshot() async -> StoreSnapshot? {
        guard exists(.account) else { return nil }

        do {
            let account = try load(HiveSpaceAccount.self, from: .account)
            let colonies = try load([Colony].self, from: .colonies)
            let currentColonyID = try load(UUID.self, from: .currentColonyID)
            let currentUser = try load(HSUser.self, from: .userProfile)
            let tasks = try load([HSTask].self, from: .tasks)
            let expenses = try load([Expense].self, from: .expenses)
            let activityEvents = try load([ActivityEvent].self, from: .activityEvents)
            let healthScore = try load(HiveHealthScore.self, from: .healthScore)
            let choreWheels = try load([ChoreWheel].self, from: .choreWheels)
            let nudges = try load([Nudge].self, from: .nudges)
            let joinRequests = try load([ColonyJoinRequest].self, from: .joinRequests)
            let settlementRequests = try load([SettlementRequest].self, from: .settlementRequests)
            let eventSplits = try load([EventSplit].self, from: .eventSplits)
            let semesterSnapshots = try load([SemesterSnapshot].self, from: .semesterSnapshots)
            let messageChannels = try load([MessageChannel].self, from: .messageChannels)
            let messages = try load([HSMessage].self, from: .messages)
            let directThreads = try load([DirectMessageThread].self, from: .directThreads)
            let callSessions = try load([CallSession].self, from: .callSessions)
            let trips = try load([HiveTrip].self, from: .trips)
            let availabilityPolls = try load([AvailabilityPoll].self, from: .availabilityPolls)
            let teamWorkspace = try load(TeamWorkspace.self, from: .teamWorkspace)

            return StoreSnapshot(
                account: account,
                allColonies: colonies,
                currentUser: currentUser,
                currentColonyID: currentColonyID,
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
        } catch {
            print("[PersistenceService] Load failed: \(error)")
            return nil
        }
    }

    func hasExistingData() -> Bool {
        exists(.account)
    }
}
