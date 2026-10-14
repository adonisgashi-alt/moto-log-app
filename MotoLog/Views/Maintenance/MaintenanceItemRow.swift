//
//  MaintenanceItemRow.swift
//  MotoLog
//

import SwiftUI

struct MaintenanceItemRow: View {
    let item: MaintenanceItem
    let currentMileage: Int
    var isInteractive: Bool = true
    var onLogService: (() -> Void)?

    private var status: MaintenanceStatus { item.status(currentMileage: currentMileage) }
    private var remaining: Int { item.milesRemaining(currentMileage: currentMileage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(item.displayName, systemImage: item.type.systemImage)
                    .font(.headline)
                Spacer()
                StatusBadge(status: status)
            }

            ProgressView(value: item.progress(currentMileage: currentMileage))
                .tint(.primary)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(remainingText)
                    Text(dueDateText)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Spacer()
                if isInteractive, let onLogService {
                    Button("Log Service", action: onLogService)
                        .font(.subheadline)
                        .buttonStyle(.glass)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var remainingText: String {
        if remaining <= 0 {
            return "\(-remaining) mi overdue \u{00B7} every \(item.intervalMiles) mi"
        }
        return "\(remaining) mi remaining \u{00B7} every \(item.intervalMiles) mi"
    }

    private var dueDateText: String {
        let formatted = item.nextDueDate.formatted(date: .abbreviated, time: .omitted)
        let daysLeft = item.daysRemaining()
        return daysLeft <= 0 ? "Due by \(formatted) (overdue)" : "Due by \(formatted)"
    }
}

#Preview {
    let item = MaintenanceItem(type: .oilChange, intervalMiles: 3000, lastServiceMileage: 1000)
    return List {
        MaintenanceItemRow(item: item, currentMileage: 3800, onLogService: {})
    }
}
