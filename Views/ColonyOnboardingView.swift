import SwiftUI

/// Shown when a signed-in user has no colonies. Lets them create or join one.
struct ColonyOnboardingView: View {
    @EnvironmentObject private var authService: AuthService
    var onColonyReady: (Colony) -> Void

    @State private var mode: OnboardingMode = .choose
    @State private var colonyName = ""
    @State private var colonyEmoji = "🐝"
    @State private var joinCode = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    private let plum  = Color(red: 0.24, green: 0.10, blue: 0.36)
    private let rose  = Color(red: 0.77, green: 0.33, blue: 0.48)
    private let muted = Color(red: 0.62, green: 0.56, blue: 0.67)
    private let cream = Color(red: 0.98, green: 0.97, blue: 0.95)

    private enum OnboardingMode { case choose, create, join }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    HiveLogoMark(size: 70, shadowOpacity: 0.1)
                    Text("Welcome to HiveSpace")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(plum)
                    if let user = authService.currentUser {
                        Text("Hi, \(user.displayName)!")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(muted)
                    }
                }
                .padding(.top, 50)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(rose.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 24)
                }

                switch mode {
                case .choose:
                    chooseView
                case .create:
                    createView
                case .join:
                    joinView
                }
            }
        }
        .background(cream.ignoresSafeArea())
    }

    // MARK: - Choose Mode

    @ViewBuilder
    private var chooseView: some View {
        VStack(spacing: 16) {
            Text("Start by creating a colony or joining one with an invite code.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                withAnimation { mode = .create }
            } label: {
                onboardingCard(
                    icon: "plus.circle.fill",
                    title: "Create a Colony",
                    subtitle: "Set up a new shared space for your group"
                )
            }

            Button {
                withAnimation { mode = .join }
            } label: {
                onboardingCard(
                    icon: "person.badge.key.fill",
                    title: "Join a Colony",
                    subtitle: "Enter an invite code from a friend"
                )
            }

            Button("Sign out") {
                Task { await authService.signOut() }
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(muted)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Create Colony

    @ViewBuilder
    private var createView: some View {
        VStack(spacing: 18) {
            Text("Name Your Colony")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(plum)

            TextField("Colony name", text: $colonyName)
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(rose.opacity(0.2), lineWidth: 1)
                }

            Button(action: createColony) {
                HStack(spacing: 10) {
                    if isBusy { ProgressView().tint(.white) }
                    Text(isBusy ? "Creating..." : "Create Colony")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(!colonyName.isEmpty ? plum : plum.opacity(0.55))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .disabled(colonyName.isEmpty || isBusy)

            Button("Back") { withAnimation { mode = .choose }; errorMessage = nil }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(rose)
        }
        .padding(28)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: plum.opacity(0.08), radius: 20, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Join Colony

    @ViewBuilder
    private var joinView: some View {
        VStack(spacing: 18) {
            Text("Enter Invite Code")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(plum)

            TextField("6-character code", text: $joinCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(rose.opacity(0.2), lineWidth: 1)
                }
                .onChange(of: joinCode) { newValue in
                    if newValue.count > 6 {
                        joinCode = String(newValue.prefix(6))
                    }
                }

            Button(action: joinColony) {
                HStack(spacing: 10) {
                    if isBusy { ProgressView().tint(.white) }
                    Text(isBusy ? "Joining..." : "Join Colony")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(joinCode.count == 6 ? plum : plum.opacity(0.55))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .disabled(joinCode.count != 6 || isBusy)

            Button("Back") { withAnimation { mode = .choose }; errorMessage = nil }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(rose)
        }
        .padding(28)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: plum.opacity(0.08), radius: 20, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func createColony() {
        guard let user = authService.currentUser else { return }
        isBusy = true
        errorMessage = nil
        Task {
            defer { isBusy = false }
            do {
                let colony = Colony(
                    id: UUID(),
                    name: colonyName.trimmingCharacters(in: .whitespacesAndNewlines),
                    emoji: colonyEmoji,
                    description: nil,
                    joinCode: "",
                    createdByID: user.id,
                    createdAt: .now,
                    type: .roommates,
                    members: [],
                    settings: ColonySettings(
                        isPublic: false,
                        allowGuestView: false,
                        defaultSplitMethod: .equal,
                        semesterMode: false,
                        nudgesEnabled: true,
                        currencyCode: "USD"
                    )
                )
                let created = try await RepositoryContainer.shared.colony.createColony(colony)
                await MainActor.run { onColonyReady(created) }
            } catch {
                errorMessage = "Could not create colony: \(error.localizedDescription)"
            }
        }
    }

    private func joinColony() {
        guard let user = authService.currentUser else { return }
        isBusy = true
        errorMessage = nil
        Task {
            defer { isBusy = false }
            do {
                let colony = try await RepositoryContainer.shared.colony.joinColony(
                    code: joinCode.trimmingCharacters(in: .whitespacesAndNewlines),
                    userID: user.id
                )
                await MainActor.run { onColonyReady(colony) }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Card Helper

    private func onboardingCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(rose)
                .frame(width: 50, height: 50)
                .background(rose.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(plum)
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(muted.opacity(0.5))
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(plum.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: plum.opacity(0.05), radius: 10, y: 4)
    }
}

#Preview {
    ColonyOnboardingView(onColonyReady: { _ in })
        .environmentObject(AuthService.shared)
}
