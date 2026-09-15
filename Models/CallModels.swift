import Foundation

struct CallSession: Identifiable, Codable, Hashable {
    let id: UUID
    var colonyID: UUID
    var title: String
    var type: CallType
    var state: CallState
    var startedAt: Date?
    var scheduledFor: Date?
    var participantIDs: [UUID]
}

enum CallType: String, Codable, CaseIterable, Hashable {
    case voice = "Voice"
    case video = "Video"
}

enum CallState: String, Codable, CaseIterable, Hashable {
    case idle = "Idle"
    case incoming = "Incoming"
    case active = "Active"
    case scheduled = "Scheduled"
    case ended = "Ended"
}

struct CallParticipantState: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var isMuted: Bool
    var isCameraOn: Bool
    var isSpeaking: Bool
}
