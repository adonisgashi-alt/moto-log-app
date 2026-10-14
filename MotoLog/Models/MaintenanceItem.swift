//
//  MaintenanceItem.swift
//  MotoLog
//

import Foundation
import SwiftData
import FirebaseFirestore

enum MaintenanceStatus {
    case ok
    case dueSoon
    case overdue

    var label: String {
        switch self {
        case .ok: return "OK"
        case .dueSoon: return "Due Soon"
        case .overdue: return "Overdue"
        }
    }

    var systemImage: String {
        switch self {
        case .ok: return "checkmark.circle.fill"
        case .dueSoon: return "exclamationmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
}

@Model
final class MaintenanceItem {
    var id: UUID = UUID()
    var typeRawValue: String = MaintenanceType.custom.rawValue
    var customName: String?
    var intervalMiles: Int = 1000
    var intervalMonths: Int = 12
    var lastServiceMileage: Int = 0
    var lastServiceDate: Date?
    var motorcycle: Motorcycle?
    /// Last-write-wins timestamp, same role as `Motorcycle.updatedAt`.
    var updatedAt: Date = Date()

    init(
        type: MaintenanceType,
        customName: String? = nil,
        intervalMiles: Int,
        intervalMonths: Int? = nil,
        lastServiceMileage: Int,
        lastServiceDate: Date = Date()
    ) {
        self.typeRawValue = type.rawValue
        self.customName = customName
        self.intervalMiles = intervalMiles
        self.intervalMonths = intervalMonths ?? type.defaultIntervalMonths
        self.lastServiceMileage = lastServiceMileage
        self.lastServiceDate = lastServiceDate
    }

    var type: MaintenanceType {
        MaintenanceType(rawValue: typeRawValue) ?? .custom
    }

    var displayName: String {
        if type == .custom {
            return (customName?.isEmpty == false ? customName! : "Custom Maintenance")
        }
        return type.defaultName
    }

    var nextDueMileage: Int {
        lastServiceMileage + intervalMiles
    }

    /// Manufacturers pair a mileage interval with a time interval ("X miles or
    /// Y months, whichever comes first") — this is the date side of that.
    var nextDueDate: Date {
        Calendar.current.date(byAdding: .month, value: intervalMonths, to: lastServiceDate ?? Date()) ?? Date()
    }

    func milesRemaining(currentMileage: Int) -> Int {
        nextDueMileage - currentMileage
    }

    func daysRemaining(asOf date: Date = Date()) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: nextDueDate).day ?? 0
    }

    func progress(currentMileage: Int) -> Double {
        guard intervalMiles > 0 else { return 0 }
        let traveled = currentMileage - lastServiceMileage
        return min(max(Double(traveled) / Double(intervalMiles), 0), 1)
    }

    func status(currentMileage: Int, asOf date: Date = Date()) -> MaintenanceStatus {
        let milesLeft = milesRemaining(currentMileage: currentMileage)
        let daysLeft = daysRemaining(asOf: date)

        if milesLeft <= 0 || daysLeft <= 0 {
            return .overdue
        }
        let dueSoonMileageThreshold = max(Int(Double(intervalMiles) * 0.1), 50)
        if milesLeft <= dueSoonMileageThreshold || daysLeft <= 14 {
            return .dueSoon
        }
        return .ok
    }

    func markServiced(atMileage mileage: Int, date: Date = Date()) {
        lastServiceMileage = mileage
        lastServiceDate = date
    }

    // MARK: - Firestore sync

    /// Mirrors `users/{uid}/maintenanceItems/{id}`. `motorcycleId` links back
    /// to the parent since this is a top-level collection, not nested under
    /// the motorcycle doc — SwiftData's `motorcycle` relationship has no
    /// Firestore equivalent.
    func firestoreData(motorcycleId: UUID) -> [String: Any] {
        [
            "motorcycleId": motorcycleId.uuidString,
            "type": typeRawValue,
            "customName": customName as Any,
            "intervalMiles": intervalMiles,
            "intervalMonths": intervalMonths,
            "lastServiceMileage": lastServiceMileage,
            "lastServiceDate": lastServiceDate as Any,
            "updatedAt": updatedAt
        ]
    }

    /// Creates a detached instance from a Firestore document. Returns nil
    /// (rather than the parent-less item) if `motorcycleId` doesn't resolve
    /// to a bike the sync service already knows about.
    convenience init?(id: UUID, data: [String: Any]) {
        guard let typeRaw = data["type"] as? String,
              let intervalMiles = data["intervalMiles"] as? Int,
              let lastServiceMileage = data["lastServiceMileage"] as? Int else { return nil }
        self.init(
            type: MaintenanceType(rawValue: typeRaw) ?? .custom,
            customName: data["customName"] as? String,
            intervalMiles: intervalMiles,
            intervalMonths: data["intervalMonths"] as? Int,
            lastServiceMileage: lastServiceMileage,
            lastServiceDate: (data["lastServiceDate"] as? Timestamp)?.dateValue() ?? Date()
        )
        self.id = id
        apply(data)
    }

    func apply(_ data: [String: Any]) {
        typeRawValue = data["type"] as? String ?? typeRawValue
        customName = data["customName"] as? String
        intervalMiles = data["intervalMiles"] as? Int ?? intervalMiles
        intervalMonths = data["intervalMonths"] as? Int ?? intervalMonths
        lastServiceMileage = data["lastServiceMileage"] as? Int ?? lastServiceMileage
        lastServiceDate = (data["lastServiceDate"] as? Timestamp)?.dateValue()
        updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? updatedAt
    }
}
