//
//  AddTripView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

struct AddTripView: View {
    @Bindable var motorcycle: Motorcycle
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var distanceText = ""
    @State private var hours = 0
    @State private var minutes = 0
    @State private var notes = ""
    @State private var addToOdometer = true

    private let minuteOptions = Array(stride(from: 0, to: 60, by: 5))

    private var isValid: Bool {
        guard let distance = Int(distanceText) else { return false }
        return distance > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Distance (miles)", text: $distanceText)
                        .keyboardType(.numberPad)
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<13) { Text("\($0) h").tag($0) }
                        }
                        Picker("Minutes", selection: $minutes) {
                            ForEach(minuteOptions, id: \.self) { Text("\($0) m").tag($0) }
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Notes (optional)", text: $notes)
                }

                Section {
                    Toggle("Add these miles to \(motorcycle.displayName)'s odometer", isOn: $addToOdometer)
                } footer: {
                    Text("Current odometer: \(motorcycle.currentMileage.formatted()) mi")
                }
            }
            .navigationTitle("Log Trip")
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
        guard let distance = Int(distanceText) else { return }
        let trip = Trip(
            date: date,
            distanceMiles: distance,
            durationMinutes: hours * 60 + minutes,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        )
        trip.motorcycle = motorcycle
        motorcycle.trips.append(trip)
        modelContext.insert(trip)
        if addToOdometer {
            motorcycle.currentMileage += distance
        }
        dismiss()
    }
}
