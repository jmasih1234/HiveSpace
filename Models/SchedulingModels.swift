import Foundation

struct AvailabilityPoll: Identifiable, Codable, Hashable {
    let id: UUID
    var colonyID: UUID
    var title: String
    var timezoneIdentifier: String
    var days: [AvailabilityDay]
    var slots: [AvailabilitySlot]
    var participantIDs: [UUID]
    var responses: [AvailabilityResponse]

    var participantCount: Int {
        participantIDs.count
    }
}

struct AvailabilityDay: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var shortLabel: String
    var weekdayLabel: String
}

struct AvailabilitySlot: Identifiable, Codable, Hashable {
    let id: UUID
    var dayID: UUID
    var hour: Int
    var label: String
}

struct AvailabilityResponse: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID
    var availableSlotIDs: [UUID]
    var updatedAt: Date
}
