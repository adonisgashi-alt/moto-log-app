//
//  RoadType.swift
//  MotoLog
//

import Foundation

/// The kind of riding a suggested route should favor. There's no public,
/// free API exposing real road-curvature data, so "Curvy"/"Scenic" are a
/// best-effort proxy: biasing the route's waypoint toward parks, overlooks,
/// and rural landmarks rather than true curvature-optimized routing.
enum RoadType: String, CaseIterable, Identifiable {
    case curvy
    case scenic
    case city

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .curvy: return "Curvy Roads"
        case .scenic: return "Scenic Roads"
        case .city: return "City Roads"
        }
    }

    var systemImage: String {
        switch self {
        case .curvy: return "road.lanes"
        case .scenic: return "mountain.2"
        case .city: return "building.2"
        }
    }

    /// Average riding speed used to convert an hours-based goal into a
    /// target distance — curvy backroads and city riding-with-stops run
    /// slower than a relaxed scenic cruise, so each type assumes a
    /// different pace.
    var assumedAverageSpeedMph: Double {
        switch self {
        case .curvy: return 30
        case .scenic: return 32
        case .city: return 22
        }
    }

    /// MKLocalSearch query terms tried in order to bias the route's
    /// waypoint toward the requested road character.
    var waypointSearchTerms: [String] {
        switch self {
        case .curvy: return ["scenic overlook", "state park", "mountain pass"]
        case .scenic: return ["scenic overlook", "park", "lake", "nature preserve"]
        case .city: return ["downtown", "town center", "shopping district"]
        }
    }
}

/// How the rider wants to size the suggested ride.
enum RideGoal: Equatable {
    case miles(Double)
    case hours(Double)
}
