//
//  MaintenanceSectionView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

/// Shared maintenance list + logging UI, embedded in both the Garage detail
/// screen and the Maintenance tab so the logic only lives in one place.
struct MaintenanceSectionView: View {
    @Bindable var motorcycle: Motorcycle
    @Environment(\.modelContext) private var modelContext
    @State private var isAddingCustom = false
    @State private var loggingItem: MaintenanceItem?

    private var sortedItems: [MaintenanceItem] {
        motorcycle.maintenanceItems.sorted {
            $0.milesRemaining(currentMileage: motorcycle.currentMileage)
                < $1.milesRemaining(currentMileage: motorcycle.currentMileage)
        }
    }

    var body: some View {
        Group {
            ForEach(sortedItems) { item in
                MaintenanceItemRow(item: item, currentMileage: motorcycle.currentMileage) {
                    loggingItem = item
                }
            }
            .onDelete(perform: delete)

            Button {
                isAddingCustom = true
            } label: {
                Label("Add Custom Maintenance", systemImage: "plus")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $isAddingCustom) {
            AddCustomMaintenanceView(motorcycle: motorcycle)
        }
        .sheet(item: $loggingItem) { item in
            LogServiceView(item: item, currentMileage: motorcycle.currentMileage)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedItems[index])
        }
    }
}
