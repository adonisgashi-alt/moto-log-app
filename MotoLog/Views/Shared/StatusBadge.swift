//
//  StatusBadge.swift
//  MotoLog
//

import SwiftUI

/// A monochrome status pill. Overdue items are filled (highest emphasis),
/// due-soon items are outlined, and on-track items are plain text —
/// hierarchy comes from weight/fill rather than color.
struct StatusBadge: View {
    let status: MaintenanceStatus

    var body: some View {
        switch status {
        case .ok:
            HStack(spacing: 4) {
                Text("On Track")
                Image(systemName: status.systemImage)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        case .dueSoon:
            Label(status.label, systemImage: status.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(
                    Capsule().strokeBorder(Color.primary, lineWidth: 1)
                )
        case .overdue:
            Label(status.label, systemImage: status.systemImage)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.primary))
                .foregroundStyle(Color(uiColor: .systemBackground))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(status: .ok)
        StatusBadge(status: .dueSoon)
        StatusBadge(status: .overdue)
    }
    .padding()
}
