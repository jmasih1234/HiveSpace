import SwiftUI

struct AuthView: View {
    @AppStorage("hiveSpace.authenticated") private var persistedAuthentication = false
    @AppStorage("hiveSpace.savedEmail") private var savedEmail = ""
    @State private var email = ""
    @State private var password = ""
    @State private var keepSignedIn = true
    @State private var isSigningIn = false
    @State private var authError: String?
    @State private var authMessage = "Use any valid email and a password with at least 6 characters."
    @State private var isAuthenticated = false

    private let cream = Color(red: 0.98, green: 0.97, blue: 0.95)
    private let plum = Color(red: 0.24, green: 0.10, blue: 0.36)
    private let rose = Color(red: 0.77, green: 0.33, blue: 0.48)
    private let blush = Color(red: 0.91, green: 0.63, blue: 0.71)
    private let muted = Color(red: 0.62, green: 0.56, blue: 0.67)

    var body: some View {
        Group {
            if isAuthenticated {
                AppShellView(onSignOut: signOut)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ScrollView {
                    VStack(spacing: 40) {
                        VStack(spacing: 22) {
                            HiveLogoMark(size: 110, shadowOpacity: 0.1)

                            VStack(spacing: 8) {
                                BrandName(fontSize: 50, plum: plum, rose: rose)
                                Text("YOUR COLONY, YOUR FLOW")
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .tracking(2.8)
                                    .foregroundStyle(muted)
                            }
                            .multilineTextAlignment(.center)
                        }
                        .padding(.top, 48)

                        VStack(spacing: 18) {
                            Text("Sign in to manage chores, tasks, and shared expenses.")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(muted)

                            VStack(spacing: 14) {
                                AuthField(
                                    title: "Email",
                                    systemImage: "envelope.fill",
                                    text: $email,
                                    textContentType: .emailAddress,
                                    keyboardType: .emailAddress,
                                    iconColor: rose
                                )

                                AuthSecureField(
                                    title: "Password",
                                    systemImage: "lock.fill",
                                    text: $password,
                                    iconColor: rose
                                )
                            }

                            if let authError {
                                Text(authError)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(rose)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(authMessage)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Toggle("Keep me signed in", isOn: $keepSignedIn)
                                .toggleStyle(SwitchToggleStyle(tint: rose))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(plum)

                            Button(action: signIn) {
                                HStack(spacing: 10) {
                                    if isSigningIn {
                                        ProgressView()
                                            .tint(.white)
                                    }

                                    Text(isSigningIn ? "Signing In..." : "Sign In")
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canSubmit ? plum : plum.opacity(0.55))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .disabled(!canSubmit || isSigningIn)

                            HStack {
                                Button("Create account") {
                                    authError = nil
                                    authMessage = "Account creation flow can branch from here next."
                                }
                                Spacer()
                                Button("Forgot password?") {
                                    authError = nil
                                    authMessage = "Password reset link would be sent to \(email.isEmpty ? "your email" : email)."
                                }
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(rose)
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
                }
            }
        }
        .background(cream.ignoresSafeArea())
        .onAppear {
            if email.isEmpty, !savedEmail.isEmpty {
                email = savedEmail
            }
            if persistedAuthentication {
                isAuthenticated = true
            }
        }
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    private func signIn() {
        guard !isSigningIn else {
            return
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            authError = "Enter a valid email address."
            return
        }

        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters."
            return
        }

        authError = nil
        authMessage = keepSignedIn ? "Saving your session on this device." : "Signing you in for this session."
        isSigningIn = true

        Task {
            try? await Task.sleep(for: .milliseconds(700))
            await MainActor.run {
                isSigningIn = false
                persistedAuthentication = keepSignedIn
                savedEmail = keepSignedIn ? normalizedEmail : ""
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAuthenticated = true
                }
            }
        }
    }

    private func signOut() {
        persistedAuthentication = false
        withAnimation(.easeInOut(duration: 0.3)) {
            isAuthenticated = false
        }
        password = ""
        authError = nil
        authMessage = "Signed out. Use any valid email and a password with at least 6 characters."
    }
}

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
}
