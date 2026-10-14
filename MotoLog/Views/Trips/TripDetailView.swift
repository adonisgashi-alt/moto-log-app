//
//  TripDetailView.swift
//  MotoLog
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// Full-bleed route map with a details card floating over the bottom —
/// tapping a trip in `TripsView`'s history opens this instead of drilling
/// into a form, the way Waymo's trip detail puts the map front-and-center
/// with a round back button rather than a plain navigation push.
struct TripDetailView: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingDeleteConfirmation = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cardHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var cityName: String?

    private var coordinates: [CLLocationCoordinate2D] {
        trip.route.map(\.coordinate)
    }

    private var hasRoute: Bool {
        trip.hasRoute && coordinates.count > 1
    }

    private var endDate: Date {
        trip.date.addingTimeInterval(TimeInterval(trip.durationMinutes * 60))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                if hasRoute {
                    Map(position: $cameraPosition) {
                        MapPolyline(coordinates: coordinates)
                            .stroke(.primary, lineWidth: 4)
                        if let start = coordinates.first {
                            Marker("Start", systemImage: "flag.fill", coordinate: start)
                                .tint(.green)
                        }
                        if let end = coordinates.last {
                            Marker("End", systemImage: "flag.checkered", coordinate: end)
                                .tint(.red)
                        }
                    }
                    .mapControlVisibility(.hidden)
                    .ignoresSafeArea()
                } else {
                    Color(uiColor: .systemGroupedBackground)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No route recorded for this trip.")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .onAppear { viewHeight = proxy.size.height }
            .onChange(of: proxy.size.height) { _, newValue in viewHeight = newValue }
        }
        .safeAreaInset(edge: .bottom) {
            detailCard
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { newValue in
                    cardHeight = newValue
                }
        }
        .onChange(of: cardHeight) { _, _ in updateCameraPosition() }
        .onChange(of: viewHeight) { _, _ in updateCameraPosition() }
        .task { await resolveCityName() }
        .confirmationDialog(
            "Delete this trip?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Trip", role: .destructive) {
                modelContext.delete(trip)
                dismiss()
            }
        }
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.date.formatted(date: .long, time: .omitted))
                        .font(.title3.weight(.bold))
                    if let motorcycle = trip.motorcycle {
                        Text(motorcycle.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let cityName {
                    Text(cityName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if hasRoute {
                HStack {
                    timeColumn(label: "Start", time: trip.date, alignment: .leading)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    timeColumn(label: "End", time: endDate, alignment: .trailing)
                }
                Divider()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                statContainer(value: "\(trip.distanceMiles)", unit: "mi", label: "Distance")
                statContainer(value: trip.durationText, unit: nil, label: "Duration")
                if let avg = trip.averageSpeedMph {
                    statContainer(value: "\(avg)", unit: "mph", label: "Avg Speed")
                }
                if let temperatureRangeText = trip.temperatureRangeText {
                    statContainer(value: temperatureRangeText, unit: nil, label: "Temp")
                }
            }

            if let notes = trip.notes, !notes.isEmpty {
                Divider()
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete Trip", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func timeColumn(label: String, time: Date, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(time.formatted(date: .omitted, time: .shortened))
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func statContainer(value: String, unit: String?, label: String) -> some View {
        EqualInfoContainer {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2.weight(.bold))
                    if let unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Computes the region directly from the route's own bounds every time,
    /// rather than reading back and nudging whatever `MapKit`'s automatic fit
    /// settled on — that two-step, read-then-shift approach depended on
    /// `onMapCameraChange` firing exactly once with the final settled camera,
    /// which doesn't hold up reliably (it can fire early, mid-animation, or
    /// more than once), producing inconsistent framing. A single pure
    /// function of the route + measured card height has no such race.
    private func updateCameraPosition() {
        guard hasRoute, viewHeight > 0 else { return }
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max() else { return }

        // Breathing room around the route itself, applied symmetrically so
        // it can't affect horizontal or vertical centering on its own.
        let breathingRoom = 1.4
        let minSpanDegrees = 0.003
        let latSpan = max(maxLat - minLat, minSpanDegrees) * breathingRoom
        let lonSpan = max(maxLon - minLon, minSpanDegrees) * breathingRoom

        // Extend the region further south only, proportional to how much of
        // the screen the card covers, so the route itself lands centered in
        // the space still visible above it rather than dead-center overall.
        let visibleHeight = max(viewHeight - cardHeight, 1)
        let extraSouthSpan = latSpan * (cardHeight / visibleHeight)

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2 - extraSouthSpan / 2,
            longitude: (minLon + maxLon) / 2
        )
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latSpan + extraSouthSpan, longitudeDelta: lonSpan)
        )
        cameraPosition = .region(region)
    }

    private func resolveCityName() async {
        guard hasRoute, let start = coordinates.first else { return }
        let location = CLLocation(latitude: start.latitude, longitude: start.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else { return }
        cityName = placemark.locality ?? placemark.subAdministrativeArea
    }
}

#Preview {
    let route = [
        TrackPoint(latitude: 37.7749, longitude: -122.4194, timestamp: .now),
        TrackPoint(latitude: 37.7849, longitude: -122.4094, timestamp: .now),
        TrackPoint(latitude: 37.7999, longitude: -122.4294, timestamp: .now),
        TrackPoint(latitude: 37.8099, longitude: -122.4150, timestamp: .now)
    ]
    let trip = Trip(
        distanceMiles: 42,
        durationMinutes: 65,
        notes: "Canyon loop",
        route: route,
        startTemperatureF: 68,
        endTemperatureF: 74
    )
    TripDetailView(trip: trip)
        .modelContainer(for: [Motorcycle.self, Trip.self], inMemory: true)
}
