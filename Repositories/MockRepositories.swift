import Foundation

// MARK: - Mock Repositories
//
// These implementations back the existing demo experience.
// They operate entirely in-memory using the sample data already
// present in HiveSpaceStore.sample. When Supabase repositories
// are introduced in Phase 2+, these mocks remain available for
// previews, tests, and offline fallback.

// MARK: Mock Auth

struct MockAuthRepository: AuthRepository {
    func signIn(email: String, password: String) async throws -> HSUser {
        try await Task.sleep(for: .milliseconds(500))
        return makeDemoUser(email: email)
    }

    func signUp(email: String, password: String, displayName: String, username: String) async throws -> HSUser {
        try await Task.sleep(for: .milliseconds(500))
        return HSUser(
            id: UUID(),
            displayName: displayName,
            username: username,
            email: email,
            avatarURL: nil,
            colonyIDs: [],
            createdAt: .now
        )
    }

    func restoreSession() async throws -> HSUser? {
        nil
    }

    func signOut() async throws {}

    func resetPassword(email: String) async throws {}

    private func makeDemoUser(email: String) -> HSUser {
        let name = email.components(separatedBy: "@").first?.capitalized ?? "User"
        let uname = email.components(separatedBy: "@").first ?? "user"
        return HSUser(
            id: UUID(),
            displayName: name,
            username: uname,
            email: email,
            avatarURL: nil,
            colonyIDs: [],
            createdAt: .now
        )
    }
}

// MARK: Mock Profile

struct MockProfileRepository: ProfileRepository {
    func fetchProfile(userID: UUID) async throws -> HSUser {
        HSUser(
            id: userID,
            displayName: "Demo User",
            username: "demo",
            email: "demo@hivespace.app",
            avatarURL: nil,
            colonyIDs: [],
            createdAt: .now
        )
    }

    func updateProfile(_ user: HSUser) async throws -> HSUser {
        user
    }
}

// MARK: Mock Colony

struct MockColonyRepository: ColonyRepository {
    func fetchColonies(for userID: UUID) async throws -> [Colony] {
        []
    }

    func fetchColony(id: UUID) async throws -> Colony {
        throw RepositoryError.notFound
    }

    func createColony(_ colony: Colony) async throws -> Colony {
        colony
    }

    func updateColony(_ colony: Colony) async throws -> Colony {
        colony
    }

    func joinColony(code: String, userID: UUID) async throws -> Colony {
        throw RepositoryError.notFound
    }

    func leaveColony(colonyID: UUID, userID: UUID) async throws {}

    func updateMemberRole(colonyID: UUID, memberID: UUID, role: MemberRole) async throws {}

    func removeMember(colonyID: UUID, memberID: UUID) async throws {}

    func fetchJoinRequests(colonyID: UUID) async throws -> [ColonyJoinRequest] {
        []
    }

    func resolveJoinRequest(requestID: UUID, approved: Bool) async throws {}
}

// MARK: Mock Task

struct MockTaskRepository: TaskRepository {
    func fetchTasks(colonyID: UUID) async throws -> [HSTask] {
        []
    }

    func createTask(_ task: HSTask, colonyID: UUID) async throws -> HSTask {
        task
    }

    func updateTask(_ task: HSTask) async throws -> HSTask {
        task
    }

    func deleteTask(id: UUID) async throws {}

    func fetchChoreWheels(colonyID: UUID) async throws -> [ChoreWheel] {
        []
    }

    func createChoreWheel(_ wheel: ChoreWheel, colonyID: UUID) async throws -> ChoreWheel {
        wheel
    }

    func advanceChoreWheel(id: UUID) async throws -> ChoreWheel {
        throw RepositoryError.notFound
    }
}

// MARK: Mock Expense

struct MockExpenseRepository: ExpenseRepository {
    func fetchExpenses(colonyID: UUID) async throws -> [Expense] {
        []
    }

    func createExpense(_ expense: Expense, colonyID: UUID) async throws -> Expense {
        expense
    }

    func updateExpense(_ expense: Expense) async throws -> Expense {
        expense
    }

    func deleteExpense(id: UUID) async throws {}

    func fetchSettlementRequests(colonyID: UUID) async throws -> [SettlementRequest] {
        []
    }

    func createSettlementRequest(_ request: SettlementRequest) async throws -> SettlementRequest {
        request
    }

    func resolveSettlementRequest(id: UUID, accepted: Bool) async throws {}

    func fetchEventSplits(colonyID: UUID) async throws -> [EventSplit] {
        []
    }
}

// MARK: Mock Activity

struct MockActivityRepository: ActivityRepository {
    func fetchEvents(colonyID: UUID, limit: Int) async throws -> [ActivityEvent] {
        []
    }

    func postEvent(_ event: ActivityEvent, colonyID: UUID) async throws -> ActivityEvent {
        event
    }
}

// MARK: Mock Health Score

struct MockHealthScoreRepository: HealthScoreRepository {
    func fetchScore(colonyID: UUID) async throws -> HiveHealthScore {
        HiveHealthScore(
            colonyID: colonyID,
            score: 0,
            grade: .dormant,
            lastUpdated: .now,
            taskCompletionRate: 0,
            balanceSettlementRate: 0,
            memberActivityRate: 0,
            choreComplianceRate: 0
        )
    }

    func recalculateScore(colonyID: UUID) async throws -> HiveHealthScore {
        try await fetchScore(colonyID: colonyID)
    }
}

// MARK: - Repository Error

enum RepositoryError: LocalizedError {
    case notFound
    case unauthorized
    case serverError(String)
    case offline

    var errorDescription: String? {
        switch self {
        case .notFound: return "The requested resource was not found."
        case .unauthorized: return "You are not authorized to perform this action."
        case .serverError(let msg): return "Server error: \(msg)"
        case .offline: return "No network connection."
        }
    }
}
