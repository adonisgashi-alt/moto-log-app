//
//  Trip.swift
//  MotoLog
//

import Foundation
import SwiftData
import FirebaseFirestore

@Model
final class Trip {
    var id: UUID = UUID()
    var date: Date = Date()
    var distanceMiles: Int = 0
    var durationMinutes: Int = 0
    var notes: String?
    var motorcycle: Motorcycle?

    /// JSON-encoded `[TrackPoint]` captured by a GPS-tracked ride. Nil for
    /// trips logged manually via AddTripView, which have no route.
    @Attribute(.externalStorage) var routeData: Data?
    var startTemperatureF: Double?
    var endTemperatureF: Double?
    /// Firebase Storage download URL for the JSON-encoded route, set once
    /// `GarageSyncService` uploads `routeData`. Nil for manually-logged trips.
    var routeURL: String?
    /// Last-write-wins timestamp, same role as `Motorcycle.updatedAt`.
    var updatedAt: Date = Date()

    init(
        date: Date = Date(),
        distanceMiles: Int,
        durationMinutes: Int,
        notes: String? = nil,
        route: [TrackPoint]? = nil,
        startTemperatureF: Double? = nil,
        endTemperatureF: Double? = nil
    ) {
        self.date = date
        self.distanceMiles = distanceMiles
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.routeData = route.flatMap { try? JSONEncoder().encode($0) }
        self.startTemperatureF = startTemperatureF
        self.endTemperatureF = endTemperatureF
    }

    var durationText: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        switch (hours, minutes) {
        case (0, _): return "\(minutes)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(minutes)m"
        }
    }

    var averageSpeedMph: Int? {
        guard durationMinutes > 0 else { return nil }
        return Int((Double(distanceMiles) / Double(durationMinutes)) * 60)
    }

    var route: [TrackPoint] {
        guard let routeData else { return [] }
        return (try? JSONDecoder().decode([TrackPoint].self, from: routeData)) ?? []
    }

    var hasRoute: Bool {
        routeData != nil
    }

    /// e.g. "73–77°" for a ride that warmed up, or "73°" when start/end match.
    var temperatureRangeText: String? {
        guard let startTemperatureF, let endTemperatureF else { return nil }
        let lo = Int(min(startTemperatureF, endTemperatureF).rounded())
        let hi = Int(max(startTemperatureF, endTemperatureF).rounded())
        return lo == hi ? "\(lo)\u{00B0}" : "\(lo)\u{2013}\(hi)\u{00B0}"
    }

    // MARK: - Firestore sync

    /// Mirrors `users/{uid}/trips/{id}`. The route itself lives in Storage
    /// (`trip_routes/{uid}/{id}`), not in this document — a dense GPS track
    /// can exceed Firestore's 1 MB document cap.
    func firestoreData(motorcycleId: UUID?) -> [String: Any] {
        [
            "motorcycleId": motorcycleId?.uuidString as Any,
            "date": date,
            "distanceMiles": distanceMiles,
            "durationMinutes": durationMinutes,
            "notes": notes as Any,
            "startTemperatureF": startTemperatureF as Any,
            "endTemperatureF": endTemperatureF as Any,
            "routeURL": routeURL as Any,
            "updatedAt": updatedAt
        ]
    }

    convenience init?(id: UUID, data: [String: Any]) {
        guard let distanceMiles = data["distanceMiles"] as? Int,
              let durationMinutes = data["durationMinutes"] as? Int else { return nil }
        self.init(distanceMiles: distanceMiles, durationMinutes: durationMinutes)
        self.id = id
        apply(data)
    }

    func apply(_ data: [String: Any]) {
        date = (data["date"] as? Timestamp)?.dateValue() ?? date
        distanceMiles = data["distanceMiles"] as? Int ?? distanceMiles
        durationMinutes = data["durationMinutes"] as? Int ?? durationMinutes
        notes = data["notes"] as? String
        startTemperatureF = data["startTemperatureF"] as? Double
        endTemperatureF = data["endTemperatureF"] as? Double
        routeURL = data["routeURL"] as? String
        updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? updatedAt
    }
}
