import Foundation
import Supabase

// MARK: - Supabase Auth Repository

struct SupabaseAuthRepository: AuthRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func signIn(email: String, password: String) async throws -> UUID {
        let session = try await client.auth.signIn(email: email, password: password)
        return session.user.id
    }

    func signUp(email: String, password: String, displayName: String, username: String) async throws -> UUID? {
        let result = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "display_name": .string(displayName),
                "username": .string(username)
            ]
        )
        // nil session means email confirmation is required
        if result.session == nil { return nil }
        return result.user.id
    }

    func restoreSession() async throws -> UUID? {
        let session = try await client.auth.session
        return session.user.id
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
}

// MARK: - Profile Row DTO

/// Maps snake_case database columns to the app's HSUser model.
struct ProfileRow: Decodable, Sendable {
    let id: UUID
    let display_name: String
    let username: String
    let email: String
    let avatar_url: String?
    let created_at: String

    func toHSUser() -> HSUser {
        HSUser(
            id: id,
            displayName: display_name,
            username: username,
            email: email,
            avatarURL: avatar_url,
            colonyIDs: [],
            createdAt: ISO8601DateFormatter().date(from: created_at) ?? .now
        )
    }
}
