//
//  EqualInfoContainer.swift
//  MotoLog
//

import SwiftUI

/// Shared chrome for the "equal containers" stat grid pattern — a neutral
/// rounded box sized to match its siblings in a `LazyVGrid` or `HStack`. Each
/// call site supplies its own inner content (a trip's distance/duration/temp,
/// a bike's mileage/next-service), so only the card styling itself is shared,
/// keeping both screens' stat grids visually consistent without forcing one
/// layout.
///
/// Stretches to fill the height its siblings need (not just its own content's
/// height) — a plain `HStack` doesn't equalize child heights the way
/// `LazyVGrid` rows do, so without this a 2-line box and a 3-line box next to
/// each other get different-sized backgrounds instead of matching.
struct EqualInfoContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
            .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
