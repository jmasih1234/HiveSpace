import Foundation

// MARK: - Activity Event
// Powers the Colony Feed — every meaningful action logs one of these
struct ActivityEvent: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var actorID: UUID             // who did the thing
    var actorName: String         // denormalized for display speed
    var type: ActivityType
    var referenceID: UUID?        // task/expense/member being referenced
    var metadata: ActivityMetadata?
    var createdAt: Date
}

enum ActivityType: String, Codable {
    // Tasks
    case taskCreated    = "task.created"
    case taskCompleted  = "task.completed"
    case taskAssigned   = "task.assigned"
    case taskOverdue    = "task.overdue"

    // Expenses
    case expenseAdded   = "expense.added"
    case expenseSettled = "expense.settled"
    case nudgeSent      = "nudge.sent"

    // Colony
    case memberJoined   = "member.joined"
    case memberLeft     = "member.left"
    case choreRotated   = "chore.rotated"
    case semesterReset  = "semester.reset"

    // Computed display string
    func label(actorName: String, metadata: ActivityMetadata?) -> String {
        let ref = metadata?.referenceName ?? "something"
        switch self {
        case .taskCreated:    return "\(actorName) added \"\(ref)\""
        case .taskCompleted:  return "\(actorName) completed \"\(ref)\" ✓"
        case .taskAssigned:   return "\(actorName) was assigned \"\(ref)\""
        case .taskOverdue:    return "\"\(ref)\" is overdue"
        case .expenseAdded:   return "\(actorName) added \(ref)"
        case .expenseSettled: return "\(actorName) settled up"
        case .nudgeSent:      return "\(actorName) sent a nudge 👋"
        case .memberJoined:   return "\(actorName) joined the colony"
        case .memberLeft:     return "\(actorName) left the colony"
        case .choreRotated:   return "Chore rotation: \"\(ref)\" -> \(metadata?.targetName ?? "next person")"
        case .semesterReset:  return "Colony reset for new semester 🎓"
        }
    }
}

// Lightweight extra context attached to an activity event
struct ActivityMetadata: Codable {
    var referenceName: String?    // e.g. task title, expense title
    var targetName: String?       // e.g. new assignee name
    var amount: Double?           // for expense events
    var emoji: String?
}

// MARK: - Hive Health Score
// A fun per-colony metric that gamifies responsibility
struct HiveHealthScore: Codable {
    var colonyID: UUID
    var score: Int                // 0–100
    var grade: HealthGrade
    var lastUpdated: Date

    // Sub-scores that feed into the total
    var taskCompletionRate: Double    // % of tasks completed on time (30 pts)
    var balanceSettlementRate: Double // % of balances settled (30 pts)
    var memberActivityRate: Double    // % of members active in last 7 days (20 pts)
    var choreComplianceRate: Double   // % of chores done on rotation (20 pts)

    // Recompute from sub-scores (call after any update)
    mutating func recalculate() {
        let raw = (taskCompletionRate * 30)
                + (balanceSettlementRate * 30)
                + (memberActivityRate * 20)
                + (choreComplianceRate * 20)
        score = min(100, max(0, Int(raw)))
        grade = HealthGrade.from(score: score)
        lastUpdated = Date()
    }
}

enum HealthGrade: String, Codable {
    case thriving  = "Thriving"   // 80–100
    case active    = "Active"     // 60–79
    case sluggish  = "Sluggish"   // 40–59
    case dormant   = "Dormant"    // 0–39

    static func from(score: Int) -> HealthGrade {
        switch score {
        case 80...100: return .thriving
        case 60...79:  return .active
        case 40...59:  return .sluggish
        default:       return .dormant
        }
    }

    var emoji: String {
        switch self {
        case .thriving: return "🟢"
        case .active:   return "🟡"
        case .sluggish: return "🟠"
        case .dormant:  return "🔴"
        }
    }
}

// MARK: - Semester Reset
// Archives current colony state and starts fresh
struct SemesterSnapshot: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var semesterLabel: String     // e.g. "Fall 2025"
    var archivedAt: Date
    var createdByID: UUID

    // Summary stats preserved for memory
    var totalExpenses: Double
    var tasksCompleted: Int
    var topContributorID: UUID?
    var finalHealthScore: Int
}
