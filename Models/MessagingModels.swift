import Foundation

struct MessageChannel: Identifiable, Codable, Hashable {
    let id: UUID
    var colonyID: UUID
    var name: String
    var kind: MessageChannelKind
    var memberIDs: [UUID]
    var topic: String?
    var unreadCount: Int
}

enum MessageChannelKind: String, Codable, CaseIterable, Hashable {
    case general = "General"
    case tasks = "Tasks"
    case expenses = "Expenses"
    case social = "Social"
    case direct = "Direct Message"
}

struct HSMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var channelID: UUID
    var senderID: UUID
    var senderName: String
    var body: String
    var sentAt: Date
    var attachments: [MessageAttachment]
    var reactions: [MessageReaction]
    var replyToMessageID: UUID?
}

struct MessageAttachment: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: MessageAttachmentKind
    var title: String
}

enum MessageAttachmentKind: String, Codable, CaseIterable, Hashable {
    case image = "Image"
    case document = "Document"
    case link = "Link"
}

struct MessageReaction: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID
    var emoji: String
}

struct DirectMessageThread: Identifiable, Codable, Hashable {
    let id: UUID
    var participantIDs: [UUID]
    var lastMessagePreview: String
    var updatedAt: Date
}
