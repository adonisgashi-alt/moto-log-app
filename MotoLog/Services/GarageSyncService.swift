//
//  GarageSyncService.swift
//  MotoLog
//

import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseStorage

/// Surfaces real failures (a rejected Firestore write, a save that threw)
/// to Console.app without spamming it on every routine save — `print()`
/// is block-buffered when piped to a debugger and can sit unflushed
/// indefinitely, so this writes straight to `stderr`, which isn't.
private func garageSyncDebugLog(_ message: String) {
    fputs("[GarageSync] \(message)\n", stderr)
}

/// Keeps `Motorcycle`/`MaintenanceItem`/`Trip` in sync between local
/// SwiftData (the fast, offline-capable read path every existing Garage/
/// Maintenance/Trips view already uses) and Firestore (the shared source
/// of truth the website also reads).
///
/// Local -> cloud: listens for `ModelContext.didSave` and pushes whatever
/// changed. Cloud -> local: Firestore snapshot listeners upsert/delete the
/// matching SwiftData rows. `isApplyingRemote` suppresses the local
/// observer while a remote-driven save is in flight — that's what stops
/// the two directions from echoing the same write back and forth forever.
///
/// Bike photos and GPS routes are too large for a 1 MB Firestore document,
/// so they live in Firebase Storage instead; only their download URL rides
/// along on the Firestore doc.
@Observable
final class GarageSyncService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private var modelContext: ModelContext?
    private var currentUID: String?
    private var isApplyingRemote = false

    private var localSaveObserver: NSObjectProtocol?
    private var motorcyclesListener: ListenerRegistration?
    private var maintenanceItemsListener: ListenerRegistration?
    private var tripsListener: ListenerRegistration?
    private var saveFlushTask: Task<Void, Never>?

    /// Delete notifications only carry a `PersistentIdentifier` — the model
    /// itself is already gone from the context by then — so these caches
    /// are populated on every insert/update/pull and consulted on delete.
    private var motorcycleIDs: [PersistentIdentifier: UUID] = [:]
    private var maintenanceItemIDs: [PersistentIdentifier: UUID] = [:]
    private var tripIDs: [PersistentIdentifier: UUID] = [:]

    private let syncedUIDDefaultsKey = "GarageSyncService.syncedUID"

    // MARK: - Lifecycle

    /// Call when a rider signs in. Safe to call repeatedly with the same
    /// uid (no-ops after the first call).
    func start(uid: String, context: ModelContext) {
        guard currentUID != uid else { return }
        stop()
        modelContext = context
        currentUID = uid

        Task { @MainActor in
            await self.reconcileLocalData(forUID: uid, context: context)
            self.populateIdentifierCaches(context: context)
            self.attachLocalSaveObserver(context: context)
            self.attachRemoteListeners(uid: uid, context: context)
            self.startSaveFlushLoop(context: context)
        }
    }

    /// Most Garage/Maintenance/Trips views mutate `@Bindable` model
    /// properties directly (a mileage stepper, a photo picker) without ever
    /// calling `context.save()` themselves — they rely on SwiftData's
    /// implicit autosave, which only fires on scene-phase changes like
    /// backgrounding, not promptly after every edit. Since the entire
    /// local -> cloud push pipeline is driven by `ModelContext.didSave`,
    /// an edit sitting unsaved for minutes means it sits unsynced for
    /// minutes too. Polling `hasChanges` on a short interval bounds that
    /// staleness without having to audit every mutation site in the app.
    private func startSaveFlushLoop(context: ModelContext) {
        saveFlushTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if context.hasChanges {
                    do {
                        try context.save()
                    } catch {
                        garageSyncDebugLog("flush loop save FAILED: \(error)")
                    }
                }
            }
        }
    }

    /// Tears down listeners/observers without touching local data — used
    /// both standalone (app backgrounding) and as the first step of
    /// `signOutAndStop`.
    func stop() {
        saveFlushTask?.cancel()
        saveFlushTask = nil
        if let localSaveObserver {
            NotificationCenter.default.removeObserver(localSaveObserver)
        }
        localSaveObserver = nil
        motorcyclesListener?.remove()
        maintenanceItemsListener?.remove()
        tripsListener?.remove()
        motorcyclesListener = nil
        maintenanceItemsListener = nil
        tripsListener = nil
        motorcycleIDs.removeAll()
        maintenanceItemIDs.removeAll()
        tripIDs.removeAll()
        currentUID = nil
    }

    /// Call right before signing out — e.g. a rider adds a bike and taps
    /// Sign Out moments later, before the `didSave` observer (dispatched
    /// asynchronously on the main queue, not synchronously from
    /// `context.save()`) has even run, let alone before its `setData` call
    /// reached the server. A brief sleep gives that queued dispatch a
    /// chance to actually run and issue its writes, then
    /// `waitForPendingWrites()` blocks until those specific writes are
    /// acknowledged.
    func flushBeforeSignOut() async {
        guard let modelContext else { return }
        try? modelContext.save()
        try? await Task.sleep(for: .milliseconds(100))
        try? await db.waitForPendingWrites()
    }

    /// Call when a rider signs out. The local Garage is the source of
    /// truth now (sign-in is only for the optional website mirror), so this
    /// just tears down listeners — it must NEVER delete local data.
    func signOutAndStop() {
        stop()
        UserDefaults.standard.removeObject(forKey: syncedUIDDefaultsKey)
        modelContext = nil
    }

    // MARK: - First-sign-in migration

    /// Local data belongs to the device, not the account — signing in (even
    /// with a different uid than last time) just mirrors whatever's already
    /// here up to that account. Firestore writes use the model's own UUID
    /// as the document ID, so re-running this under a new uid is harmless
    /// (merge, not duplicate or collision with the previous account's data).
    private func reconcileLocalData(forUID uid: String, context: ModelContext) async {
        await uploadAllLocalData(uid: uid, context: context)
        UserDefaults.standard.set(uid, forKey: syncedUIDDefaultsKey)
    }

    /// One-time upload of whatever's already on this device — the rider's
    /// existing bikes/trips from before this account ever touched
    /// Firestore. Firestore writes use the model's own UUID as the
    /// document ID, so running this twice is harmless (merge, not
    /// duplicate).
    private func uploadAllLocalData(uid: String, context: ModelContext) async {
        let motorcycles = (try? context.fetch(FetchDescriptor<Motorcycle>())) ?? []
        for motorcycle in motorcycles {
            await uploadPhotoIfNeeded(motorcycle: motorcycle, uid: uid)
            try? await db.collection("users").document(uid).collection("motorcycles")
                .document(motorcycle.id.uuidString).setData(motorcycle.firestoreData, merge: true)
        }

        let items = (try? context.fetch(FetchDescriptor<MaintenanceItem>())) ?? []
        for item in items {
            guard let motorcycleId = item.motorcycle?.id else { continue }
            try? await db.collection("users").document(uid).collection("maintenanceItems")
                .document(item.id.uuidString).setData(item.firestoreData(motorcycleId: motorcycleId), merge: true)
        }

        let trips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        for trip in trips {
            await uploadRouteIfNeeded(trip: trip, uid: uid)
            try? await db.collection("users").document(uid).collection("trips")
                .document(trip.id.uuidString).setData(trip.firestoreData(motorcycleId: trip.motorcycle?.id), merge: true)
        }

        try? context.save()
    }

    // MARK: - Local -> cloud

    private func populateIdentifierCaches(context: ModelContext) {
        for motorcycle in (try? context.fetch(FetchDescriptor<Motorcycle>())) ?? [] {
            motorcycleIDs[motorcycle.persistentModelID] = motorcycle.id
        }
        for item in (try? context.fetch(FetchDescriptor<MaintenanceItem>())) ?? [] {
            maintenanceItemIDs[item.persistentModelID] = item.id
        }
        for trip in (try? context.fetch(FetchDescriptor<Trip>())) ?? [] {
            tripIDs[trip.persistentModelID] = trip.id
        }
    }

    private func attachLocalSaveObserver(context: ModelContext) {
        localSaveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: context, queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            // Extracted here, synchronously, rather than passed into the
            // Task below — `Notification` itself isn't Sendable, but the
            // identifier sets inside its userInfo are.
            // `userInfo` is keyed by `NotificationKey.rawValue` ("inserted",
            // "updated", "deleted"), NOT by the enum case itself — subscripting
            // with the bare enum case silently misses (two different concrete
            // types never compare equal as `AnyHashable`, regardless of a
            // matching rawValue), and the values are plain `Array`, not `Set`.
            // Confirmed by dumping the raw dictionary on-device; every save
            // was reporting a false "nothing changed" because of this.
            let userInfo = notification.userInfo
            let inserted = Set((userInfo?[ModelContext.NotificationKey.insertedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? [])
            let updated = Set((userInfo?[ModelContext.NotificationKey.updatedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? [])
            let deleted = Set((userInfo?[ModelContext.NotificationKey.deletedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? [])
            Task { @MainActor in
                self.handleLocalSave(inserted: inserted, updated: updated, deleted: deleted, context: context)
            }
        }
    }

    private func handleLocalSave(
        inserted: Set<PersistentIdentifier>, updated: Set<PersistentIdentifier>, deleted: Set<PersistentIdentifier>, context: ModelContext
    ) {
        guard !isApplyingRemote, let uid = currentUID else { return }

        for identifier in inserted.union(updated) {
            pushUpsert(identifier: identifier, context: context, uid: uid)
        }
        for identifier in deleted {
            pushDelete(identifier: identifier, uid: uid)
        }
    }

    /// `registeredModel<T>(for:)` is documented to return `nil` when the
    /// identifier doesn't match `T`, but in practice it force-casts and
    /// traps instead — confirmed on-device ("Could not cast value of type
    /// 'MaintenanceItem' ... to 'Motorcycle'") once a save actually mixed
    /// identifier types (adding a bike inserts its default maintenance
    /// items in the same save). Checking `entityName` first means we only
    /// ever call `registeredModel` with the type that identifier actually
    /// is, never relying on that mismatch-safety.
    private func pushUpsert(identifier: PersistentIdentifier, context: ModelContext, uid: String) {
        switch identifier.entityName {
        case "Motorcycle":
            guard let motorcycle: Motorcycle = context.registeredModel(for: identifier) else { return }
            motorcycleIDs[identifier] = motorcycle.id
            motorcycle.updatedAt = Date()
            db.collection("users").document(uid).collection("motorcycles")
                .document(motorcycle.id.uuidString).setData(motorcycle.firestoreData, merge: true) { error in
                    if let error { garageSyncDebugLog("motorcycle push FAILED: \(error)") }
                }
            Task { @MainActor in await self.uploadPhotoIfNeeded(motorcycle: motorcycle, uid: uid) }
        case "MaintenanceItem":
            guard let item: MaintenanceItem = context.registeredModel(for: identifier),
                  let motorcycleId = item.motorcycle?.id else { return }
            maintenanceItemIDs[identifier] = item.id
            item.updatedAt = Date()
            db.collection("users").document(uid).collection("maintenanceItems")
                .document(item.id.uuidString).setData(item.firestoreData(motorcycleId: motorcycleId), merge: true) { error in
                    if let error { garageSyncDebugLog("maintenanceItem push FAILED: \(error)") }
                }
        case "Trip":
            guard let trip: Trip = context.registeredModel(for: identifier) else { return }
            tripIDs[identifier] = trip.id
            trip.updatedAt = Date()
            db.collection("users").document(uid).collection("trips")
                .document(trip.id.uuidString).setData(trip.firestoreData(motorcycleId: trip.motorcycle?.id), merge: true) { error in
                    if let error { garageSyncDebugLog("trip push FAILED: \(error)") }
                }
            Task { @MainActor in await self.uploadRouteIfNeeded(trip: trip, uid: uid) }
        default:
            break
        }
    }

    private func pushDelete(identifier: PersistentIdentifier, uid: String) {
        if let id = motorcycleIDs.removeValue(forKey: identifier) {
            db.collection("users").document(uid).collection("motorcycles").document(id.uuidString).delete()
            let ref = storage.reference().child("motorcycle_photos/\(uid)/\(id.uuidString)")
            Task { @MainActor in try? await ref.delete() }
        } else if let id = maintenanceItemIDs.removeValue(forKey: identifier) {
            db.collection("users").document(uid).collection("maintenanceItems").document(id.uuidString).delete()
        } else if let id = tripIDs.removeValue(forKey: identifier) {
            db.collection("users").document(uid).collection("trips").document(id.uuidString).delete()
            let ref = storage.reference().child("trip_routes/\(uid)/\(id.uuidString)")
            Task { @MainActor in try? await ref.delete() }
        }
    }

    // MARK: - Cloud -> local

    private func attachRemoteListeners(uid: String, context: ModelContext) {
        let userDoc = db.collection("users").document(uid)

        motorcyclesListener = userDoc.collection("motorcycles").addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let snapshot else { return }
            Task { @MainActor in self.applyMotorcycleChanges(snapshot.documentChanges, context: context, uid: uid) }
        }
        maintenanceItemsListener = userDoc.collection("maintenanceItems").addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let snapshot else { return }
            Task { @MainActor in self.applyMaintenanceItemChanges(snapshot.documentChanges, context: context) }
        }
        tripsListener = userDoc.collection("trips").addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let snapshot else { return }
            Task { @MainActor in self.applyTripChanges(snapshot.documentChanges, context: context, uid: uid) }
        }
    }

    private func applyMotorcycleChanges(_ changes: [DocumentChange], context: ModelContext, uid: String) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        for change in changes {
            guard let id = UUID(uuidString: change.document.documentID) else { continue }
            let existing = try? context.fetch(FetchDescriptor<Motorcycle>(predicate: #Predicate { $0.id == id })).first

            switch change.type {
            case .added, .modified:
                if let existing {
                    existing.apply(change.document.data())
                    motorcycleIDs[existing.persistentModelID] = id
                } else if let created = Motorcycle(id: id, data: change.document.data()) {
                    context.insert(created)
                    motorcycleIDs[created.persistentModelID] = id
                }
            case .removed:
                if let existing {
                    motorcycleIDs.removeValue(forKey: existing.persistentModelID)
                    context.delete(existing)
                }
            }
        }
        try? context.save()

        for change in changes where change.type != .removed {
            guard let id = UUID(uuidString: change.document.documentID),
                  let motorcycle = try? context.fetch(FetchDescriptor<Motorcycle>(predicate: #Predicate { $0.id == id })).first
            else { continue }
            Task { @MainActor in await self.downloadPhotoIfNeeded(motorcycle: motorcycle, context: context) }
        }
    }

    private func applyMaintenanceItemChanges(_ changes: [DocumentChange], context: ModelContext) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        for change in changes {
            guard let id = UUID(uuidString: change.document.documentID) else { continue }
            let existing = try? context.fetch(FetchDescriptor<MaintenanceItem>(predicate: #Predicate { $0.id == id })).first

            switch change.type {
            case .added, .modified:
                let data = change.document.data()
                if let existing {
                    existing.apply(data)
                    maintenanceItemIDs[existing.persistentModelID] = id
                } else {
                    guard let motorcycleIdString = data["motorcycleId"] as? String,
                          let motorcycleId = UUID(uuidString: motorcycleIdString),
                          let motorcycle = try? context.fetch(
                            FetchDescriptor<Motorcycle>(predicate: #Predicate { $0.id == motorcycleId })
                          ).first,
                          let created = MaintenanceItem(id: id, data: data) else { continue }
                    created.motorcycle = motorcycle
                    context.insert(created)
                    maintenanceItemIDs[created.persistentModelID] = id
                }
            case .removed:
                if let existing {
                    maintenanceItemIDs.removeValue(forKey: existing.persistentModelID)
                    context.delete(existing)
                }
            }
        }
        try? context.save()
    }

    private func applyTripChanges(_ changes: [DocumentChange], context: ModelContext, uid: String) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        for change in changes {
            guard let id = UUID(uuidString: change.document.documentID) else { continue }
            let existing = try? context.fetch(FetchDescriptor<Trip>(predicate: #Predicate { $0.id == id })).first

            switch change.type {
            case .added, .modified:
                let data = change.document.data()
                if let existing {
                    existing.apply(data)
                    tripIDs[existing.persistentModelID] = id
                } else if let created = Trip(id: id, data: data) {
                    if let motorcycleIdString = data["motorcycleId"] as? String,
                       let motorcycleId = UUID(uuidString: motorcycleIdString) {
                        created.motorcycle = try? context.fetch(
                            FetchDescriptor<Motorcycle>(predicate: #Predicate { $0.id == motorcycleId })
                        ).first
                    }
                    context.insert(created)
                    tripIDs[created.persistentModelID] = id
                }
            case .removed:
                if let existing {
                    tripIDs.removeValue(forKey: existing.persistentModelID)
                    context.delete(existing)
                }
            }
        }
        try? context.save()

        for change in changes where change.type != .removed {
            guard let id = UUID(uuidString: change.document.documentID),
                  let trip = try? context.fetch(FetchDescriptor<Trip>(predicate: #Predicate { $0.id == id })).first
            else { continue }
            Task { @MainActor in await self.downloadRouteIfNeeded(trip: trip, context: context) }
        }
    }

    // MARK: - Photo / route binary sync (Storage, not Firestore)

    private func uploadPhotoIfNeeded(motorcycle: Motorcycle, uid: String) async {
        guard let data = motorcycle.photoData, motorcycle.photoURL == nil else { return }
        let ref = storage.reference().child("motorcycle_photos/\(uid)/\(motorcycle.id.uuidString)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        guard (try? await ref.putDataAsync(data, metadata: metadata)) != nil,
              let url = try? await ref.downloadURL() else { return }
        motorcycle.photoURL = url.absoluteString
        try? modelContext?.save()
        try? await db.collection("users").document(uid).collection("motorcycles")
            .document(motorcycle.id.uuidString).updateData(["photoURL": url.absoluteString])
    }

    private func downloadPhotoIfNeeded(motorcycle: Motorcycle, context: ModelContext) async {
        guard motorcycle.photoData == nil, let urlString = motorcycle.photoURL,
              let url = URL(string: urlString) else { return }
        let ref = storage.reference(forURL: url.absoluteString)
        guard let data = try? await ref.data(maxSize: 10 * 1024 * 1024) else { return }
        motorcycle.photoData = data
        try? context.save()
    }

    private func uploadRouteIfNeeded(trip: Trip, uid: String) async {
        guard let data = trip.routeData, trip.routeURL == nil else { return }
        let ref = storage.reference().child("trip_routes/\(uid)/\(trip.id.uuidString)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/json"
        guard (try? await ref.putDataAsync(data, metadata: metadata)) != nil,
              let url = try? await ref.downloadURL() else { return }
        trip.routeURL = url.absoluteString
        try? modelContext?.save()
        try? await db.collection("users").document(uid).collection("trips")
            .document(trip.id.uuidString).updateData(["routeURL": url.absoluteString])
    }

    private func downloadRouteIfNeeded(trip: Trip, context: ModelContext) async {
        guard trip.routeData == nil, let urlString = trip.routeURL,
              let url = URL(string: urlString) else { return }
        let ref = storage.reference(forURL: url.absoluteString)
        guard let data = try? await ref.data(maxSize: 10 * 1024 * 1024) else { return }
        trip.routeData = data
        try? context.save()
    }
}
