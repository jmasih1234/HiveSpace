import Foundation

// MARK: - Task
struct HSTask: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var title: String
    var description: String?
    var status: TaskStatus
    var priority: TaskPriority
    var assignedToIDs: [UUID]     // can assign to multiple members
    var createdByID: UUID
    var createdAt: Date
    var dueDate: Date?
    var completedAt: Date?
    var completedByID: UUID?
    var linkedExpenseID: UUID?    // if task triggers an expense on completion
    var recurrence: Recurrence?
    var tags: [String]
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo       = "To Do"
    case inProgress = "In Progress"
    case done       = "Done"
}

enum TaskPriority: String, Codable, CaseIterable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
}

// MARK: - Recurrence
struct Recurrence: Codable {
    var frequency: RecurrenceFrequency
    var interval: Int             // every N days/weeks/months
    var endsOn: Date?
    var nextOccurrence: Date?
}

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
}

// MARK: - Chore Wheel
// Rotating chore assignments — auto-reassigns on a schedule
struct ChoreWheel: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var choreName: String
    var assignees: [UUID]         // ordered list — rotates through this
    var currentIndex: Int         // which member is currently up
    var rotationFrequency: RecurrenceFrequency
    var lastRotatedAt: Date?
    var nextRotationAt: Date

    // Who is currently responsible
    var currentAssigneeID: UUID {
        assignees[currentIndex % assignees.count]
    }

    // Advance to next person in rotation
    mutating func rotate() {
        currentIndex = (currentIndex + 1) % assignees.count
        lastRotatedAt = Date()
    }
}

// MARK: - Nudge
struct Nudge: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var senderID: UUID
    var recipientID: UUID
    var referenceType: NudgeReferenceType
    var referenceID: UUID         // ID of the task or expense being nudged about
    var message: String?          // optional custom message
    var sentAt: Date
    var seenAt: Date?
}

enum NudgeReferenceType: String, Codable {
    case task
    case expense
}
