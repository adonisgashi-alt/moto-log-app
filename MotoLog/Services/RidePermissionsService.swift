//
//  RidePermissionsService.swift
//  MotoLog
//

import Foundation
import CoreLocation
import CoreMotion

/// Tracks and requests the two permissions automatic ride detection needs —
/// Always-location (so tracking can run in the background) and Motion &
/// Fitness (so CoreMotion can flag "automotive" activity as the trigger).
/// Kept separate from `RideTrackingService`, which only needs When-In-Use
/// for the existing manual "Start Riding" flow and knows nothing about
/// automatic detection.
@Observable
final class RidePermissionsService: NSObject, CLLocationManagerDelegate {
    enum LocationPermission {
        case notDetermined
        case whenInUseOnly
        case always
        case denied
        case restricted
    }

    enum SimplePermission {
        case notDetermined
        case granted
        case denied
        case restricted
    }

    private let locationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()

    private(set) var locationPermission: LocationPermission = .notDetermined
    private(set) var motionPermission: SimplePermission = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self
        refreshStatuses()
    }

    func refreshStatuses() {
        locationPermission = Self.locationPermission(for: locationManager.authorizationStatus)
        motionPermission = Self.simplePermission(for: CMMotionActivityManager.authorizationStatus())
    }

    func requestWhenInUseLocation() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysLocation() {
        locationManager.requestAlwaysAuthorization()
    }

    /// CoreMotion has no explicit "request authorization" call — querying
    /// activity data is what surfaces the system prompt on first use, so a
    /// throwaway one-second query is the request.
    func requestMotionAuthorization(completion: @escaping () -> Void) {
        let now = Date()
        motionActivityManager.queryActivityStarting(from: now.addingTimeInterval(-1), to: now, to: .main) { [weak self] _, _ in
            self?.motionPermission = Self.simplePermission(for: CMMotionActivityManager.authorizationStatus())
            completion()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.refreshStatuses()
        }
    }

    private static func locationPermission(for status: CLAuthorizationStatus) -> LocationPermission {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse: return .whenInUseOnly
        case .authorizedAlways: return .always
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    private static func simplePermission(for status: CMAuthorizationStatus) -> SimplePermission {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
}
