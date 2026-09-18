import Foundation
import Supabase

// MARK: - Supabase Client Provider

/// Single point of access for the Supabase client.
/// Returns nil when credentials are not configured, signaling the app
/// should fall back to mock repositories and demo mode.
@MainActor
final class SupabaseClientProvider: Sendable {
    static let shared = SupabaseClientProvider()

    /// The live Supabase client. `nil` when environment is not configured.
    let client: SupabaseClient?

    /// Whether a live backend is available.
    var isLive: Bool { client != nil }

    private init() {
        if SupabaseEnvironment.isConfigured,
           let url = URL(string: SupabaseEnvironment.url) {
            self.client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: SupabaseEnvironment.anonKey
            )
        } else {
            self.client = nil
        }
    }
}
