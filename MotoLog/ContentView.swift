//
//  ContentView.swift
//  MotoLog
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    @Query(sort: \Motorcycle.dateAdded) private var motorcycles: [Motorcycle]
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()
    @State private var accountStore = AccountStore()
    @State private var routeSuggestion = RouteSuggestionService()
    @State private var garageSync = GarageSyncService()
    @State private var isSplashVisible = true
    // Owned by AppDelegate, not here — they need to exist before any SwiftUI
    // scene connects so a background location-launch can use them. See
    // AppDelegate.swift.
    @Environment(RideTrackingService.self) private var rideTracking
    @Environment(RidePermissionsService.self) private var ridePermissions
    @Environment(AppSettingsStore.self) private var appSettings
    @Environment(AutomaticRideDetectionService.self) private var autoRideDetection
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Garage/Trips/Maintenance work fully offline — no account
            // required. Signing in (from the Settings tab) only turns on
            // the optional background mirror to Firestore that the
            // companion website reads from.
            TabView(selection: Bindable(appState).selectedTab) {
                Tab("Garage", systemImage: "motorcycle.fill", value: AppTab.garage) {
                    GarageListView()
                }
                Tab("Trips", systemImage: "map.fill", value: AppTab.trips) {
                    TripsView()
                }
                Tab("Maintenance", systemImage: "wrench.and.screwdriver.fill", value: AppTab.maintenance) {
                    MaintenanceDashboardView()
                }
                Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings) {
                    SettingsView()
                }
            }
            .tint(.primary)
            .onAppear { syncSelection() }
            .onChange(of: motorcycles.map(\.id)) { _, _ in syncSelection() }
            .environment(appState)
            .environment(accountStore)
            .environment(rideTracking)
            .environment(ridePermissions)
            .environment(appSettings)
            .environment(routeSuggestion)
            .environment(garageSync)

            if isSplashVisible {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            // No account is required to see the tabs anymore, so there's
            // nothing worth blocking launch on — dismiss immediately.
            // Firebase's auth listener (in AccountStore.init) reports the
            // persisted session asynchronously whenever it resolves, and
            // the onChange below starts the website sync then, with no
            // need to make every cold launch wait on it first.
            withAnimation(.easeOut(duration: 0.25)) {
                isSplashVisible = false
            }
            autoRideDetection.configure(rideTracking: rideTracking, permissions: ridePermissions, settings: appSettings)
            autoRideDetection.refresh()
        }
        .onChange(of: accountStore.firebaseUser?.uid) { oldUID, newUID in
            if let newUID {
                garageSync.start(uid: newUID, context: modelContext)
            } else if oldUID != nil {
                garageSync.signOutAndStop()
            }
        }
        .onChange(of: appSettings.isAutomaticTrackingEnabled) { _, _ in
            autoRideDetection.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Catches permission changes made in Settings.app while MotoLog
            // was backgrounded, the same way AutomaticTrackingSetupView does.
            if newPhase == .active {
                ridePermissions.refreshStatuses()
                autoRideDetection.refresh()
            }
        }
    }

    private func syncSelection() {
        guard let selectedMotorcycleID = appState.selectedMotorcycleID else {
            appState.selectedMotorcycleID = motorcycles.first?.id
            return
        }
        if !motorcycles.contains(where: { $0.id == selectedMotorcycleID }) {
            appState.selectedMotorcycleID = motorcycles.first?.id
        }
    }
}

#Preview {
    ContentView()
        .environment(RideTrackingService())
        .environment(RidePermissionsService())
        .environment(AppSettingsStore())
        .environment(AutomaticRideDetectionService())
        .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}
