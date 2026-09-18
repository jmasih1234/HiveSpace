import Foundation
import Supabase

// MARK: - Supabase Profile Repository

struct SupabaseProfileRepository: ProfileRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchProfile(userID: UUID) async throws -> HSUser {
        let row: ProfileRow = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID.uuidString)
            .single()
            .execute()
            .value

        return row.toHSUser()
    }

    func updateProfile(_ user: HSUser) async throws -> HSUser {
        struct ProfileUpdate: Encodable {
            let display_name: String
            let username: String
            let avatar_url: String?
        }

        try await client
            .from("profiles")
            .update(ProfileUpdate(
                display_name: user.displayName,
                username: user.username,
                avatar_url: user.avatarURL
            ))
            .eq("id", value: user.id.uuidString)
            .execute()

        return try await fetchProfile(userID: user.id)
    }
}
