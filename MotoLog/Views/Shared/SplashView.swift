//
//  SplashView.swift
//  MotoLog
//

import SwiftUI

/// Matches LaunchScreen.storyboard exactly (same background, same centered
/// logo) so there's no visible flash/jump when this takes over from the
/// system launch screen — it just stays up a little longer, for however
/// long the app's initial auth-state check takes, instead of showing the
/// tab UI mid-flicker (e.g. briefly showing the sign-in screen before a
/// persisted session loads). The rounded corners are baked directly into
/// LaunchLogo's PNG (Apple's ~22.37% app-icon corner ratio) rather than
/// applied via clipShape here — launch screens can't execute any code
/// (Apple rejects user-defined runtime attributes on them), so the asset
/// itself has to carry the rounding for both renderers to match exactly.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
    }
}
