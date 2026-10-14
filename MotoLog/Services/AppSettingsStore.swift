//
//  AppSettingsStore.swift
//  MotoLog
//

import Foundation

/// App-wide (not per-account) preferences, persisted to UserDefaults.
/// Separate from AccountStore since these settings apply
/// regardless of sign-in state.
@Observable
final class AppSettingsStore {
    private let defaults = UserDefaults.standard
    private let partsRetailerKey = "settings.defaultPartsRetailer"
    private let automaticTrackingKey = "settings.isAutomaticTrackingEnabled"

    var defaultPartsRetailer: PartsRetailer {
        didSet {
            defaults.set(defaultPartsRetailer.rawValue, forKey: partsRetailerKey)
        }
    }

    /// Whether the rider has opted into automatic ride detection. Only takes
    /// effect once the required permissions (Always-location, Motion &
    /// Fitness) are also granted — see `AutomaticRideDetectionService`.
    var isAutomaticTrackingEnabled: Bool {
        didSet {
            defaults.set(isAutomaticTrackingEnabled, forKey: automaticTrackingKey)
        }
    }

    init() {
        if let rawValue = UserDefaults.standard.string(forKey: partsRetailerKey),
           let retailer = PartsRetailer(rawValue: rawValue) {
            defaultPartsRetailer = retailer
        } else {
            defaultPartsRetailer = .revzilla
        }
        isAutomaticTrackingEnabled = UserDefaults.standard.bool(forKey: automaticTrackingKey)
    }
}
