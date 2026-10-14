//
//  SuggestedRoutesResultView.swift
//  MotoLog
//

import SwiftUI
import MapKit
import UIKit

struct SuggestedRoutesResultView: View {
    @Environment(RouteSuggestionService.self) private var routeSuggestion
    @Environment(RideTrackingService.self) private var rideTracking
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRouteID: SuggestedRoute.ID?

    private var selectedRoute: SuggestedRoute? {
        routeSuggestion.suggestedRoutes.first { $0.id == selectedRouteID }
    }

    var body: some View {
        NavigationStack {
            List(routeSuggestion.suggestedRoutes) { route in
                RouteCard(route: route, isSelected: selectedRouteID == route.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRouteID = route.id
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("Suggested Routes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedRoute {
                    VStack(spacing: 12) {
                        Button("Open in Apple Maps") {
                            openInAppleMaps(route: selectedRoute)
                        }
                        .buttonStyle(.primaryAction)

                        Button {
                            openInGoogleMaps(route: selectedRoute)
                        } label: {
                            HStack {
                                GoogleLogoMark()
                                    .frame(width: 18, height: 18)
                                Text("Open in Google Maps")
                            }
                        }
                        .buttonStyle(.outlined)

                        Button {
                            rideTracking.requestToStartRide()
                            dismiss()
                        } label: {
                            Text("Start Riding (Track in MotoLog)")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(.bar)
                }
            }
            .onAppear {
                if selectedRouteID == nil {
                    selectedRouteID = routeSuggestion.suggestedRoutes.first?.id
                }
            }
        }
    }

    private func openInAppleMaps(route: SuggestedRoute) {
        guard let origin = route.coordinates.first else { return }
        MapsHandoff.openInAppleMaps(
            origin: origin,
            destination: origin,
            waypoint: (route.waypointCoordinate, route.waypointName)
        )
    }

    private func openInGoogleMaps(route: SuggestedRoute) {
        guard let origin = route.coordinates.first else { return }
        MapsHandoff.openInGoogleMaps(origin: origin, destination: origin, waypoint: route.waypointCoordinate)
    }
}

private struct RouteCard: View {
    let route: SuggestedRoute
    let isSelected: Bool

    private var durationText: String {
        let hours = route.durationMinutes / 60
        let minutes = route.durationMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Map {
                MapPolyline(coordinates: route.coordinates)
                    .stroke(.primary, lineWidth: 3)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("via \(route.waypointName)")
                        .font(.headline)
                    Text("\(String(format: "%.1f", route.distanceMiles)) mi \u{00B7} \(durationText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.primary)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.primary, lineWidth: 2)
            }
        }
    }
}
