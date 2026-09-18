import SwiftUI

// MARK: - App Route

/// Determines which screen the user sees after session check.
enum AppRoute: Equatable {
    case loading
    case auth                  // Not signed in
    case profileSetup          // Signed in but profile incomplete
    case colonyOnboarding      // Signed in, profile done, no colony
    case main(Colony)          // Fully onboarded

    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.auth, .auth),
             (.profileSetup, .profileSetup),
             (.colonyOnboarding, .colonyOnboarding):
            return true
        case (.main(let a), .main(let b)):
            return a.id == b.id
        default:
            return false
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @State private var route: AppRoute = .loading
    @State private var store: HiveSpaceStore?
    @State private var toastMessage: String?

    var body: some View {
        ZStack {
            switch route {
            case .loading:
                LaunchScreen()

            case .auth:
                AuthView()
                    .environmentObject(authService)
                    .transition(.opacity)

            case .profileSetup:
                ProfileSetupView()
                    .environmentObject(authService)
                    .transition(.opacity)

            case .colonyOnboarding:
                ColonyOnboardingView(onColonyReady: { colony in
                    enterMainApp(colony: colony)
                })
                .environmentObject(authService)
                .transition(.opacity)

            case .main:
                if let store {
                    AppShellView(onSignOut: {
                        Task { await signOut() }
                    })
                    .environmentObject(store)
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: route)
        .overlay(alignment: .top) {
            if let toast = toastMessage {
                ToastView(message: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
            }
        }
        .animation(.spring(response: 0.4), value: toastMessage)
        .onAppear { startSessionCheck() }
        .onChange(of: authService.state) { newState in
            handleAuthStateChange(newState)
        }
    }

    // MARK: - Session Lifecycle

    private func startSessionCheck() {
        // Safety fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if route == .loading { route = .auth }
        }

        if authService.isDemoMode {
            // Demo mode: go straight to auth (sample data loaded on sign-in)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                route = .auth
            }
            return
        }

        Task {
            await authService.restoreSession()
            // handleAuthStateChange will route from here
            if route == .loading {
                route = .auth
            }
        }
    }

    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .signedIn(let user):
            // Check if user has colonies
            Task {
                if authService.isDemoMode {
                    // Demo: load sample store
                    enterDemoMode(user: user)
                } else {
                    await loadColonies(for: user)
                }
            }

        case .needsProfile:
            route = .profileSetup

        case .needsEmailVerification:
            // AuthView handles this state internally
            route = .auth

        case .signedOut, .error:
            store = nil
            route = .auth

        case .signingIn, .unknown:
            break
        }
    }

    private func loadColonies(for user: HSUser) async {
        do {
            let colonies = try await RepositoryContainer.shared.colony.fetchColonies(for: user.id)
            if let first = colonies.first {
                enterMainApp(colony: first)
            } else {
                route = .colonyOnboarding
            }
        } catch {
            // If colony fetch fails, show onboarding
            route = .colonyOnboarding
        }
    }

    private func enterMainApp(colony: Colony) {
        guard let user = authService.currentUser else { return }

        let newStore = HiveSpaceStore(
            account: HiveSpaceAccount(
                id: UUID(),
                userID: user.id,
                displayName: user.displayName,
                hive: Hive(
                    id: UUID(),
                    name: colony.name,
                    ownerID: user.id,
                    colonyIDs: [colony.id]
                ),
                subscriptionTier: .free,
                createdAt: user.createdAt
            ),
            allColonies: [colony],
            currentUser: user,
            colony: colony,
            tasks: [],
            expenses: [],
            activityEvents: [],
            healthScore: HiveHealthScore(
                colonyID: colony.id,
                score: 0,
                grade: .dormant,
                lastUpdated: .now,
                taskCompletionRate: 0,
                balanceSettlementRate: 0,
                memberActivityRate: 0,
                choreComplianceRate: 0
            ),
            choreWheels: [],
            nudges: [],
            joinRequests: [],
            settlementRequests: [],
            eventSplits: [],
            semesterSnapshots: [],
            messageChannels: [],
            messages: [],
            directThreads: [],
            callSessions: [],
            callParticipants: [],
            trips: [],
            availabilityPolls: [],
            teamWorkspace: TeamWorkspace(
                id: UUID(), colonyID: colony.id, channels: [],
                documents: [], calendarEvents: []
            )
        )

        store = newStore
        route = .main(colony)
    }

    /// Demo mode: load sample data store directly.
    private func enterDemoMode(user: HSUser) {
        let sampleStore = HiveSpaceStore.sample
        // Overwrite the user fields with the demo sign-in user
        sampleStore.currentUser = user
        store = sampleStore
        route = .main(sampleStore.colony)
    }

    private func signOut() async {
        await authService.signOut()
        store = nil
        route = .auth
    }
}

// MARK: - Launch Screen

struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.9

    var body: some View {
        ZStack {
            HiveTheme.background
                .ignoresSafeArea()
            VStack(spacing: 18) {
                HiveLogoMark(size: 80, shadowOpacity: 0.2)
                    .scaleEffect(scale)
                Text("HiveSpace")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                ProgressView()
                    .tint(HiveTheme.pink)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { scale = 1.0 }
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HiveTheme.green)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    ContentView()
}
