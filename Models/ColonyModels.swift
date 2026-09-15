import Foundation

struct HSUser: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var username: String
    var email: String
    var avatarURL: String?
    var colonyIDs: [UUID]
    var createdAt: Date

    var shareableID: String {
        let short = id.uuidString.prefix(4).uppercased()
        return "HVS-\(short)"
    }
}

struct Colony: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var description: String?
    var joinCode: String
    var createdByID: UUID
    var createdAt: Date
    var type: ColonyType
    var members: [ColonyMember]
    var settings: ColonySettings

    var memberCount: Int {
        members.filter { $0.status == .active }.count
    }
}

enum ColonyType: String, Codable, CaseIterable {
    case roommates = "Roommates"
    case project = "Project"
    case friend = "Friend Group"
    case family = "Family"
    case team = "Team"
}

enum MemberRole: String, Codable, CaseIterable {
    case queen = "Queen"
    case worker = "Worker"
    case guest = "Guest"
}

enum MemberStatus: String, Codable, CaseIterable {
    case active = "Active"
    case invited = "Invited"
    case removed = "Removed"
}

struct ColonySettings: Codable, Hashable {
    var isPublic: Bool
    var allowGuestView: Bool
    var defaultSplitMethod: SplitMethod
    var semesterMode: Bool
    var nudgesEnabled: Bool
    var currencyCode: String
}

struct ColonyMember: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var username: String
    var avatarURL: String?
    var role: MemberRole
    var status: MemberStatus
    var joinedAt: Date
    var lastActiveAt: Date?
}

struct ColonyJoinRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let colonyID: UUID
    let requesterID: UUID
    var status: JoinRequestStatus
    let requestedAt: Date
    var resolvedAt: Date?
    var resolvedByID: UUID?
}

enum JoinRequestStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
}

enum ColonyError: LocalizedError {
    case notFound
    case alreadyMember
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notFound:          return "No colony found with that code."
        case .alreadyMember:     return "You're already in this colony."
        case .permissionDenied:  return "You don't have permission to do that."
        }
    }
}
