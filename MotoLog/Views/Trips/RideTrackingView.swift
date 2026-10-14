//
//  RideTrackingView.swift
//  MotoLog
//

import SwiftUI
import MapKit

struct RideTrackingView: View {
    @Environment(RideTrackingService.self) private var rideTracking
    @State private var isShowingDiscardConfirmation = false

    private var elapsedText: String {
        let hours = rideTracking.elapsedSeconds / 3600
        let minutes = (rideTracking.elapsedSeconds % 3600) / 60
        let seconds = rideTracking.elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            Map {
                if rideTracking.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: rideTracking.routeCoordinates)
                        .stroke(.primary, lineWidth: 4)
                }
                if let last = rideTracking.routeCoordinates.last {
                    Marker("", coordinate: last)
                }
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 20) {
                if rideTracking.isStationaryTooLong {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.circle.fill")
                        Text("Looks like you've stopped. Ready to end this ride?")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f", rideTracking.distanceMiles))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        Text("miles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(elapsedText)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        Text("time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Button("End Ride") {
                    rideTracking.endRide()
                }
                .buttonStyle(.primaryAction)
                .padding(.horizontal, 40)

                Button("Cancel", role: .destructive) {
                    isShowingDiscardConfirmation = true
                }
                .font(.footnote)
            }
            .padding(.top)
            .padding(.bottom, 24)
        }
        .confirmationDialog(
            "Discard this ride?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Ride", role: .destructive) {
                rideTracking.discardRide()
            }
        } message: {
            Text("The route and mileage tracked so far will be lost.")
        }
    }
}
