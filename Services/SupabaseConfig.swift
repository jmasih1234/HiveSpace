import Foundation

// MARK: - Supabase Environment Configuration

/// Provides Supabase credentials at runtime.
///
/// **Debug builds:** Reads from Xcode scheme environment variables.
/// If not set, the app enters demo mode (previews, offline development).
///
/// **Release builds:** Reads from compiled constants in `SupabaseReleaseKeys.swift`.
/// That file is gitignored — create it from the example before archiving.
/// If the file is missing, the Release build will fail at compile time.
///
/// The anon key is a PUBLIC publishable key. Never include the service-role key.
enum SupabaseEnvironment {

    static var url: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        #else
        return SupabaseReleaseKeys.url
        #endif
    }

    static var anonKey: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        #else
        return SupabaseReleaseKeys.anonKey
        #endif
    }

    /// Returns true only when both URL and key are set to real values.
    static var isConfigured: Bool {
        let u = url
        let k = anonKey
        return !u.isEmpty
            && !k.isEmpty
            && u != "https://your-project.supabase.co"
            && k != "your-anon-key"
    }
}
