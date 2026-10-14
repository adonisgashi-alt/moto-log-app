//
//  AccountStore.swift
//  MotoLog
//

import Foundation
import CryptoKit
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import UIKit

/// Auth/session management backed by real Firebase Auth. Signing in is
/// optional here — it only exists so `GarageSyncService` has an account to
/// mirror Garage/Maintenance/Trips data under for the companion website to
/// read. There's no in-app profile/username/social layer anymore.
@Observable
final class AccountStore {
    private(set) var firebaseUser: FirebaseAuth.User?

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var currentAppleNonce: String?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user
        }
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    /// Waits for any in-flight Firestore writes (e.g. a bike just added by
    /// `GarageSyncService` seconds ago) to actually reach the server before
    /// invalidating the auth token — otherwise a write still sitting in
    /// Firestore's local queue can get rejected mid-flight by the sign-out,
    /// silently dropping data the next sign-in has nothing to restore.
    func signOut() async throws {
        try? await Firestore.firestore().waitForPendingWrites()
        try Auth.auth().signOut()
    }

    // MARK: - Sign in with Apple

    /// Call from the `SignInWithAppleButton` request closure to set up the nonce.
    func prepareAppleSignIn(request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    enum AppleSignInError: LocalizedError {
        case missingNonce
        case missingToken
        var errorDescription: String? {
            "Apple sign-in couldn't be completed. Please try again."
        }
    }

    func completeAppleSignIn(authorization: ASAuthorization) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        guard let nonce = currentAppleNonce else { throw AppleSignInError.missingNonce }
        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AppleSignInError.missingToken
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        try await Auth.auth().signIn(with: firebaseCredential)

        // Apple only hands us the person's name on their very first sign-in —
        // stash it on the Firebase user now so ChooseUsernameView can prefill it.
        if let user = Auth.auth().currentUser, user.displayName == nil {
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                try? await changeRequest.commitChanges()
            }
        }
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(status == errSecSuccess, "Unable to generate nonce")
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Sign in with Google

    enum GoogleSignInError: LocalizedError {
        case noPresentingViewController
        case missingToken
        var errorDescription: String? {
            switch self {
            case .noPresentingViewController:
                return "Couldn't find a screen to present Google Sign-In from. Try again."
            case .missingToken:
                return "Google didn't return a valid sign-in token. Try again."
            }
        }
    }

    func signInWithGoogle() async throws {
        guard let presentingViewController = UIApplication.shared.motoLogRootViewController else {
            throw GoogleSignInError.noPresentingViewController
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.missingToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Email / password

    /// Whether a thrown `signIn` error means "no account exists for this
    /// email" — AuthLandingView uses this to decide whether to bounce the
    /// rider from the sign-in form to the sign-up form, rather than
    /// pre-checking via the now-deprecated `fetchSignInMethods(forEmail:)`
    /// (which Firebase says always returns empty once Email Enumeration
    /// Protection is on, making it unreliable regardless of this project's
    /// current setting).
    static func isUserNotFoundError(_ error: Error) -> Bool {
        AuthErrorCode(rawValue: (error as NSError).code) == .userNotFound
    }

    func createAccount(name: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
}

private extension UIApplication {
    var motoLogRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}
