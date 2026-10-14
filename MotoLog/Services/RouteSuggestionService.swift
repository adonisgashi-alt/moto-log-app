//
//  RouteSuggestionService.swift
//  MotoLog
//

import Foundation
import CoreLocation
import MapKit

/// Generates candidate loop routes (start → waypoint → back to start) near
/// the rider's current location, sized to a target distance/duration and
/// biased toward a requested road character. Built entirely on MapKit
/// (MKDirections + MKLocalSearch) — free, no API key, no account capability
/// needed — same reasoning as WeatherService's choice of Open-Meteo.
///
/// MapKit's directions API doesn't expose an "avoid highways" or
/// "prefer curvy roads" parameter the way some paid routing APIs do, so
/// this can't generate true curvature-optimized routes. Instead it picks a
/// waypoint at roughly half the target distance away (biased via
/// MKLocalSearch toward parks/overlooks for Scenic, rural landmarks for
/// Curvy, or downtown/commercial points for City) and asks MapKit for the
/// real drivable road path out and back — a reasonable approximation
/// without the specialized road-curvature datasets dedicated motorcycle
/// route-planning apps use.
@Observable
final class RouteSuggestionService: NSObject, CLLocationManagerDelegate {
    enum SuggestionError: LocalizedError {
        case locationDenied
        case noRoutesFound

        var errorDescription: String? {
            switch self {
            case .locationDenied:
                return "Location access is needed to suggest routes near you. Enable it in Settings > MotoLog > Location."
            case .noRoutesFound:
                return "Couldn't find any routes nearby. Try a different distance or road type."
            }
        }
    }

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    var isSearching = false
    var errorMessage: String?
    var suggestedRoutes: [SuggestedRoute] = []

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func suggestRoutes(goal: RideGoal, roadType: RoadType) async {
        isSearching = true
        errorMessage = nil
        suggestedRoutes = []
        defer { isSearching = false }

        do {
            let origin = try await currentLocation()
            let targetMiles = targetDistanceMiles(for: goal, roadType: roadType)
            // Spread three candidate directions around the compass rather
            // than three random bearings, so the suggestions don't cluster
            // on the same side of town.
            let bearings: [Double] = [40, 160, 280]

            var candidates: [SuggestedRoute] = []
            for bearing in bearings {
                if let route = try? await buildLoopRoute(
                    origin: origin, bearingDegrees: bearing, targetMiles: targetMiles, roadType: roadType
                ) {
                    candidates.append(route)
                }
            }

            guard !candidates.isEmpty else {
                errorMessage = SuggestionError.noRoutesFound.errorDescription
                return
            }

            suggestedRoutes = candidates.sorted {
                abs($0.distanceMiles - targetMiles) < abs($1.distanceMiles - targetMiles)
            }
        } catch let error as CLError where error.code == .denied {
            errorMessage = SuggestionError.locationDenied.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func targetDistanceMiles(for goal: RideGoal, roadType: RoadType) -> Double {
        switch goal {
        case .miles(let miles): return miles
        case .hours(let hours): return hours * roadType.assumedAverageSpeedMph
        }
    }

    private func buildLoopRoute(
        origin: CLLocationCoordinate2D, bearingDegrees: Double, targetMiles: Double, roadType: RoadType
    ) async throws -> SuggestedRoute {
        let halfDistance = max(targetMiles / 2, 1)
        let approxWaypoint = destinationCoordinate(from: origin, bearingDegrees: bearingDegrees, distanceMiles: halfDistance)
        let (waypointCoordinate, waypointName) = await resolveWaypoint(near: approxWaypoint, roadType: roadType)

        async let outbound = route(from: origin, to: waypointCoordinate)
        async let inbound = route(from: waypointCoordinate, to: origin)
        let (outboundRoute, inboundRoute) = try await (outbound, inbound)

        let coordinates = outboundRoute.polyline.coordinates + inboundRoute.polyline.coordinates
        let totalMeters = outboundRoute.distance + inboundRoute.distance
        let totalSeconds = outboundRoute.expectedTravelTime + inboundRoute.expectedTravelTime

        return SuggestedRoute(
            coordinates: coordinates,
            distanceMiles: totalMeters / 1609.344,
            durationMinutes: Int(totalSeconds / 60),
            waypointCoordinate: waypointCoordinate,
            waypointName: waypointName
        )
    }

    /// `MKLocalSearch.Request.region` is only a soft bias, not a hard
    /// filter — an exact-name match hundreds of miles away can outrank a
    /// weaker nearby match, so a naive `.first` pick can return a result
    /// nowhere near where the loop is supposed to be. Explicitly measure
    /// distance from the search point and reject anything outside a sane
    /// radius, falling back to the geometric point (no POI bias) rather
    /// than ever accepting a wildly out-of-area result.
    private func resolveWaypoint(near coordinate: CLLocationCoordinate2D, roadType: RoadType) async -> (CLLocationCoordinate2D, String) {
        let searchRadiusMeters: CLLocationDistance = 16000
        let maxAcceptableDistanceMeters = searchRadiusMeters * 1.5
        let searchCenter = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        for term in roadType.waypointSearchTerms {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: searchRadiusMeters, longitudinalMeters: searchRadiusMeters)
            let search = MKLocalSearch(request: request)
            guard let response = try? await search.start() else { continue }

            let nearestMatch = response.mapItems
                .map { item -> (MKMapItem, CLLocationDistance) in
                    (item, item.location.distance(from: searchCenter))
                }
                .filter { $0.1 <= maxAcceptableDistanceMeters }
                .min { $0.1 < $1.1 }

            if let (item, _) = nearestMatch {
                return (item.location.coordinate, displayName(for: item, fallback: term.capitalized))
            }
        }
        return (coordinate, "Loop Ride")
    }

    /// Generic POI names like "Downtown" are common across many towns —
    /// appending the locality disambiguates candidate cards that would
    /// otherwise show the same label for genuinely different places.
    private func displayName(for item: MKMapItem, fallback: String) -> String {
        let name = item.name ?? fallback
        if let locality = item.addressRepresentations?.cityName, !name.localizedCaseInsensitiveContains(locality) {
            return "\(name), \(locality)"
        }
        return name
    }

    private func route(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: from.latitude, longitude: from.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: to.latitude, longitude: to.longitude), address: nil)
        request.transportType = .automobile
        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else {
            throw SuggestionError.noRoutesFound
        }
        return route
    }

    /// Great-circle destination point given a starting coordinate, bearing,
    /// and distance — used to pick a rough search area for the waypoint
    /// before refining it with MKLocalSearch.
    private func destinationCoordinate(from origin: CLLocationCoordinate2D, bearingDegrees: Double, distanceMiles: Double) -> CLLocationCoordinate2D {
        let earthRadiusMiles = 3958.8
        let bearing = bearingDegrees * .pi / 180
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        let angularDistance = distanceMiles / earthRadiusMiles

        let lat2 = asin(sin(lat1) * cos(angularDistance) + cos(lat1) * sin(angularDistance) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(angularDistance) * cos(lat1), cos(angularDistance) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }

    private func currentLocation() async throws -> CLLocationCoordinate2D {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.locationContinuation?.resume(returning: location.coordinate)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: error)
            self.locationContinuation = nil
        }
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
