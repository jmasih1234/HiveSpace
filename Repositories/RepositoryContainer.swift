import Foundation

// MARK: - Repository Container
//
// Central dependency-injection point. When Supabase is configured,
// auth/profile/colony use live Supabase implementations. Otherwise
// (and for DEBUG previews), everything falls back to mocks.
//
// HiveSpaceStore migration plan:
// The store remains the single @Published state holder that views observe.
// Repositories replace the *data-access layer*. In subsequent phases,
// the store's mutating methods will call repository methods and update
// their @Published properties from the responses.

@MainActor
final class RepositoryContainer {
    static let shared = RepositoryContainer()

    let auth: any AuthRepository
    let profile: any ProfileRepository
    let colony: any ColonyRepository
    let tasks: any TaskRepository
    let expenses: any ExpenseRepository
    let activity: any ActivityRepository
    let healthScore: any HealthScoreRepository

    private init() {
        if let client = SupabaseClientProvider.shared.client {
            auth = SupabaseAuthRepository(client: client)
            profile = SupabaseProfileRepository(client: client)
            colony = SupabaseColonyRepository(client: client)
        } else {
            auth = MockAuthRepository()
            profile = MockProfileRepository()
            colony = MockColonyRepository()
        }

        // Tasks, expenses, activity, healthScore: still mocks until Phase 3+
        tasks = MockTaskRepository()
        expenses = MockExpenseRepository()
        activity = MockActivityRepository()
        healthScore = MockHealthScoreRepository()
    }
}
