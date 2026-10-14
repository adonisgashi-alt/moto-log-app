//
//  AppleSignInButton.swift
//  MotoLog
//

import AuthenticationServices
import UIKit

/// Drives the native Sign in with Apple flow without a UIKit button view.
///
/// A previous version of this file wrapped `ASAuthorizationAppleIDButton`
/// (UIKit) in a `UIViewRepresentable` to get an exact capsule shape and a
/// guaranteed-identical size next to the custom Google button. That wrapper
/// broke in four different ways across repeated attempts — missing width
/// constraints collapsing the button to zero size, the native view's
/// internal Auto Layout intrinsic-height fighting the SwiftUI-side frame,
/// and finally the button's background/border failing to render at all
/// even once the outer frame was forced to the right size — because
/// UIKit's Auto Layout and SwiftUI's layout system were negotiating over
/// the same view in ways that kept finding new failure modes.
///
/// Apple's own Human Interface Guidelines ship exact artwork, typography,
/// and minimum sizing for the Sign in with Apple mark specifically so a
/// fully custom button can stay compliant without using the stock control
/// — so AuthLandingView now renders the button as a plain SwiftUI `Button`
/// (sharing `OutlinedButtonStyle` with the Google button, guaranteeing
/// pixel-identical sizing since they're now the exact same SwiftUI style
/// struct) and this coordinator only drives the real authorization flow.
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?

    func signIn(
        onRequest: (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
    ) {
        self.onCompletion = onCompletion
        let request = ASAuthorizationAppleIDProvider().createRequest()
        onRequest(request)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion?(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion?(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = windowScenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return keyWindow
        }
        // UIWindow() (no scene) is deprecated; fall back to building a
        // window on whatever scene is available rather than a scene-less
        // one. There should always be a key window by the time this is
        // called (Sign in with Apple only runs from an active, on-screen
        // flow), so this is a last-resort path, not the common case.
        if let scene = windowScenes.first {
            return UIWindow(windowScene: scene)
        }
        // Genuinely unreachable: Sign in with Apple only runs from an
        // active, on-screen flow, which requires at least one connected
        // scene to exist. There's no scene-less, non-deprecated UIWindow
        // initializer to fall back to.
        fatalError("No window scene available to present Sign in with Apple")
    }
}
