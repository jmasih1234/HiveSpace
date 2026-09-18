import SwiftUI

/// Shown after sign-up when the user's display_name is still empty.
struct ProfileSetupView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var displayName = ""
    @State private var username = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let plum = Color(red: 0.24, green: 0.10, blue: 0.36)
    private let rose = Color(red: 0.77, green: 0.33, blue: 0.48)
    private let muted = Color(red: 0.62, green: 0.56, blue: 0.67)
    private let cream = Color(red: 0.98, green: 0.97, blue: 0.95)

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(rose)
                    Text("Complete Your Profile")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(plum)
                    Text("Choose a name and username your colony mates will see.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(muted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Display Name")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(plum)
                        TextField("Your name", text: $displayName)
                            .textContentType(.name)
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(rose.opacity(0.2), lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(plum)
                        TextField("username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(rose.opacity(0.2), lineWidth: 1)
                            }
                    }
                }
                .padding(.horizontal, 28)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(rose)
                        .padding(.horizontal, 28)
                }

                Button(action: save) {
                    HStack(spacing: 10) {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Saving..." : "Continue")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSubmit ? plum : plum.opacity(0.55))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .disabled(!canSubmit || isSaving)
                .padding(.horizontal, 28)
            }
        }
        .background(cream.ignoresSafeArea())
    }

    private var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            defer { isSaving = false }
            do {
                try await authService.updateProfile(
                    displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                    username: username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                )
            } catch {
                errorMessage = "Could not save profile. Try a different username."
            }
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthService.shared)
}
