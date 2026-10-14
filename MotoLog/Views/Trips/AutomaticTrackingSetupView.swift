//
//  AutomaticTrackingSetupView.swift
//  MotoLog
//

import SwiftUI

/// Explain-first permission walkthrough for automatic ride detection.
/// Location has to be requested in two steps — When In Use, then the
/// upgrade to Always — since iOS refuses to grant Always directly from a
/// `.notDetermined` state. Motion is a separate, independent permission.
/// Denying anything here is a dead end only for automatic detection; the
/// rest of the app, including manual "Start Riding", keeps working either way.
struct AutomaticTrackingSetupView: View {
    @Environment(RidePermissionsService.self) private var permissions
    @Environment(AppSettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "location.fill.viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Automatic Ride Tracking")
                            .font(.title2.weight(.bold))
                        Text("MotoLog can detect when you start riding and track mileage in the background, with no need to open the app or tap Start Riding. This needs two permissions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        permissionRow(
                            icon: "location.fill",
                            title: "Location: Always",
                            description: "Lets MotoLog keep tracking a ride after you lock your phone or switch apps.",
                            status: locationStatusText,
                            isComplete: permissions.locationPermission == .always,
                            action: locationAction
                        )
                        permissionRow(
                            icon: "figure.walk.motion",
                            title: "Motion & Fitness",
                            description: "Lets MotoLog notice when you're moving like you're on a ride, so it knows when to start.",
                            status: motionStatusText,
                            isComplete: permissions.motionPermission == .granted,
                            action: requestMotion
                        )
                    }

                    if isFullyGranted {
                        Label("You're all set — MotoLog will detect rides automatically.", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("You can turn this off anytime in Settings. Manual ride logging always works, regardless of what you choose here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Automatic Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        settings.isAutomaticTrackingEnabled = isFullyGranted
                        dismiss()
                    }
                }
            }
            .onAppear { permissions.refreshStatuses() }
            .onChange(of: scenePhase) { _, newPhase in
                // Catches a rider going to Settings.app to flip a denied
                // permission and coming straight back, rather than only
                // refreshing on the next explicit button tap.
                if newPhase == .active { permissions.refreshStatuses() }
            }
        }
    }

    private var isFullyGranted: Bool {
        permissions.locationPermission == .always && permissions.motionPermission == .granted
    }

    private var locationStatusText: String {
        switch permissions.locationPermission {
        case .notDetermined: return "Not requested yet"
        case .whenInUseOnly: return "Only while using the app — needs the Always upgrade"
        case .always: return "Granted"
        case .denied: return "Denied — enable in Settings"
        case .restricted: return "Restricted on this device"
        }
    }

    private var motionStatusText: String {
        switch permissions.motionPermission {
        case .notDetermined: return "Not requested yet"
        case .granted: return "Granted"
        case .denied: return "Denied — enable in Settings"
        case .restricted: return "Restricted on this device"
        }
    }

    private func locationAction() {
        switch permissions.locationPermission {
        case .notDetermined:
            permissions.requestWhenInUseLocation()
        case .whenInUseOnly:
            permissions.requestAlwaysLocation()
        case .denied, .restricted:
            openSystemSettings()
        case .always:
            break
        }
    }

    private func requestMotion() {
        switch permissions.motionPermission {
        case .notDetermined:
            permissions.requestMotionAuthorization {}
        case .denied, .restricted:
            openSystemSettings()
        case .granted:
            break
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @ViewBuilder
    private func permissionRow(icon: String, title: String, description: String, status: String, isComplete: Bool, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : icon)
                .font(.title3)
                .foregroundStyle(isComplete ? .green : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(status)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isComplete ? .green : .secondary)
            }

            Spacer()

            if !isComplete {
                Button("Allow", action: action)
                    .buttonStyle(.compactProminent)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    AutomaticTrackingSetupView()
        .environment(RidePermissionsService())
        .environment(AppSettingsStore())
}
