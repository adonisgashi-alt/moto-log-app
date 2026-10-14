//
//  AutomaticRideDetectionService.swift
//  MotoLog
//

import Foundation
import CoreLocation
import CoreMotion

/// Watches CoreMotion activity to auto-start/stop ride tracking without the
/// rider tapping "Start Riding" — only active once they've opted in via
/// `AutomaticTrackingSetupView` and granted both Always-location and Motion.
///
/// CoreMotion alone won't keep the app alive in the background, so a
/// dedicated `CLLocationManager` runs significant-location-change monitoring
/// purely as an iOS background wake-up while idle; once a ride is confirmed,
/// `RideTrackingService` takes over with full-accuracy tracking and this
/// service steps aside until the ride ends. (This covers detection while the
/// app process is alive, backgrounded or foregrounded — it does not relaunch
/// MotoLog from a fully terminated state, which would need an
/// app-delegate-based launch handler.)
///
/// Before committing to a start, it also takes a brief look at device-motion
/// roll for a motorcycle-style lean, to raise confidence over "automotive"
/// activity alone — which can't otherwise tell a motorcycle from a car. This
/// only helps when the phone is mounted to the bike; see
/// `beginLeanConfirmation`.
@Observable
final class AutomaticRideDetectionService: NSObject, CLLocationManagerDelegate {
    private let wakeLocationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()

    private var rideTracking: RideTrackingService?
    private var permissions: RidePermissionsService?
    private var settings: AppSettingsStore?

    private(set) var isMonitoring = false
    private var stationarySinceDate: Date?
    private var isConfirmingLean = false
    private var rollRangeMin: Double = .greatestFiniteMagnitude
    private var rollRangeMax: Double = -.greatestFiniteMagnitude

    /// How long the rider has to look stationary before an automatically
    /// started ride ends itself. Longer than the manual UI's 180s "looks
    /// like you've stopped" nudge since there's no one watching the screen
    /// to confirm it's really over — a stoplight shouldn't end the ride.
    private let autoEndStationaryThreshold: TimeInterval = 300

    /// How long to sample device motion for a lean, once CoreMotion already
    /// thinks we're in a vehicle, before giving up and starting anyway. Kept
    /// short (rather than, say, 30s) to fit inside the ~10s of background
    /// execution time a significant-location-change wake-up grants, and so a
    /// straight road at the start of a ride doesn't delay tracking for long.
    private let leanConfirmationWindow: TimeInterval = 5
    /// A car's body stays level through a turn; a motorcycle's frame — and a
    /// handlebar/tank-mounted phone along with it — visibly leans into one.
    /// ~15° of peak-to-peak roll is a clear lean, well above what jostling in
    /// a cupholder or dash mount would produce on its own.
    private let leanRollThresholdRadians: Double = 0.26

    override init() {
        super.init()
        wakeLocationManager.delegate = self
    }

    func configure(rideTracking: RideTrackingService, permissions: RidePermissionsService, settings: AppSettingsStore) {
        self.rideTracking = rideTracking
        self.permissions = permissions
        self.settings = settings
    }

    /// Call after anything that could change whether detection should be
    /// running: the opt-in toggle, a permission grant/revoke, or launch.
    func refresh() {
        if shouldMonitor {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private var shouldMonitor: Bool {
        guard let settings, let permissions else { return false }
        return settings.isAutomaticTrackingEnabled
            && permissions.locationPermission == .always
            && permissions.motionPermission == .granted
            && CMMotionActivityManager.isActivityAvailable()
    }

    private func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        wakeLocationManager.startMonitoringSignificantLocationChanges()
        motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            self.handle(activity)
        }
    }

    private func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        wakeLocationManager.stopMonitoringSignificantLocationChanges()
        motionActivityManager.stopActivityUpdates()
        cancelLeanConfirmation()
        stationarySinceDate = nil
    }

    private func handle(_ activity: CMMotionActivity) {
        guard let rideTracking else { return }
        if rideTracking.isTracking {
            // A rider who started manually stays in control of ending it.
            guard rideTracking.startedAutomatically else { return }
            evaluateAutoEnd(activity, rideTracking: rideTracking)
        } else {
            stationarySinceDate = nil
            evaluateAutoStart(activity, rideTracking: rideTracking)
        }
    }

    private func evaluateAutoStart(_ activity: CMMotionActivity, rideTracking: RideTrackingService) {
        guard !isConfirmingLean else { return }
        guard activity.confidence != .low, activity.automotive,
              !activity.stationary, !activity.walking, !activity.running, !activity.cycling else { return }
        // Full-accuracy tracking takes over once we start the ride — step
        // aside so the two location managers aren't both running at once.
        wakeLocationManager.stopMonitoringSignificantLocationChanges()
        beginLeanConfirmation(rideTracking: rideTracking)
    }

    /// Briefly samples device motion for a motorcycle-style lean before
    /// committing to the ride. A clear lean confirms it immediately; no lean
    /// within the window is inconclusive — a straight road, or a phone in a
    /// pocket that can't see the bike's lean at all — not proof it's a car,
    /// so it still starts the ride on CoreMotion's word alone, same as before
    /// this existed. The upshot is only a faster, more confident start when
    /// the phone happens to be mounted and the rider turns early.
    private func beginLeanConfirmation(rideTracking: RideTrackingService) {
        guard motionManager.isDeviceMotionAvailable else {
            rideTracking.startRide(isAutomatic: true)
            return
        }
        isConfirmingLean = true
        rollRangeMin = .greatestFiniteMagnitude
        rollRangeMax = -.greatestFiniteMagnitude

        motionManager.deviceMotionUpdateInterval = 1.0 / 20.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion, self.isConfirmingLean else { return }
            let roll = motion.attitude.roll
            self.rollRangeMin = min(self.rollRangeMin, roll)
            self.rollRangeMax = max(self.rollRangeMax, roll)
            if self.rollRangeMax - self.rollRangeMin >= self.leanRollThresholdRadians {
                self.finishLeanConfirmation(rideTracking: rideTracking)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + leanConfirmationWindow) { [weak self] in
            self?.finishLeanConfirmation(rideTracking: rideTracking)
        }
    }

    private func finishLeanConfirmation(rideTracking: RideTrackingService) {
        guard isConfirmingLean else { return }
        isConfirmingLean = false
        motionManager.stopDeviceMotionUpdates()
        rideTracking.startRide(isAutomatic: true)
    }

    private func cancelLeanConfirmation() {
        guard isConfirmingLean else { return }
        isConfirmingLean = false
        motionManager.stopDeviceMotionUpdates()
    }

    private func evaluateAutoEnd(_ activity: CMMotionActivity, rideTracking: RideTrackingService) {
        guard activity.confidence != .low, activity.stationary else {
            stationarySinceDate = nil
            return
        }
        guard let since = stationarySinceDate else {
            stationarySinceDate = Date()
            return
        }
        if Date().timeIntervalSince(since) > autoEndStationaryThreshold {
            stationarySinceDate = nil
            rideTracking.endRide()
            if isMonitoring {
                wakeLocationManager.startMonitoringSignificantLocationChanges()
            }
        }
    }
}
