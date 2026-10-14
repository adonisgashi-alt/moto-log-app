//
//  LogServiceView.swift
//  MotoLog
//

import SwiftUI

struct LogServiceView: View {
    @Bindable var item: MaintenanceItem
    let currentMileage: Int

    @Environment(\.dismiss) private var dismiss
    @State private var serviceMileage: String
    @State private var serviceDate: Date = Date()

    init(item: MaintenanceItem, currentMileage: Int) {
        self.item = item
        self.currentMileage = currentMileage
        _serviceMileage = State(initialValue: String(currentMileage))
    }

    private var isValid: Bool { Int(serviceMileage) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Performed") {
                    Text(item.displayName)
                        .font(.headline)
                }
                Section("Mileage at Service") {
                    TextField("Mileage", text: $serviceMileage)
                        .keyboardType(.numberPad)
                }
                Section("Date") {
                    DatePicker("Service Date", selection: $serviceDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Log Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let mileage = Int(serviceMileage) {
                            item.markServiced(atMileage: mileage, date: serviceDate)
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
