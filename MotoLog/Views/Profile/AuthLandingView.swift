//
//  AuthLandingView.swift
//  MotoLog
//

import SwiftUI
import AuthenticationServices
import UIKit

/// Email + password together, attempt sign-in first — if Firebase says no
/// account exists for that email, bounce to a sign-up form (carrying over
/// the password already typed) instead of pre-checking whether the email
/// exists. See AccountStore.isUserNotFoundError for why this replaced the
/// old "check email first" flow.
struct AuthLandingView: View {
    @Environment(AccountStore.self) private var accountStore
    @State private var appleSignInCoordinator = AppleSignInCoordinator()

    private enum Stage: Equatable {
        case signIn
        case signUp
    }

    @State private var stage: Stage = .signIn
    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var googleErrorMessage: String?
    @State private var appleErrorMessage: String?

    /// The app's actual home-screen icon, pulled from the bundle's icon files
    /// rather than a duplicated image asset — falls back to a generic glyph if
    /// Xcode ever changes how icons are packaged.
    private var appIconImage: Image {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let uiImage = UIImage(named: name) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "person.crop.circle")
    }

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var isSubmitEnabled: Bool {
        switch stage {
        case .signIn:
            return isEmailValid && !password.isEmpty && !isSubmitting
        case .signUp:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
                && password.count >= 6
                && password == confirmPassword
                && !isSubmitting
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    appIconImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Text("Log In or Sign Up")
                        .font(.title2.weight(.bold))
                        .padding(.top, 8)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .capsuleFieldStyle()
                        .disabled(stage == .signUp)

                    if stage == .signUp {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .capsuleFieldStyle()
                    }

                    SecureField(stage == .signUp ? "Password (6+ characters)" : "Password", text: $password)
                        .textContentType(stage == .signUp ? .newPassword : .password)
                        .capsuleFieldStyle()

                    if stage == .signUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .capsuleFieldStyle()
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button(primaryButtonTitle, action: primaryAction)
                    .buttonStyle(.primaryAction)
                    .disabled(!isSubmitEnabled)

                if stage == .signUp {
                    Button("Use a Different Email", action: reset)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    VStack { Divider() }
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack { Divider() }
                }

                VStack(spacing: 12) {
                    // A plain SwiftUI button sharing OutlinedButtonStyle with
                    // the Google button below — see AppleSignInCoordinator
                    // for why this replaced a UIKit-wrapped
                    // ASAuthorizationAppleIDButton. Using the same style
                    // struct for both guarantees identical sizing; Apple's
                    // HIG ships the exact logo/text artwork used here
                    // precisely so a custom button like this stays compliant.
                    Button {
                        appleSignInCoordinator.signIn(
                            onRequest: { request in
                                accountStore.prepareAppleSignIn(request: request)
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    Task {
                                        do {
                                            try await accountStore.completeAppleSignIn(authorization: authorization)
                                        } catch {
                                            appleErrorMessage = error.localizedDescription
                                        }
                                    }
                                case .failure(let error):
                                    if (error as? ASAuthorizationError)?.code != .canceled {
                                        appleErrorMessage = error.localizedDescription
                                    }
                                }
                            }
                        )
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "apple.logo")
                            Text("Sign in with Apple")
                        }
                    }
                    .buttonStyle(.outlined)

                    Button {
                        Task {
                            do {
                                try await accountStore.signInWithGoogle()
                            } catch {
                                googleErrorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack {
                            GoogleLogoMark()
                                .frame(width: 18, height: 18)
                            Text("Sign in with Google")
                        }
                    }
                    .buttonStyle(.outlined)
                }

                Spacer()
            }
            .padding()
        }
        .alert("Google Sign-In", isPresented: Binding(
            get: { googleErrorMessage != nil },
            set: { if !$0 { googleErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(googleErrorMessage ?? "")
        }
        .alert("Sign in with Apple", isPresented: Binding(
            get: { appleErrorMessage != nil },
            set: { if !$0 { appleErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appleErrorMessage ?? "")
        }
    }

    private var primaryButtonTitle: String {
        switch stage {
        case .signIn: return isSubmitting ? "Signing In..." : "Continue"
        case .signUp: return isSubmitting ? "Creating..." : "Create Account"
        }
    }

    private func primaryAction() {
        switch stage {
        case .signIn: attemptSignIn()
        case .signUp: createAccount()
        }
    }

    /// Attempts sign-in directly instead of pre-checking whether the email
    /// exists. A `.userNotFound` error means this is actually a new rider —
    /// bounce to the sign-up form (keeping the password they already typed,
    /// so they only need to add their name and confirm it) rather than
    /// surfacing it as a hard failure.
    private func attemptSignIn() {
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await accountStore.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            } catch {
                if AccountStore.isUserNotFoundError(error) {
                    withAnimation {
                        stage = .signUp
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            }
            isSubmitting = false
        }
    }

    private func createAccount() {
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await accountStore.createAccount(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func reset() {
        withAnimation {
            stage = .signIn
            password = ""
            confirmPassword = ""
            name = ""
            errorMessage = nil
        }
    }
}
