import Foundation
import SwiftUI

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

/// Coordinates authentication state. All Supabase operations flow through
/// injected AuthRepository and ProfileRepository — no direct Supabase imports.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var state: AuthState = .unknown
    @Published var currentUser: HSUser?

    private var authRepo: any AuthRepository { RepositoryContainer.shared.auth }
    private var profileRepo: any ProfileRepository { RepositoryContainer.shared.profile }

    var isAuthenticated: Bool {
        if case .signedIn = state { return true }
        return false
    }

    var isDemoMode: Bool {
        #if DEBUG
        return !SupabaseEnvironment.isConfigured
        #else
        return false
        #endif
    }

    private init() {}

    // MARK: - Session Restore

    func restoreSession() async {
        guard !isDemoMode else {
            state = .signedOut
            return
        }

        do {
            guard let userID = try await authRepo.restoreSession() else {
                state = .signedOut
                return
            }
            await resolveProfile(userID: userID)
        } catch {
            state = .signedOut
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        guard !isDemoMode else {
            #if DEBUG
            await demoSignIn(email: email)
            #else
            state = .error("Supabase is not configured. Cannot sign in.")
            #endif
            return
        }

        state = .signingIn
        do {
            let userID = try await authRepo.signIn(email: email, password: password)
            await resolveProfile(userID: userID)
        } catch {
            state = .error(friendlyError(error))
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String, username: String) async {
        guard !isDemoMode else {
            #if DEBUG
            await demoSignIn(email: email, displayName: displayName, username: username)
            #else
            state = .error("Supabase is not configured. Cannot sign up.")
            #endif
            return
        }

        state = .signingIn
        do {
            guard let userID = try await authRepo.signUp(
                email: email, password: password,
                displayName: displayName, username: username
            ) else {
                // nil means email confirmation is required
                state = .needsEmailVerification
                return
            }
            await resolveProfile(userID: userID)
        } catch {
            state = .error(friendlyError(error))
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authRepo.signOut()
        } catch {
            // Sign-out failed server-side; still clear local state
        }
        currentUser = nil
        state = .signedOut
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await authRepo.resetPassword(email: email)
    }

    // MARK: - Update Profile

    func updateProfile(displayName: String, username: String) async throws {
        guard var user = currentUser else {
            throw AuthError.notAuthenticated
        }
        user.displayName = displayName
        user.username = username
        let updated = try await profileRepo.updateProfile(user)
        currentUser = updated
        state = .signedIn(updated)
    }

    // MARK: - Profile Resolution

    /// After auth succeeds, fetch the profile and route to the correct state.
    /// Handles the profile-trigger race condition with a brief retry.
    private func resolveProfile(userID: UUID) async {
        do {
            let profile = try await fetchProfileWithRetry(userID: userID)
            if profile.displayName.isEmpty || profile.username.isEmpty {
                currentUser = profile
                state = .needsProfile
            } else {
                currentUser = profile
                state = .signedIn(profile)
            }
        } catch {
            // Profile not found — may need setup
            state = .needsProfile
        }
    }

    /// The `handle_new_user` trigger may not have completed when we first fetch.
    /// Retry once after a short delay.
    private func fetchProfileWithRetry(userID: UUID) async throws -> HSUser {
        do {
            return try await profileRepo.fetchProfile(userID: userID)
        } catch {
            try await Task.sleep(for: .milliseconds(800))
            return try await profileRepo.fetchProfile(userID: userID)
        }
    }

    // MARK: - Demo Mode (DEBUG previews only)

    #if DEBUG
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
    #endif

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
        if message.contains("duplicate") && message.contains("username") {
            return "That username is already taken. Try a different one."
        }
        return "Something went wrong: \(error.localizedDescription)"
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case demoMode
    case notAuthenticated
    case profileNotFound
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .demoMode: return "Supabase is not configured. Running in demo mode."
        case .notAuthenticated: return "You must be signed in."
        case .profileNotFound: return "Profile not found."
        case .notConfigured: return "Backend is not configured."
        }
    }
}
