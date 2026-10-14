//
//  TrackPoint.swift
//  MotoLog
//

import Foundation
import CoreLocation

/// A single GPS sample captured while a ride is being tracked. Stored on
/// `Trip` as JSON-encoded `Data` (SwiftData can't natively persist an array
/// of custom structs), decoded back into `[TrackPoint]` on demand for the
/// route map and distance/temperature calculations.
struct TrackPoint: Codable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
