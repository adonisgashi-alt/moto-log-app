//
//  SuggestedRoute.swift
//  MotoLog
//

import Foundation
import CoreLocation

/// One candidate loop route (start → waypoint → back to start) produced by
/// RouteSuggestionService, ready for preview and hand-off to Apple Maps.
struct SuggestedRoute: Identifiable {
    let id = UUID()
    var coordinates: [CLLocationCoordinate2D]
    var distanceMiles: Double
    var durationMinutes: Int
    var waypointCoordinate: CLLocationCoordinate2D
    var waypointName: String
}
