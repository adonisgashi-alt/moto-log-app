//
//  SettingsView.swift
//  MotoLog
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(AppSettingsStore.self) private var settings
    @Environment(AccountStore.self) private var accountStore
    @Environment(GarageSyncService.self) private var garageSync
    @Environment(RidePermissionsService.self) private var ridePermissions
    @State private var isShowingSignIn = false
    @State private var isShowingTrackingSetup = false
    @State private var isSigningOut = false
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section {
                    Toggle("Automatically Track Rides", isOn: Binding(
                        get: { settings.isAutomaticTrackingEnabled },
                        set: { newValue in
                            if newValue {
                                isShowingTrackingSetup = true
                            } else {
                                settings.isAutomaticTrackingEnabled = false
                            }
                        }
                    ))
                } header: {
                    Text("Automatic Tracking")
                } footer: {
                    Text("Needs Always-location and Motion & Fitness access. Manual \"Start Riding\" always works regardless of this setting.")
                }

                Section {
                    Picker("Default Retailer", selection: $settings.defaultPartsRetailer) {
                        ForEach(PartsRetailer.allCases) { retailer in
                            Text(retailer.displayName).tag(retailer)
                        }
                    }
                } header: {
                    Text("Parts")
                } footer: {
                    Text("The Parts tab will search this retailer first when you look up parts for your bike.")
                }

                Section {
                    if let user = accountStore.firebaseUser {
                        LabeledContent("Signed in as", value: user.email ?? user.displayName ?? "Account")
                        Button("Sign Out", role: .destructive) {
                            signOut()
                        }
                        .disabled(isSigningOut)
                    } else {
                        Button("Sign In") {
                            isShowingSignIn = true
                        }
                    }
                } header: {
                    Text("Website Sync")
                } footer: {
                    Text("Sign in to mirror your Garage, Maintenance, and Trips to moto-log.app. Everything in this app keeps working fully offline either way.")
                }
            }
            .contentMargins(.top, 16, for: .scrollContent)
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingTrackingSetup) {
                AutomaticTrackingSetupView()
            }
            .sheet(isPresented: $isShowingSignIn) {
                NavigationStack {
                    AuthLandingView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { isShowingSignIn = false }
                            }
                        }
                }
                .onChange(of: accountStore.firebaseUser?.uid) { _, newUID in
                    if newUID != nil { isShowingSignIn = false }
                }
            }
            .alert("Couldn't Sign Out", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func signOut() {
        isSigningOut = true
        Task {
            await garageSync.flushBeforeSignOut()
            do {
                try await accountStore.signOut()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigningOut = false
        }
    }
}
