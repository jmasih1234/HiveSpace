import Foundation

// MARK: - Expense
struct Expense: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var title: String
    var amount: Double
    var currencyCode: String      // "USD"
    var category: ExpenseCategory
    var paidByID: UUID            // who fronted the money
    var splits: [ExpenseSplit]    // how it's divided
    var splitMethod: SplitMethod
    var createdByID: UUID
    var createdAt: Date
    var settledAt: Date?
    var receiptImageURL: String?  // for photo receipt feature
    var linkedTaskID: UUID?       // task that triggered this expense
    var isRecurring: Bool
    var recurrence: Recurrence?
    var notes: String?
    var reactions: [ExpenseReaction]

    // Whether all splits have been settled
    var isFullySettled: Bool {
        splits.allSatisfy { $0.isSettled || $0.userID == paidByID }
    }

    // Total confirmed owed to payer (excluding payer's own share)
    var totalOwed: Double {
        splits
            .filter { $0.userID != paidByID && !$0.isSettled }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Expense Split
// One entry per person who shares in an expense
struct ExpenseSplit: Identifiable, Codable {
    let id: UUID
    var userID: UUID
    var amount: Double            // their portion in currency
    var percentage: Double?       // if split by percentage
    var isSettled: Bool
    var settledAt: Date?
    var settledVia: SettlementMethod?
}

enum SplitMethod: String, Codable, CaseIterable {
    case equal = "Split equally"
    case percentage = "By percentage"
    case custom = "Custom amounts"
    case itemized = "Itemized"
}

enum SettlementMethod: String, Codable {
    case inApp    = "In App"
    case venmo    = "Venmo"
    case cashApp  = "Cash App"
    case zelle    = "Zelle"
    case cash     = "Cash"
}

// MARK: - Expense Category
enum ExpenseCategory: String, Codable, CaseIterable {
    case rent        = "Rent"
    case groceries   = "Groceries"
    case utilities   = "Utilities"
    case dining      = "Dining"
    case entertainment = "Entertainment"
    case transport   = "Transport"
    case subscriptions = "Subscriptions"
    case supplies    = "Supplies"
    case other       = "Other"

    var emoji: String {
        switch self {
        case .rent:          return "🏠"
        case .groceries:     return "🛒"
        case .utilities:     return "⚡️"
        case .dining:        return "🍕"
        case .entertainment: return "🎬"
        case .transport:     return "🚗"
        case .subscriptions: return "📱"
        case .supplies:      return "🧴"
        case .other:         return "💸"
        }
    }
}

// MARK: - Expense Reaction
struct ExpenseReaction: Identifiable, Codable {
    let id: UUID
    var userID: UUID
    var emoji: String             // "👀", "😬", "✅" etc.
    var reactedAt: Date
}

// MARK: - Balance Summary
// Computed per-user balance across all expenses in a colony
struct BalanceSummary: Identifiable {
    let id: UUID                  // userID
    var displayName: String
    var avatarURL: String?
    var totalOwed: Double         // they owe this much to others
    var totalOwedToThem: Double   // others owe them this much
    var netBalance: Double { totalOwedToThem - totalOwed }

    // Positive = others owe them. Negative = they owe others.
    var isSettled: Bool { abs(netBalance) < 0.01 }
}

// MARK: - Settlement Request
// When a user requests to settle a debt
struct SettlementRequest: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var fromUserID: UUID          // person paying
    var toUserID: UUID            // person receiving
    var amount: Double
    var method: SettlementMethod
    var status: SettlementStatus
    var expenseIDs: [UUID]        // which expenses this covers
    var createdAt: Date
    var confirmedAt: Date?
}

enum SettlementStatus: String, Codable {
    case pending
    case confirmed
    case disputed
}

// MARK: - Event Split
// Quick "who's in?" expense for shared events
struct EventSplit: Identifiable, Codable {
    let id: UUID
    var colonyID: UUID
    var title: String             // "Concert tickets 🎵"
    var totalAmount: Double
    var amountPerPerson: Double?  // if equal split
    var createdByID: UUID
    var createdAt: Date
    var expiresAt: Date?          // deadline to opt in
    var participants: [EventParticipant]
    var status: EventSplitStatus

    var confirmedCount: Int {
        participants.filter { $0.response == .in }.count
    }
}

struct EventParticipant: Identifiable, Codable {
    let id: UUID                  // userID
    var response: EventResponse
    var respondedAt: Date?
}

enum EventResponse: String, Codable {
    case pending = "Pending"
    case `in`    = "In"
    case out     = "Out"
}

enum EventSplitStatus: String, Codable {
    case open     = "Open"
    case locked   = "Locked"
    case settled  = "Settled"
}
