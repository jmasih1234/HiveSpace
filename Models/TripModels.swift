import Foundation

struct HiveTrip: Identifiable, Codable, Hashable {
    let id: UUID
    var colonyID: UUID
    var title: String
    var location: String
    var startDate: Date
    var endDate: Date
    var itineraryDays: [TripItineraryDay]
    var packingItems: [PackingItem]
    var polls: [TripPoll]
}

struct TripItineraryDay: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var events: [TripItineraryEvent]
}

struct TripItineraryEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var timeLabel: String
    var location: String
    var confirmationNumber: String?
}

struct PackingItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var category: PackingCategory
    var isShared: Bool
    var isPacked: Bool
}

enum PackingCategory: String, Codable, CaseIterable, Hashable {
    case essentials = "Essentials"
    case travel = "Travel"
    case outfits = "Outfits"
    case extras = "Extras"
}

struct TripPoll: Identifiable, Codable, Hashable {
    let id: UUID
    var question: String
    var options: [TripPollOption]
}

struct TripPollOption: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var voteCount: Int
}
