//
//  RideTrackingService.swift
//  MotoLog
//

import Foundation
import CoreLocation

/// The result of a completed GPS-tracked ride, pending the rider's review
/// (which motorcycle, notes, odometer) before it's saved as a `Trip`.
struct RideSummary: Identifiable {
    let id = UUID()
    var startDate: Date
    var endDate: Date
    var distanceMiles: Double
    var route: [TrackPoint]
    var startTemperatureF: Double?
    var endTemperatureF: Double?

    var durationMinutes: Int {
        max(0, Int(endDate.timeIntervalSince(startDate) / 60))
    }
}

/// Ride tracking, started either by a "Start Riding" tap or by
/// `AutomaticRideDetectionService` noticing automotive motion. Runs on
/// CoreLocation's "When In Use" authorization by default, so it's active
/// while MotoLog is open/foregrounded; if the rider has upgraded to "Always"
/// (opting into automatic tracking), it also tracks in the background.
@Observable
final class RideTrackingService: NSObject, CLLocationManagerDelegate {
    enum TrackingError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location access is needed to track your ride. Enable it in Settings > MotoLog > Location."
            }
        }
    }

    private let locationManager = CLLocationManager()
    private let weatherService = WeatherService()

    var isTracking = false
    var elapsedSeconds = 0
    var distanceMiles: Double = 0
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var errorMessage: String?
    var isStationaryTooLong = false
    var pendingSummary: RideSummary?
    /// Set when `AutomaticRideDetectionService` starts this ride rather than
    /// a "Start Riding" tap — gates auto-*ending* the ride too, so a rider
    /// who started manually stays in control of when it ends.
    private(set) var startedAutomatically = false

    private var points: [TrackPoint] = []
    private var lastLocation: CLLocation?
    private var startDate: Date?
    private var lastMovementDate: Date?
    private var timer: Timer?
    private var isAwaitingPermissionToStart = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    var hasLocationPermission: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var isPermissionDenied: Bool {
        let status = locationManager.authorizationStatus
        return status == .denied || status == .restricted
    }

    /// Single entry point for the "Start Riding" button: starts immediately
    /// if we already have permission, otherwise requests it and auto-starts
    /// once the system alert resolves — rather than making the rider tap
    /// "Start Riding" a second time, which is error-prone because a second
    /// tap can land while the permission alert is still animating away and
    /// get silently dropped by UIKit's presentation machinery.
    func requestToStartRide() {
        if hasLocationPermission {
            startRide()
        } else if isPermissionDenied {
            errorMessage = TrackingError.permissionDenied.errorDescription
        } else {
            isAwaitingPermissionToStart = true
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startRide(isAutomatic: Bool = false) {
        guard hasLocationPermission else {
            errorMessage = TrackingError.permissionDenied.errorDescription
            return
        }
        points = []
        routeCoordinates = []
        distanceMiles = 0
        elapsedSeconds = 0
        lastLocation = nil
        isStationaryTooLong = false
        startedAutomatically = isAutomatic

        let now = Date()
        startDate = now
        lastMovementDate = now
        isTracking = true

        // Always-location riders get background tracking for free; When-In-Use-only
        // riders keep the original foreground-only behavior.
        locationManager.allowsBackgroundLocationUpdates = locationManager.authorizationStatus == .authorizedAlways
        locationManager.startUpdatingLocation()
        startTimer()
    }

    func discardRide() {
        stopUpdating()
        isTracking = false
        startDate = nil
    }

    func endRide() {
        guard let startDate else { return }
        stopUpdating()
        isTracking = false
        let endDate = Date()
        let finishedPoints = points
        let finishedDistance = distanceMiles
        self.startDate = nil

        Task {
            var startTemp: Double?
            var endTemp: Double?
            if let first = finishedPoints.first {
                startTemp = await weatherService.temperatureFahrenheit(
                    latitude: first.latitude, longitude: first.longitude, at: first.timestamp
                )
            }
            if let last = finishedPoints.last {
                endTemp = await weatherService.temperatureFahrenheit(
                    latitude: last.latitude, longitude: last.longitude, at: last.timestamp
                )
            }
            await MainActor.run {
                self.pendingSummary = RideSummary(
                    startDate: startDate,
                    endDate: endDate,
                    distanceMiles: finishedDistance,
                    route: finishedPoints,
                    startTemperatureF: startTemp,
                    endTemperatureF: endTemp
                )
            }
        }
    }

    func clearPendingSummary() {
        pendingSummary = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
    }

    private func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let startDate else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(startDate))
        if let lastMovementDate, Date().timeIntervalSince(lastMovementDate) > 180 {
            isStationaryTooLong = true
        }
    }

    private func handle(locations: [CLLocation]) {
        guard isTracking, let newest = locations.last else { return }
        guard newest.horizontalAccuracy >= 0, newest.horizontalAccuracy < 50 else { return }

        if let lastLocation {
            let delta = newest.distance(from: lastLocation)
            // Ignore GPS jitter while stopped at a light — only count real movement.
            if delta > 5 {
                distanceMiles += delta / 1609.344
                lastMovementDate = Date()
                isStationaryTooLong = false
            }
        } else {
            lastMovementDate = Date()
        }
        lastLocation = newest
        routeCoordinates.append(newest.coordinate)
        points.append(TrackPoint(
            latitude: newest.coordinate.latitude,
            longitude: newest.coordinate.longitude,
            timestamp: newest.timestamp
        ))
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.handle(locations: locations)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // CoreLocation commonly fires this once with .locationUnknown right
        // as tracking starts, before the first real fix arrives — transient,
        // more updates are already on the way. Surfacing it as an alert here
        // would present at the same instant the ride-tracking fullScreenCover
        // does, and the two presentations collide on the same host.
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.handleAuthorizationChange()
        }
    }

    private func handleAuthorizationChange() {
        guard isAwaitingPermissionToStart else { return }
        // CLLocationManager calls this delegate method twice per request:
        // once synchronously with .notDetermined the instant
        // requestWhenInUseAuthorization() is called (before the system
        // prompt even appears), and again once the user actually responds.
        // Ignore the first, spurious echo so we don't consume the "awaiting"
        // flag before the real answer arrives.
        let status = locationManager.authorizationStatus
        guard status != .notDetermined else { return }
        isAwaitingPermissionToStart = false

        if hasLocationPermission {
            // A beat for the system permission alert to finish dismissing
            // before we present the fullScreenCover — presenting immediately
            // can silently collide with that still-in-flight transition.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.startRide()
            }
        } else if isPermissionDenied {
            errorMessage = TrackingError.permissionDenied.errorDescription
        }
    }
}
