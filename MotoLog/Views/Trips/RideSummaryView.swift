//
//  RideSummaryView.swift
//  MotoLog
//

import SwiftUI
import SwiftData
import MapKit

/// Shown right after a tracked ride ends — the "was this you riding your
/// motorcycle?" moment. Lets the rider review the GPS-measured route,
/// mileage, duration, and temperature range, pick which bike it was, and
/// either save it as a Trip or discard it entirely.
struct RideSummaryView: View {
    let summary: RideSummary

    @Environment(RideTrackingService.self) private var rideTracking
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Motorcycle.dateAdded) private var motorcycles: [Motorcycle]

    @State private var selectedMotorcycleID: UUID?
    @State private var addToOdometer = true
    @State private var notes = ""

    private var selectedMotorcycle: Motorcycle? {
        motorcycles.first { $0.id == selectedMotorcycleID } ?? motorcycles.first
    }

    private var coordinates: [CLLocationCoordinate2D] {
        summary.route.map(\.coordinate)
    }

    private var temperatureRangeText: String? {
        guard let start = summary.startTemperatureF, let end = summary.endTemperatureF else { return nil }
        let lo = Int(min(start, end).rounded())
        let hi = Int(max(start, end).rounded())
        return lo == hi ? "\(lo)\u{00B0}" : "\(lo)\u{2013}\(hi)\u{00B0}"
    }

    private var durationText: String {
        let minutes = summary.durationMinutes
        let hours = minutes / 60
        let mins = minutes % 60
        return hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
    }

    var body: some View {
        NavigationStack {
            Form {
                if coordinates.count > 1 {
                    Section {
                        Map {
                            MapPolyline(coordinates: coordinates)
                                .stroke(.primary, lineWidth: 4)
                        }
                        .frame(height: 200)
                        .listRowInsets(EdgeInsets())
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                Section("Was This You Riding?") {
                    LabeledContent("Distance", value: String(format: "%.1f mi", summary.distanceMiles))
                    LabeledContent("Duration", value: durationText)
                    if let temperatureRangeText {
                        LabeledContent("Temperature", value: temperatureRangeText)
                    }
                }

                if motorcycles.count > 1 {
                    Section("Motorcycle") {
                        Picker("Motorcycle", selection: $selectedMotorcycleID) {
                            ForEach(motorcycles) { motorcycle in
                                Text(motorcycle.displayName).tag(Optional(motorcycle.id))
                            }
                        }
                    }
                }

                Section {
                    TextField("Notes (optional)", text: $notes)
                }

                if let selectedMotorcycle {
                    Section {
                        Toggle("Add these miles to \(selectedMotorcycle.displayName)'s odometer", isOn: $addToOdometer)
                    } footer: {
                        Text("Current odometer: \(selectedMotorcycle.currentMileage.formatted()) mi")
                    }
                }
            }
            .navigationTitle("Save Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        rideTracking.clearPendingSummary()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(selectedMotorcycle == nil)
                }
            }
            .onAppear {
                if selectedMotorcycleID == nil {
                    selectedMotorcycleID = motorcycles.first?.id
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func save() {
        guard let selectedMotorcycle else { return }
        let roundedMiles = Int(summary.distanceMiles.rounded())
        let trip = Trip(
            date: summary.startDate,
            distanceMiles: roundedMiles,
            durationMinutes: summary.durationMinutes,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes,
            route: summary.route,
            startTemperatureF: summary.startTemperatureF,
            endTemperatureF: summary.endTemperatureF
        )
        trip.motorcycle = selectedMotorcycle
        selectedMotorcycle.trips.append(trip)
        modelContext.insert(trip)
        if addToOdometer {
            selectedMotorcycle.currentMileage += roundedMiles
        }
        rideTracking.clearPendingSummary()
    }
}
