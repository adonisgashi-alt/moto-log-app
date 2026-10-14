//
//  MotoLogApp.swift
//  MotoLog
//
//  Created by Adonis Gashi on 10/2/26.
//

import SwiftUI
import SwiftData
import GoogleSignIn
import FirebaseCore

@main
struct MotoLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(for: [Motorcycle.self, MaintenanceItem.self, Trip.self])
        .environment(appDelegate.appSettings)
        .environment(appDelegate.ridePermissions)
        .environment(appDelegate.rideTracking)
        .environment(appDelegate.autoRideDetection)
    }
}
