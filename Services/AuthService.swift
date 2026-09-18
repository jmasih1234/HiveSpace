import Foundation
import SwiftUI
import Supabase

// MARK: - Auth State

enum AuthState: Equatable {
    case unknown
    case signedOut
    case signingIn
    case signedIn(HSUser)
    case needsProfile          // signed in but profile incomplete
    case needsEmailVerification
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.signedOut, .signedOut), (.signingIn, .signingIn),
             (.needsProfile, .needsProfile), (.needsEmailVerification, .needsEmailVerification):
            return true
        case (.signedIn(let a), .signedIn(let b)):
            return a.id == b.id
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var state: AuthState = .unknown
    @Published var currentUser: HSUser?

    private var supabase: SupabaseClient? {
        SupabaseClientProvider.shared.client
    }

    var isAuthenticated: Bool {
        if case .signedIn = state { return true }
        return false
    }

    var isDemoMode: Bool {
        !SupabaseEnvironment.isConfigured
    }

    private init() {}

    // MARK: - Session Restore

    func restoreSession() async {
        guard let client = supabase else {
            // No Supabase configured — fall back to demo
            state = .signedOut
            return
        }

        do {
            let session = try await client.auth.session
            let profile = try await fetchProfile(userID: session.user.id)
            if profile.displayName.isEmpty {
                state = .needsProfile
            } else {
                currentUser = profile
                state = .signedIn(profile)
            }
        } catch {
            state = .signedOut
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        guard let client = supabase else {
            await demoSignIn(email: email)
            return
        }

        state = .signingIn

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            let profile = try await fetchProfile(userID: session.user.id)
            if profile.displayName.isEmpty {
                state = .needsProfile
            } else {
                currentUser = profile
                state = .signedIn(profile)
            }
        } catch {
            state = .error(friendlyError(error))
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String, username: String) async {
        guard let client = supabase else {
            await demoSignIn(email: email, displayName: displayName, username: username)
            return
        }

        state = .signingIn

        do {
            let result = try await client.auth.signUp(
                email: email,
                password: password,
                data: [
                    "display_name": .string(displayName),
                    "username": .string(username)
                ]
            )

            // Check if email confirmation is required
            if result.session == nil {
                state = .needsEmailVerification
                return
            }

            let profile = try await fetchProfile(userID: result.user.id)
            currentUser = profile
            state = .signedIn(profile)
        } catch {
            state = .error(friendlyError(error))
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        if let client = supabase {
            try? await client.auth.signOut()
        }
        currentUser = nil
        state = .signedOut
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        guard let client = supabase else {
            throw AuthError.demoMode
        }
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Profile Fetch

    func fetchProfile(userID: UUID) async throws -> HSUser {
        guard let client = supabase else {
            throw AuthError.demoMode
        }

        struct ProfileRow: Decodable {
            let id: UUID
            let display_name: String
            let username: String
            let email: String
            let avatar_url: String?
            let created_at: String
        }

        let row: ProfileRow = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID.uuidString)
            .single()
            .execute()
            .value

        return HSUser(
            id: row.id,
            displayName: row.display_name,
            username: row.username,
            email: row.email,
            avatarURL: row.avatar_url,
            colonyIDs: [],
            createdAt: ISO8601DateFormatter().date(from: row.created_at) ?? .now
        )
    }

    // MARK: - Update Profile

    func updateProfile(displayName: String, username: String) async throws {
        guard let client = supabase else { return }
        guard let userID = try? await client.auth.session.user.id else { return }

        struct ProfileUpdate: Encodable {
            let display_name: String
            let username: String
        }

        try await client
            .from("profiles")
            .update(ProfileUpdate(display_name: displayName, username: username))
            .eq("id", value: userID.uuidString)
            .execute()

        let profile = try await fetchProfile(userID: userID)
        currentUser = profile
        state = .signedIn(profile)
    }

    // MARK: - Demo Mode (DEBUG previews + unconfigured environments)

    private func demoSignIn(email: String, displayName: String? = nil, username: String? = nil) async {
        state = .signingIn
        try? await Task.sleep(for: .milliseconds(500))

        let name = displayName ?? email.components(separatedBy: "@").first?.capitalized ?? "User"
        let uname = username ?? email.components(separatedBy: "@").first ?? "user"

        let user = HSUser(
            id: UUID(),
            displayName: name,
            username: uname,
            email: email,
            avatarURL: nil,
            colonyIDs: [],
            createdAt: .now
        )
        currentUser = user
        state = .signedIn(user)
    }

    // MARK: - Error Mapping

    private func friendlyError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login") || message.contains("invalid_credentials") {
            return "Incorrect email or password."
        }
        if message.contains("email not confirmed") {
            return "Please check your inbox and confirm your email first."
        }
        if message.contains("user already registered") || message.contains("already been registered") {
            return "An account with that email already exists. Try signing in."
        }
        if message.contains("password") && message.contains("short") {
            return "Password must be at least 6 characters."
        }
        if message.contains("rate limit") || message.contains("too many") {
            return "Too many attempts. Please wait a moment and try again."
        }
        if message.contains("network") || message.contains("offline") || message.contains("connection") {
            return "No internet connection. Check your network and try again."
        }
        return "Something went wrong: \(error.localizedDescription)"
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case demoMode
    case notAuthenticated
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .demoMode: return "Supabase is not configured. Running in demo mode."
        case .notAuthenticated: return "You must be signed in."
        case .profileNotFound: return "Profile not found."
        }
    }
}
