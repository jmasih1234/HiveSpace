import Foundation

// MARK: - Repository Container
//
// Central dependency-injection point. Injectable for tests.
// When Supabase is configured, auth/profile/colony use live implementations.
// Otherwise (DEBUG only), everything falls back to mocks.

@MainActor
final class RepositoryContainer {
    /// The app-wide default instance. Use `configure(with:)` for tests.
    static var shared = RepositoryContainer.makeDefault()

    let auth: any AuthRepository
    let profile: any ProfileRepository
    let colony: any ColonyRepository
    let tasks: any TaskRepository
    let expenses: any ExpenseRepository
    let activity: any ActivityRepository
    let healthScore: any HealthScoreRepository

    init(
        auth: any AuthRepository,
        profile: any ProfileRepository,
        colony: any ColonyRepository,
        tasks: any TaskRepository,
        expenses: any ExpenseRepository,
        activity: any ActivityRepository,
        healthScore: any HealthScoreRepository
    ) {
        self.auth = auth
        self.profile = profile
        self.colony = colony
        self.tasks = tasks
        self.expenses = expenses
        self.activity = activity
        self.healthScore = healthScore
    }

    /// Replace the shared container (for tests).
    static func configure(with container: RepositoryContainer) {
        shared = container
    }

    /// Build the default container from the current Supabase configuration.
    static func makeDefault() -> RepositoryContainer {
        if let client = SupabaseClientProvider.shared.client {
            return RepositoryContainer(
                auth: SupabaseAuthRepository(client: client),
                profile: SupabaseProfileRepository(client: client),
                colony: SupabaseColonyRepository(client: client),
                tasks: MockTaskRepository(),
                expenses: MockExpenseRepository(),
                activity: MockActivityRepository(),
                healthScore: MockHealthScoreRepository()
            )
        } else {
            return RepositoryContainer(
                auth: MockAuthRepository(),
                profile: MockProfileRepository(),
                colony: MockColonyRepository(),
                tasks: MockTaskRepository(),
                expenses: MockExpenseRepository(),
                activity: MockActivityRepository(),
                healthScore: MockHealthScoreRepository()
            )
        }
    }
}
