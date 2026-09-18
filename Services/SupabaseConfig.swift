import Foundation

// MARK: - Supabase Environment Configuration

/// Loads Supabase credentials from Xcode scheme environment variables.
///
/// To configure for development:
/// 1. In Xcode, go to Product > Scheme > Edit Scheme > Run > Environment Variables
/// 2. Add `SUPABASE_URL` with your project URL (e.g. https://abc123.supabase.co)
/// 3. Add `SUPABASE_ANON_KEY` with your project's public anon/publishable key
///
/// These values are stored in xcuserdata/ which is already gitignored,
/// so your credentials never enter source control.
///
/// See `supabase-config.example.json` in the project root for reference values.
enum SupabaseEnvironment {
    static var url: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    }

    static var anonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    }

    /// Returns true only when both URL and key are set to real values.
    static var isConfigured: Bool {
        let u = url
        let k = anonKey
        return !u.isEmpty
            && !k.isEmpty
            && u != "https://your-project.supabase.co"
    }
}
