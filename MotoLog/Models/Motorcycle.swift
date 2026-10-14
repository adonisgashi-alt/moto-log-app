//
//  Motorcycle.swift
//  MotoLog
//

import Foundation
import SwiftData
import FirebaseFirestore

@Model
final class Motorcycle {
    var id: UUID = UUID()
    var make: String = ""
    var model: String = ""
    var year: Int = Calendar.current.component(.year, from: Date())
    var nickname: String?
    var currentMileage: Int = 0
    var dateAdded: Date = Date()
    var finalDriveTypeRawValue: String = MaintenanceType.chain.rawValue
    @Attribute(.externalStorage) var photoData: Data?
    /// Set only when `photoData` was auto-fetched from Wikimedia Commons
    /// (see MotorcyclePhotoLookupService) — nil for a rider's own uploaded
    /// photo, which needs no attribution. Cleared the moment the rider
    /// replaces the photo themselves.
    var photoAttribution: String?
    /// Firebase Storage download URL for `photoData`, set once
    /// `GarageSyncService` uploads it. Nil until the first sync.
    var photoURL: String?
    /// Last-write-wins timestamp used by `GarageSyncService` to decide
    /// which side (local vs. remote) is newer when both changed.
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceItem.motorcycle)
    var maintenanceItems: [MaintenanceItem] = []

    @Relationship(deleteRule: .cascade, inverse: \Trip.motorcycle)
    var trips: [Trip] = []

    init(
        make: String,
        model: String,
        year: Int,
        nickname: String? = nil,
        currentMileage: Int,
        finalDriveType: MaintenanceType = .chain
    ) {
        self.make = make
        self.model = model
        self.year = year
        self.nickname = nickname
        self.currentMileage = currentMileage
        self.finalDriveTypeRawValue = finalDriveType.rawValue
    }

    var finalDriveType: MaintenanceType {
        MaintenanceType(rawValue: finalDriveTypeRawValue) ?? .chain
    }

    var displayName: String {
        if let nickname, !nickname.isEmpty {
            return nickname
        }
        return "\(year) \(make) \(model)"
    }

    var subtitle: String {
        "\(year) \(make) \(model)"
    }

    /// The most urgent maintenance status across all items, used for the garage card summary.
    var overallStatus: MaintenanceStatus {
        let statuses = maintenanceItems.map { $0.status(currentMileage: currentMileage) }
        if statuses.contains(.overdue) { return .overdue }
        if statuses.contains(.dueSoon) { return .dueSoon }
        return .ok
    }

    /// Creates the standard oil/final-drive/brake/tire maintenance items using
    /// manufacturer-sourced intervals from the catalog when available, falling
    /// back to generic defaults for custom/unrecognized bikes.
    func addDefaultMaintenanceItems(info: MotorcycleModelInfo? = nil) {
        finalDriveTypeRawValue = (info?.finalDriveType ?? .chain).rawValue

        let oilItem = MaintenanceItem(
            type: .oilChange,
            intervalMiles: info?.oilChangeIntervalMiles ?? MaintenanceType.oilChange.defaultIntervalMiles,
            intervalMonths: info?.serviceIntervalMonths,
            lastServiceMileage: currentMileage
        )
        let driveItem = MaintenanceItem(
            type: finalDriveType,
            intervalMiles: info?.finalDriveIntervalMiles ?? finalDriveType.defaultIntervalMiles,
            intervalMonths: info?.serviceIntervalMonths,
            lastServiceMileage: currentMileage
        )
        // Brake fluid is a fixed 24-month industry standard regardless of make/model.
        let brakeItem = MaintenanceItem(
            type: .brakes,
            intervalMiles: info?.brakeInspectionIntervalMiles ?? MaintenanceType.brakes.defaultIntervalMiles,
            lastServiceMileage: currentMileage
        )
        let tireItem = MaintenanceItem(
            type: .tires,
            intervalMiles: info?.tireInspectionIntervalMiles ?? MaintenanceType.tires.defaultIntervalMiles,
            intervalMonths: info?.serviceIntervalMonths,
            lastServiceMileage: currentMileage
        )

        for item in [oilItem, driveItem, brakeItem, tireItem] {
            item.motorcycle = self
            maintenanceItems.append(item)
        }
    }

    // MARK: - Firestore sync

    /// Mirrors `users/{uid}/motorcycles/{id}`. Maintenance items and trips
    /// are separate top-level collections (keyed by `motorcycleId`), not
    /// nested here, so each can be listened to/queried independently.
    var firestoreData: [String: Any] {
        [
            "make": make,
            "model": model,
            "year": year,
            "nickname": nickname as Any,
            "currentMileage": currentMileage,
            "dateAdded": dateAdded,
            "finalDriveType": finalDriveTypeRawValue,
            "photoURL": photoURL as Any,
            "photoAttribution": photoAttribution as Any,
            "updatedAt": updatedAt
        ]
    }

    /// Creates a detached instance from a Firestore document — used by
    /// `GarageSyncService` when a remote motorcycle has no local match yet.
    /// `id` is the document ID (the model's own `UUID` string), not a field.
    convenience init?(id: UUID, data: [String: Any]) {
        guard let make = data["make"] as? String,
              let model = data["model"] as? String,
              let year = data["year"] as? Int,
              let currentMileage = data["currentMileage"] as? Int else { return nil }
        self.init(make: make, model: model, year: year, currentMileage: currentMileage)
        self.id = id
        apply(data)
    }

    /// Overwrites local fields with a remote document's values — used for
    /// both the initial pull and every subsequent remote-change listener.
    func apply(_ data: [String: Any]) {
        make = data["make"] as? String ?? make
        model = data["model"] as? String ?? model
        year = data["year"] as? Int ?? year
        nickname = data["nickname"] as? String
        currentMileage = data["currentMileage"] as? Int ?? currentMileage
        dateAdded = (data["dateAdded"] as? Timestamp)?.dateValue() ?? dateAdded
        finalDriveTypeRawValue = data["finalDriveType"] as? String ?? finalDriveTypeRawValue
        photoURL = data["photoURL"] as? String
        photoAttribution = data["photoAttribution"] as? String
        updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? updatedAt
    }
}
