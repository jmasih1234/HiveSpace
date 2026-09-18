import Foundation

// MARK: - Repository Protocols
//
// Each protocol defines the data-access contract for one domain.
// In Phase 1, only MockXxx implementations exist.
// In Phase 2+, SupabaseXxx implementations will be added and swapped
// into the RepositoryContainer based on SupabaseClientProvider.isLive.

// MARK: Auth

/// Handles sign-in, sign-up, session restore, sign-out, and password reset.
protocol AuthRepository: Sendable {
    func signIn(email: String, password: String) async throws -> HSUser
    func signUp(email: String, password: String, displayName: String, username: String) async throws -> HSUser
    func restoreSession() async throws -> HSUser?
    func signOut() async throws
    func resetPassword(email: String) async throws
}

// MARK: Profile

/// Read and update the current user's profile.
protocol ProfileRepository: Sendable {
    func fetchProfile(userID: UUID) async throws -> HSUser
    func updateProfile(_ user: HSUser) async throws -> HSUser
}

// MARK: Colony

/// Colony CRUD, membership, join codes, and role management.
protocol ColonyRepository: Sendable {
    func fetchColonies(for userID: UUID) async throws -> [Colony]
    func fetchColony(id: UUID) async throws -> Colony
    func createColony(_ colony: Colony) async throws -> Colony
    func updateColony(_ colony: Colony) async throws -> Colony
    func joinColony(code: String, userID: UUID) async throws -> Colony
    func leaveColony(colonyID: UUID, userID: UUID) async throws
    func updateMemberRole(colonyID: UUID, memberID: UUID, role: MemberRole) async throws
    func removeMember(colonyID: UUID, memberID: UUID) async throws
    func fetchJoinRequests(colonyID: UUID) async throws -> [ColonyJoinRequest]
    func resolveJoinRequest(requestID: UUID, approved: Bool) async throws
}

// MARK: Task

/// Shared tasks and chore-wheel operations.
protocol TaskRepository: Sendable {
    func fetchTasks(colonyID: UUID) async throws -> [HSTask]
    func createTask(_ task: HSTask, colonyID: UUID) async throws -> HSTask
    func updateTask(_ task: HSTask) async throws -> HSTask
    func deleteTask(id: UUID) async throws
    func fetchChoreWheels(colonyID: UUID) async throws -> [ChoreWheel]
    func createChoreWheel(_ wheel: ChoreWheel, colonyID: UUID) async throws -> ChoreWheel
    func advanceChoreWheel(id: UUID) async throws -> ChoreWheel
}

// MARK: Expense

/// Shared expenses, splits, and settlement tracking.
protocol ExpenseRepository: Sendable {
    func fetchExpenses(colonyID: UUID) async throws -> [Expense]
    func createExpense(_ expense: Expense, colonyID: UUID) async throws -> Expense
    func updateExpense(_ expense: Expense) async throws -> Expense
    func deleteExpense(id: UUID) async throws
    func fetchSettlementRequests(colonyID: UUID) async throws -> [SettlementRequest]
    func createSettlementRequest(_ request: SettlementRequest) async throws -> SettlementRequest
    func resolveSettlementRequest(id: UUID, accepted: Bool) async throws
    func fetchEventSplits(colonyID: UUID) async throws -> [EventSplit]
}

// MARK: Activity

/// Colony activity feed events.
protocol ActivityRepository: Sendable {
    func fetchEvents(colonyID: UUID, limit: Int) async throws -> [ActivityEvent]
    func postEvent(_ event: ActivityEvent, colonyID: UUID) async throws -> ActivityEvent
}

// MARK: Hive Health

/// Hive Health score reads and recalculation.
protocol HealthScoreRepository: Sendable {
    func fetchScore(colonyID: UUID) async throws -> HiveHealthScore
    func recalculateScore(colonyID: UUID) async throws -> HiveHealthScore
}
