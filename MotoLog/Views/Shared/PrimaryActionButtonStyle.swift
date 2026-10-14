//
//  PrimaryActionButtonStyle.swift
//  MotoLog
//

import SwiftUI

/// A bold, full-size, guaranteed-readable call-to-action button. Liquid Glass's
/// `.glassProminent` style computes its own tint/label contrast, which produced
/// unreadable white-on-white buttons when combined with this app's `.tint(.primary)`
/// override — this style sidesteps that by setting background/foreground explicitly.
///
/// `minWidth: 260` keeps this readable when a parent (like ContentUnavailableView's
/// action area) doesn't offer a wide layout; `maxWidth: .infinity` lets it stretch
/// to match sibling buttons (e.g. Sign in with Apple/Google) in a normal VStack.
struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(minWidth: 260, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
            .background(Color.primary, in: Capsule())
            .foregroundStyle(Color(uiColor: .systemBackground))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Mirrors Apple's own `.whiteOutline` Sign-In-With-Apple button — white
/// fill, black text, with a thin outline for definition against a light
/// page background — so the "or sign in with X" row renders Apple and
/// Google identically. (A previous version of this style used a black fill
/// with a white outline, which looked wrong: on a white page, a white
/// outline around a black pill is nearly invisible and isn't a real Apple
/// or Google button pattern — Apple's actual sanctioned styles are `.black`,
/// `.white`, and `.whiteOutline`, never a dark fill with a light outline.)
/// On a dark page this drops the outline and matches Apple's plain `.white`
/// style instead, since a white pill already has full contrast against a
/// dark background without needing a border.
struct OutlinedButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(minWidth: 260, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
            .foregroundStyle(.black)
            .background(.white, in: Capsule())
            .overlay {
                if colorScheme == .light {
                    Capsule().strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Small-scale companion to `PrimaryActionButtonStyle` — the same solid
/// Color.primary/systemBackground capsule treatment, sized for inline row
/// actions (e.g. accepting a friend request, adding a found rider) rather
/// than full-width screen CTAs. Mirrors Apple's own Bordered-Prominent
/// button at its "Small" size rather than each call site hand-rolling the
/// same padding/fill/text-color combination separately (which had already
/// drifted slightly out of sync between two screens).
struct CompactProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.primary, in: Capsule())
            .foregroundStyle(Color(uiColor: .systemBackground))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: PrimaryActionButtonStyle { PrimaryActionButtonStyle() }
}

extension ButtonStyle where Self == OutlinedButtonStyle {
    static var outlined: OutlinedButtonStyle { OutlinedButtonStyle() }
}

extension ButtonStyle where Self == CompactProminentButtonStyle {
    static var compactProminent: CompactProminentButtonStyle { CompactProminentButtonStyle() }
}
