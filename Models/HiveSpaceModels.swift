import Foundation

struct HiveSpaceAccount: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID
    var displayName: String
    var hive: Hive
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
}

struct Hive: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var ownerID: UUID
    var colonyIDs: [UUID]
    var preferredColonyID: UUID?
}

enum SubscriptionTier: String, Codable, CaseIterable, Hashable {
    case free = "Free"
    case plus = "Plus"
    case pro = "Pro"
}
