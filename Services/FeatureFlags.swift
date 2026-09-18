import Foundation

// MARK: - Feature Flags

/// Controls which modules are active in the current build.
/// MVP features default to `true`. Deferred modules default to `false`
/// and will be enabled as they are integrated with the Supabase backend.
enum FeatureFlags {

    // MARK: MVP — enabled

    /// Email/password authentication via Supabase Auth.
    static let auth = true

    /// User profile viewing and editing.
    static let profiles = true

    /// Colony creation, joining, and member management.
    static let colonies = true

    /// Shared task lists with assignment and priority.
    static let tasks = true

    /// Recurring chore scheduling and rotation.
    static let chores = true

    /// Shared expenses with split calculations.
    static let expenses = true

    /// Settlement tracking (mark debts as paid).
    static let settlements = true

    /// Colony activity feed.
    static let activityFeed = true

    /// Hive Health score calculation.
    static let hiveHealth = true

    // MARK: Deferred — behind flags

    /// Voice/video calling.
    static let calls = false

    /// Group trip planning (itinerary, packing, polls).
    static let trips = false

    /// Shared documents and workspace.
    static let documents = false

    /// Availability polling / scheduling.
    static let availability = false

    /// Enterprise team workspace features.
    static let enterpriseWorkspace = false

    /// Advanced messaging (reactions, threads, attachments).
    static let advancedMessaging = false

    /// Subscription tiers and billing.
    static let subscriptions = false

    /// AI-powered suggestions and summaries.
    static let ai = false
}
