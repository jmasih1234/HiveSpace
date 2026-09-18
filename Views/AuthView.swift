import SwiftUI

// MARK: - Auth Mode

private enum AuthMode {
    case signIn
    case signUp
    case forgotPassword
}

// MARK: - Auth View

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var username = ""
    @State private var isBusy = false
    @State private var infoMessage: String?
    @State private var resetSent = false

    private let cream = Color(red: 0.98, green: 0.97, blue: 0.95)
    private let plum  = Color(red: 0.24, green: 0.10, blue: 0.36)
    private let rose  = Color(red: 0.77, green: 0.33, blue: 0.48)
    private let muted = Color(red: 0.62, green: 0.56, blue: 0.67)

    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                // Logo
                VStack(spacing: 22) {
                    HiveLogoMark(size: 110, shadowOpacity: 0.1)
                    VStack(spacing: 8) {
                        BrandName(fontSize: 50, plum: plum, rose: rose)
                        Text("YOUR COLONY, YOUR FLOW")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tracking(2.8)
                            .foregroundStyle(muted)
                    }
                }
                .padding(.top, 48)

                // Error banner
                if case .error(let msg) = authService.state {
                    Text(msg)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(rose.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 24)
                }

                // Verification banner
                if authService.state == .needsEmailVerification {
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 32))
                            .foregroundStyle(plum)
                        Text("Check your email")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(plum)
                        Text("We sent a verification link to **\(email)**. Tap the link then come back and sign in.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(muted)
                            .multilineTextAlignment(.center)
                        Button("Back to sign in") {
                            mode = .signIn
                            authService.state = .signedOut
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(rose)
                        .padding(.top, 4)
                    }
                    .padding(28)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: plum.opacity(0.08), radius: 20, y: 10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                } else {
                    // Auth form card
                    formCard
                }
            }
        }
        .background(cream.ignoresSafeArea())
    }

    // MARK: - Form Card

    @ViewBuilder
    private var formCard: some View {
        VStack(spacing: 18) {
            // Subtitle
            Text(subtitleText)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(muted)

            VStack(spacing: 14) {
                if mode == .signUp {
                    AuthField(
                        title: "Display name",
                        systemImage: "person.fill",
                        text: $displayName,
                        textContentType: .name,
                        keyboardType: .default,
                        iconColor: rose
                    )
                    AuthField(
                        title: "Username",
                        systemImage: "at",
                        text: $username,
                        textContentType: .username,
                        keyboardType: .default,
                        iconColor: rose
                    )
                }

                AuthField(
                    title: "Email",
                    systemImage: "envelope.fill",
                    text: $email,
                    textContentType: .emailAddress,
                    keyboardType: .emailAddress,
                    iconColor: rose
                )

                if mode != .forgotPassword {
                    AuthSecureField(
                        title: "Password",
                        systemImage: "lock.fill",
                        text: $password,
                        iconColor: rose
                    )
                }
            }

            // Info message
            if let info = infoMessage {
                Text(info)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Reset sent confirmation
            if resetSent {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HiveTheme.green)
                    Text("Password reset email sent!")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Primary button
            Button(action: performAction) {
                HStack(spacing: 10) {
                    if isBusy {
                        ProgressView().tint(.white)
                    }
                    Text(primaryButtonText)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? plum : plum.opacity(0.55))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .disabled(!canSubmit || isBusy)

            // Secondary links
            secondaryLinks
        }
        .padding(28)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(plum.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: plum.opacity(0.08), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Secondary Links

    @ViewBuilder
    private var secondaryLinks: some View {
        switch mode {
        case .signIn:
            HStack {
                Button("Create account") {
                    withAnimation { mode = .signUp }
                    clearError()
                }
                Spacer()
                Button("Forgot password?") {
                    withAnimation { mode = .forgotPassword }
                    clearError()
                }
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(rose)

        case .signUp:
            Button("Already have an account? Sign in") {
                withAnimation { mode = .signIn }
                clearError()
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(rose)

        case .forgotPassword:
            Button("Back to sign in") {
                withAnimation { mode = .signIn }
                clearError()
                resetSent = false
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(rose)
        }
    }

    // MARK: - Logic

    private var subtitleText: String {
        switch mode {
        case .signIn: "Sign in to manage chores, tasks, and shared expenses."
        case .signUp: "Create your account to start a colony."
        case .forgotPassword: "Enter your email and we'll send a reset link."
        }
    }

    private var primaryButtonText: String {
        if isBusy {
            return switch mode {
            case .signIn: "Signing In..."
            case .signUp: "Creating Account..."
            case .forgotPassword: "Sending..."
            }
        }
        return switch mode {
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        case .forgotPassword: "Send Reset Link"
        }
    }

    private var canSubmit: Bool {
        let emailOK = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch mode {
        case .signIn:
            return emailOK && !password.isEmpty
        case .signUp:
            return emailOK && !password.isEmpty && !displayName.isEmpty && !username.isEmpty
        case .forgotPassword:
            return emailOK
        }
    }

    private func performAction() {
        guard !isBusy else { return }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            authService.state = .error("Enter a valid email address.")
            return
        }

        if mode != .forgotPassword {
            guard password.count >= 6 else {
                authService.state = .error("Password must be at least 6 characters.")
                return
            }
        }

        if mode == .signUp {
            guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                authService.state = .error("Username is required.")
                return
            }
        }

        clearError()
        isBusy = true

        Task {
            defer { isBusy = false }
            switch mode {
            case .signIn:
                await authService.signIn(email: trimmedEmail, password: password)
            case .signUp:
                let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                await authService.signUp(
                    email: trimmedEmail,
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                    username: trimmedUsername
                )
            case .forgotPassword:
                do {
                    try await authService.resetPassword(email: trimmedEmail)
                    resetSent = true
                } catch {
                    authService.state = .error("Could not send reset email. Check your email address.")
                }
            }
        }
    }

    private func clearError() {
        if case .error = authService.state {
            authService.state = .signedOut
        }
        infoMessage = nil
    }
}

// MARK: - Reusable Field Components

private struct AuthField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    let textContentType: UITextContentType?
    let keyboardType: UIKeyboardType
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(iconColor)
                .frame(width: 18)
            TextField(title, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(iconColor.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct AuthSecureField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(iconColor)
                .frame(width: 18)
            SecureField(title, text: $text)
                .textContentType(.password)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(iconColor.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct BrandName: View {
    let fontSize: CGFloat
    let plum: Color
    let rose: Color

    var body: some View {
        HStack(spacing: 0) {
            Text("Hive")
                .foregroundStyle(plum)
            Text("Space")
                .italic()
                .foregroundStyle(rose)
        }
        .font(.system(size: fontSize, weight: .regular, design: .serif))
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService.shared)
}
