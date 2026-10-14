//
//  TripsView.swift
//  MotoLog
//

import SwiftUI
import SwiftData
import MapKit

struct TripsView: View {
    @Query(sort: \Motorcycle.dateAdded) private var motorcycles: [Motorcycle]
    @Environment(AppState.self) private var appState
    @Environment(RideTrackingService.self) private var rideTracking
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingAddTrip = false
    @State private var isShowingSuggestRide = false
    @State private var selectedTrip: Trip?

    private var selectedMotorcycle: Motorcycle? {
        guard let id = appState.selectedMotorcycleID else { return motorcycles.first }
        return motorcycles.first(where: { $0.id == id }) ?? motorcycles.first
    }

    private var sortedTrips: [Trip] {
        (selectedMotorcycle?.trips ?? []).sorted { $0.date > $1.date }
    }

    private var totalMiles: Int {
        sortedTrips.reduce(0) { $0 + $1.distanceMiles }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let motorcycle = selectedMotorcycle {
                    List {
                        Section {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(motorcycle.displayName)
                                        .font(.headline)
                                    Text("\(totalMiles.formatted()) mi logged \u{00B7} \(sortedTrips.count) trip\(sortedTrips.count == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }

                            Button {
                                startRiding()
                            } label: {
                                Label("Start Riding", systemImage: "location.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.primaryAction)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom, 8)

                            Button {
                                isShowingSuggestRide = true
                            } label: {
                                Label("Suggest a Ride", systemImage: "map")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.outlined)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .padding(.horizontal)
                            .padding(.bottom)
                        }

                        if sortedTrips.isEmpty {
                            Section {
                                Text("No trips logged yet for this bike. Tap Start Riding to track one automatically, or + to log one manually.")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Section("Trip History") {
                                ForEach(sortedTrips) { trip in
                                    Button {
                                        selectedTrip = trip
                                    } label: {
                                        TripRow(trip: trip)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete(perform: deleteTrips)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.top, 16, for: .scrollContent)
                } else {
                    ContentUnavailableView {
                        Label("No Motorcycle Selected", systemImage: "map")
                    } description: {
                        Text("Add a motorcycle in the Garage tab to start logging trips.")
                    } actions: {
                        Button("Go to Garage") { appState.selectedTab = .garage }
                            .buttonStyle(.primaryAction)
                            .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                if selectedMotorcycle != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingAddTrip = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                if motorcycles.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            ForEach(motorcycles) { motorcycle in
                                Button {
                                    appState.selectedMotorcycleID = motorcycle.id
                                } label: {
                                    if motorcycle.id == selectedMotorcycle?.id {
                                        Label(motorcycle.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(motorcycle.displayName)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "motorcycle")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingAddTrip) {
                if let motorcycle = selectedMotorcycle {
                    AddTripView(motorcycle: motorcycle)
                }
            }
            .sheet(isPresented: $isShowingSuggestRide) {
                SuggestRideView()
            }
            .fullScreenCover(isPresented: Bindable(rideTracking).isTracking) {
                RideTrackingView()
            }
            .sheet(item: Bindable(rideTracking).pendingSummary) { summary in
                RideSummaryView(summary: summary)
            }
            .fullScreenCover(item: $selectedTrip) { trip in
                TripDetailView(trip: trip)
            }
            .alert("Can't Track Ride", isPresented: Binding(
                get: { rideTracking.errorMessage != nil },
                set: { if !$0 { rideTracking.errorMessage = nil } }
            )) {
                if rideTracking.isPermissionDenied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } else {
                    Button("OK", role: .cancel) {}
                }
            } message: {
                Text(rideTracking.errorMessage ?? "")
            }
        }
    }

    private func startRiding() {
        rideTracking.requestToStartRide()
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedTrips[index])
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if trip.hasRoute, trip.route.count > 1 {
                Map(interactionModes: []) {
                    MapPolyline(coordinates: trip.route.map(\.coordinate))
                        .stroke(.primary, lineWidth: 3)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .allowsHitTesting(false)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trip.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    Spacer()
                    Text("\(trip.distanceMiles) mi")
                        .font(.headline)
                }
                HStack(spacing: 4) {
                    Text(trip.durationText)
                    if let avg = trip.averageSpeedMph {
                        Text("\u{00B7} \(avg) mph avg")
                    }
                    if let temperatureRangeText = trip.temperatureRangeText {
                        Text("\u{00B7} \(temperatureRangeText)")
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if let notes = trip.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    TripsView()
        .environment(AppState())
        .environment(RideTrackingService())
        .environment(RouteSuggestionService())
        .modelContainer(for: [Motorcycle.self, MaintenanceItem.self, Trip.self], inMemory: true)
}
