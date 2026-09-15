import Foundation

struct TeamWorkspace: Identifiable, Codable, Hashable {
    let id: UUID
    var colonyID: UUID
    var channels: [TeamChannel]
    var documents: [SharedDocument]
    var calendarEvents: [WorkspaceCalendarEvent]
}

struct TeamChannel: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var purpose: String
}

struct SharedDocument: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var updatedAt: Date
    var ownerName: String
}

struct WorkspaceCalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var location: String?
}
