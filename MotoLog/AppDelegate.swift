//
//  AppDelegate.swift
//  MotoLog
//

import UIKit

/// Owns the services automatic ride detection needs for its whole lifetime,
/// independent of any SwiftUI scene. A significant-location-change wake-up
/// relaunches the app directly into the background with no `UIWindowScene`
/// connected, so `ContentView`'s `.task` never runs in that case — this
/// delegate is the one thing guaranteed to run on every launch, including
/// that one, which is why these services live here instead of as `@State`
/// on `ContentView`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    let appSettings = AppSettingsStore()
    let ridePermissions = RidePermissionsService()
    let rideTracking = RideTrackingService()
    let autoRideDetection = AutomaticRideDetectionService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        autoRideDetection.configure(rideTracking: rideTracking, permissions: ridePermissions, settings: appSettings)

        if launchOptions?[.location] != nil {
            // Re-arm CoreMotion/location monitoring right here. CoreMotion
            // itself needs nothing special, but `refreshStatuses()` makes
            // sure a permission revoked while MotoLog was terminated is
            // reflected before we decide whether to keep monitoring.
            ridePermissions.refreshStatuses()
            autoRideDetection.refresh()
        }

        return true
    }
}
