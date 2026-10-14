//
//  AddCustomMaintenanceView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

struct AddCustomMaintenanceView: View {
    @Bindable var motorcycle: Motorcycle
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var intervalMiles: String = "1000"
    @State private var lastServiceMileage: String

    init(motorcycle: Motorcycle) {
        self.motorcycle = motorcycle
        _lastServiceMileage = State(initialValue: String(motorcycle.currentMileage))
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Int(intervalMiles) != nil
            && Int(lastServiceMileage) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Maintenance Item") {
                    TextField("Name (e.g. Air Filter)", text: $name)
                    TextField("Interval (miles)", text: $intervalMiles)
                        .keyboardType(.numberPad)
                    TextField("Last Serviced At (miles)", text: $lastServiceMileage)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Custom Maintenance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard let interval = Int(intervalMiles), let lastServiced = Int(lastServiceMileage) else { return }
        let item = MaintenanceItem(
            type: .custom,
            customName: name.trimmingCharacters(in: .whitespaces),
            intervalMiles: interval,
            lastServiceMileage: lastServiced
        )
        item.motorcycle = motorcycle
        motorcycle.maintenanceItems.append(item)
        modelContext.insert(item)
        dismiss()
    }
}
