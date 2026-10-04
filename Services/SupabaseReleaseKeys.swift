// SupabaseReleaseKeys.swift
//
// This file provides Supabase credentials for Release (TestFlight / App Store) builds.
// It is gitignored — create it by copying SupabaseReleaseKeys.example and filling
// in your Supabase project's URL and public anon key.
//
// The anon key is a PUBLIC publishable key. Never include the service-role key.
//
// If this file is missing, Release builds will fail with a clear compile error:
//   "Cannot find 'SupabaseReleaseKeys' in scope"

#if !DEBUG
enum SupabaseReleaseKeys {
    static let url = "https://your-project.supabase.co"
    static let anonKey = "your-anon-key"
}
#endif
