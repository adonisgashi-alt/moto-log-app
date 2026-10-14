//
//  FormStyling.swift
//  MotoLog
//

import SwiftUI

extension View {
    /// Filled-capsule field background matching the auth buttons' shape AND
    /// exact height (50pt, fixed rather than padding-derived so it can't
    /// drift from the buttons under Dynamic Type), so text fields and
    /// buttons read as one consistent design language on custom (non-Form)
    /// auth-style screens.
    func capsuleFieldStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.secondary.opacity(0.15), in: Capsule())
    }
}
