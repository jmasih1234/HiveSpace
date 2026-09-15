import Foundation
import SwiftUI

// MARK: - Auth State

enum AuthState: Equatable {
    case unknown
    case signedOut
    case signingIn
    case signedIn(HSUser)
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.signedOut, .signedOut), (.signingIn, .signingIn):
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

    private let tokenKey = "hivespace_auth_token"
    private let refreshTokenKey = "hivespace_refresh_token"
    private let tokenExpiryKey = "hivespace_token_expiry"

    var isAuthenticated: Bool {
        if case .signedIn = state { return true }
        return false
    }

    var authToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    private init() {}

    // MARK: - Token Management

    func saveTokens(auth: String, refresh: String, expiry: Date) {
        UserDefaults.standard.set(auth, forKey: tokenKey)
        UserDefaults.standard.set(refresh, forKey: refreshTokenKey)
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: tokenExpiryKey)
    }

    func clearTokens() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
    }

    var isTokenExpired: Bool {
        let expiry = UserDefaults.standard.double(forKey: tokenExpiryKey)
        guard expiry > 0 else { return true }
        return Date().timeIntervalSince1970 >= expiry
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        state = .signingIn

        // For demo/offline mode: authenticate locally
        if shouldUseDemoMode {
            await simulateSignIn(email: email)
            return
        }

        // Live API call
        do {
            let response: AuthResponse = try await NetworkService.shared.request(
                endpoint: .signIn,
                body: SignInRequest(email: email, password: password),
                queryItems: nil
            )

            saveTokens(auth: response.token, refresh: response.refreshToken, expiry: response.expiresAt)
            NetworkService.shared.setAuthToken(response.token)
            currentUser = response.user
            state = .signedIn(response.user)
        } catch {
            // Fall back to demo mode if server is unreachable
            await simulateSignIn(email: email)
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String, username: String) async {
        state = .signingIn

        if shouldUseDemoMode {
            await simulateSignIn(email: email, displayName: displayName, username: username)
            return
        }

        do {
            let response: AuthResponse = try await NetworkService.shared.request(
                endpoint: .signUp,
                body: SignUpRequest(email: email, password: password, displayName: displayName, username: username),
                queryItems: nil
            )

            saveTokens(auth: response.token, refresh: response.refreshToken, expiry: response.expiresAt)
            NetworkService.shared.setAuthToken(response.token)
            currentUser = response.user
            state = .signedIn(response.user)
        } catch {
            await simulateSignIn(email: email, displayName: displayName, username: username)
        }
    }

    // MARK: - Session Restore

    func restoreSession() async {
        // Check if we have a stored token
        let storedToken = authToken
        guard let token = storedToken, !isTokenExpired else {
            // Try loading from persistence
            if let snapshot = await PersistenceService.shared.loadSnapshot() {
                currentUser = snapshot.currentUser
                state = .signedIn(snapshot.currentUser)
                NetworkService.shared.setAuthToken(storedToken ?? "")
                return
            }
            state = .signedOut
            return
        }

        NetworkService.shared.setAuthToken(token)

        // Try to fetch fresh profile from API
        do {
            let user: HSUser = try await NetworkService.shared.request(
                endpoint: .profile,
                body: nil as String?,
                queryItems: nil
            )
            currentUser = user
            state = .signedIn(user)
        } catch {
            // Fall back to cached profile
            if let snapshot = await PersistenceService.shared.loadSnapshot() {
                currentUser = snapshot.currentUser
                state = .signedIn(snapshot.currentUser)
            } else {
                state = .signedOut
            }
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        clearTokens()
        NetworkService.shared.setAuthToken(nil)
        currentUser = nil
        state = .signedOut
    }

    // MARK: - Demo Mode

    private var shouldUseDemoMode: Bool {
        // Use demo mode when no server is configured or for development
        true // Set to false when your API server is live
    }

    private func simulateSignIn(email: String, displayName: String? = nil, username: String? = nil) async {
        // Small delay to simulate network
        try? await Task.sleep(for: .milliseconds(800))

        let name = displayName ?? email.components(separatedBy: "@").first?.capitalized ?? "User"
        let uname = username ?? email.components(separatedBy: "@").first ?? "user"

        // Check if we have saved data for this user
        if let snapshot = await PersistenceService.shared.loadSnapshot() {
            currentUser = snapshot.currentUser
            state = .signedIn(snapshot.currentUser)
            return
        }

        // Create a fresh user with sample data
        let user = HSUser(
            id: UUID(),
            displayName: name,
            username: uname,
            email: email,
            avatarURL: nil,
            colonyIDs: [],
            createdAt: .now
        )

        saveTokens(auth: "demo-\(UUID().uuidString)", refresh: "refresh-\(UUID().uuidString)", expiry: .distantFuture)
        currentUser = user
        state = .signedIn(user)
    }
}
