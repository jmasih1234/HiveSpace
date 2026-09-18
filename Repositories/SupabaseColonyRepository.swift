import Foundation
import Supabase

// MARK: - Supabase Colony Repository

struct SupabaseColonyRepository: ColonyRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Read

    func fetchColonies(for userID: UUID) async throws -> [Colony] {
        // Get colony IDs the user belongs to
        struct MembershipRow: Decodable { let colony_id: UUID }
        let memberships: [MembershipRow] = try await client
            .from("colony_members")
            .select("colony_id")
            .eq("user_id", value: userID.uuidString)
            .eq("status", value: "active")
            .execute()
            .value

        if memberships.isEmpty { return [] }

        let colonyIDs = memberships.map(\.colony_id)
        var colonies: [Colony] = []
        for cid in colonyIDs {
            do {
                let colony = try await fetchColony(id: cid)
                colonies.append(colony)
            } catch {
                continue
            }
        }
        return colonies
    }

    func fetchColony(id: UUID) async throws -> Colony {
        let row: ColonyRow = try await client
            .from("colonies")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        let members = try await fetchMembers(colonyID: id)
        let inviteCode = try await fetchInviteCode(colonyID: id)

        return row.toColony(members: members, joinCode: inviteCode)
    }

    // MARK: - Create (via secure RPC function)

    func createColony(_ colony: Colony) async throws -> Colony {
        struct CreateParams: Encodable {
            let p_name: String
            let p_emoji: String
            let p_description: String?
            let p_type: String
        }

        struct CreateResult: Decodable {
            let colony_id: UUID
            let invite_code: String
        }

        let result: CreateResult = try await client
            .rpc("create_colony_with_owner", params: CreateParams(
                p_name: colony.name,
                p_emoji: colony.emoji,
                p_description: colony.description,
                p_type: colony.type.rawValue
            ))
            .single()
            .execute()
            .value

        return try await fetchColony(id: result.colony_id)
    }

    // MARK: - Update

    func updateColony(_ colony: Colony) async throws -> Colony {
        struct ColonyUpdate: Encodable {
            let name: String
            let emoji: String
            let description: String?
            let type: String
        }

        try await client
            .from("colonies")
            .update(ColonyUpdate(
                name: colony.name,
                emoji: colony.emoji,
                description: colony.description,
                type: colony.type.rawValue
            ))
            .eq("id", value: colony.id.uuidString)
            .execute()

        return try await fetchColony(id: colony.id)
    }

    // MARK: - Join (via secure RPC function)

    func joinColony(code: String, userID: UUID) async throws -> Colony {
        struct JoinParams: Encodable {
            let p_code: String
        }

        struct JoinResult: Decodable {
            // The function returns a UUID directly
        }

        let colonyID: UUID = try await client
            .rpc("join_colony_by_code", params: JoinParams(p_code: code))
            .single()
            .execute()
            .value

        return try await fetchColony(id: colonyID)
    }

    // MARK: - Leave

    func leaveColony(colonyID: UUID, userID: UUID) async throws {
        try await client
            .from("colony_members")
            .delete()
            .eq("colony_id", value: colonyID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
    }

    // MARK: - Role Management

    func updateMemberRole(colonyID: UUID, memberID: UUID, role: MemberRole) async throws {
        struct RoleUpdate: Encodable { let role: String }
        let dbRole: String
        switch role {
        case .queen: dbRole = "owner"
        case .worker: dbRole = "member"
        case .guest: dbRole = "member"
        }
        try await client
            .from("colony_members")
            .update(RoleUpdate(role: dbRole))
            .eq("colony_id", value: colonyID.uuidString)
            .eq("user_id", value: memberID.uuidString)
            .execute()
    }

    func removeMember(colonyID: UUID, memberID: UUID) async throws {
        try await client
            .from("colony_members")
            .delete()
            .eq("colony_id", value: colonyID.uuidString)
            .eq("user_id", value: memberID.uuidString)
            .execute()
    }

    // MARK: - Join Requests (placeholder for future use)

    func fetchJoinRequests(colonyID: UUID) async throws -> [ColonyJoinRequest] {
        []
    }

    func resolveJoinRequest(requestID: UUID, approved: Bool) async throws {}

    // MARK: - Private Helpers

    private func fetchMembers(colonyID: UUID) async throws -> [ColonyMember] {
        struct MemberRow: Decodable {
            let id: UUID
            let user_id: UUID
            let role: String
            let status: String
            let joined_at: String
        }

        let rows: [MemberRow] = try await client
            .from("colony_members")
            .select()
            .eq("colony_id", value: colonyID.uuidString)
            .eq("status", value: "active")
            .execute()
            .value

        var members: [ColonyMember] = []
        for row in rows {
            let profile: ProfileRow = try await client
                .from("profiles")
                .select()
                .eq("id", value: row.user_id.uuidString)
                .single()
                .execute()
                .value

            let memberRole: MemberRole = switch row.role {
            case "owner": .queen
            case "admin": .queen
            default: .worker
            }

            members.append(ColonyMember(
                id: row.user_id,
                displayName: profile.display_name,
                username: profile.username,
                avatarURL: profile.avatar_url,
                role: memberRole,
                status: .active,
                joinedAt: ISO8601DateFormatter().date(from: row.joined_at) ?? .now,
                lastActiveAt: nil
            ))
        }
        return members
    }

    private func fetchInviteCode(colonyID: UUID) async throws -> String {
        struct InviteRow: Decodable { let code: String }
        let rows: [InviteRow] = try await client
            .from("colony_invites")
            .select("code")
            .eq("colony_id", value: colonyID.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first?.code ?? ""
    }
}

// MARK: - Colony Row DTO

private struct ColonyRow: Decodable {
    let id: UUID
    let name: String
    let emoji: String
    let description: String?
    let type: String
    let created_by: UUID
    let settings: ColonySettingsDTO?
    let created_at: String

    func toColony(members: [ColonyMember], joinCode: String) -> Colony {
        let colonyType = ColonyType(rawValue: type) ?? .roommates
        let colonySettings = settings?.toColonySettings() ?? ColonySettings(
            isPublic: false,
            allowGuestView: false,
            defaultSplitMethod: .equal,
            semesterMode: false,
            nudgesEnabled: true,
            currencyCode: "USD"
        )

        return Colony(
            id: id,
            name: name,
            emoji: emoji,
            description: description,
            joinCode: joinCode,
            createdByID: created_by,
            createdAt: ISO8601DateFormatter().date(from: created_at) ?? .now,
            type: colonyType,
            members: members,
            settings: colonySettings
        )
    }
}

private struct ColonySettingsDTO: Decodable {
    let is_public: Bool?
    let allow_guest_view: Bool?
    let default_split_method: String?
    let semester_mode: Bool?
    let nudges_enabled: Bool?
    let currency_code: String?

    func toColonySettings() -> ColonySettings {
        ColonySettings(
            isPublic: is_public ?? false,
            allowGuestView: allow_guest_view ?? false,
            defaultSplitMethod: SplitMethod(rawValue: default_split_method ?? "equal") ?? .equal,
            semesterMode: semester_mode ?? false,
            nudgesEnabled: nudges_enabled ?? true,
            currencyCode: currency_code ?? "USD"
        )
    }
}
