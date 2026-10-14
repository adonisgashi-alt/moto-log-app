//
//  GarageListView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

struct GarageListView: View {
    @Query(sort: \Motorcycle.dateAdded) private var motorcycles: [Motorcycle]
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingAddMotorcycle = false
    @State private var selectedMotorcycle: Motorcycle?

    var body: some View {
        NavigationStack {
            Group {
                if motorcycles.isEmpty {
                    ContentUnavailableView {
                        Label("No Motorcycles", systemImage: "motorcycle")
                    } description: {
                        Text("Add your motorcycle to start tracking mileage and maintenance.")
                    } actions: {
                        Button("Add Motorcycle") { isShowingAddMotorcycle = true }
                            .buttonStyle(.primaryAction)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(motorcycles) { motorcycle in
                            Section {
                                // A full-screen cover rather than a
                                // NavigationLink push: the detail screen's
                                // hero photo needs to bleed under the status
                                // bar/Dynamic Island, and a view pushed inside
                                // this NavigationStack's real navigation
                                // controller won't reliably reach the true
                                // top edge even with the nav bar hidden — a
                                // cover has no navigation controller to fight.
                                Button {
                                    selectedMotorcycle = motorcycle
                                } label: {
                                    MotorcycleRow(motorcycle: motorcycle)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        modelContext.delete(motorcycle)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    // Without this, the swipe action inherits
                                    // the app-wide `.tint(.primary)` instead of
                                    // its usual red — in dark mode that makes
                                    // the background and trash icon both
                                    // resolve to white, so the icon vanishes.
                                    .tint(.red)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .listSectionSpacing(10)
                    .contentMargins(.top, 16, for: .scrollContent)
                }
            }
            .navigationTitle("Garage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddMotorcycle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddMotorcycle) {
                AddMotorcycleView()
            }
            .fullScreenCover(item: $selectedMotorcycle) { motorcycle in
                MotorcycleDetailView(motorcycle: motorcycle)
            }
        }
    }
}

private struct MotorcycleRow: View {
    @Bindable var motorcycle: Motorcycle

    /// The item closest to being due, shown as a home-page-style "what's next" hint.
    private var mostUrgentItem: MaintenanceItem? {
        motorcycle.maintenanceItems.min {
            $0.milesRemaining(currentMileage: motorcycle.currentMileage)
                < $1.milesRemaining(currentMileage: motorcycle.currentMileage)
        }
    }

    private var hasNickname: Bool {
        motorcycle.nickname?.isEmpty == false
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MotorcyclePhotoView(motorcycle: motorcycle, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(motorcycle.displayName)
                    .font(.headline)

                // Only show the "YYYY Make Model" line when it's not identical
                // to the title above (i.e. only when a nickname is set).
                if hasNickname {
                    Text(motorcycle.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("\(motorcycle.currentMileage.formatted()) mi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let mostUrgentItem {
                    Text(nextUpText(for: mostUrgentItem))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            Spacer()
            StatusBadge(status: motorcycle.overallStatus)
        }
        .padding(.vertical, 8)
    }

    private func nextUpText(for item: MaintenanceItem) -> String {
        let remaining = item.milesRemaining(currentMileage: motorcycle.currentMileage)
        if remaining <= 0 {
            return "Next: \(item.displayName) \u{00B7} overdue"
        }
        return "Next: \(item.displayName) \u{00B7} \(remaining) mi left"
    }
}

#Preview {
    GarageListView()
        .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}
