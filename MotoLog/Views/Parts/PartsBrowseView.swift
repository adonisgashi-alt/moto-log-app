//
//  PartsBrowseView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

struct PartsBrowseView: View {
    @Query(sort: \Motorcycle.dateAdded) private var motorcycles: [Motorcycle]
    @Environment(AppState.self) private var appState
    @Environment(AppSettingsStore.self) private var appSettings
    @State private var activeLink: PartsLink?

    private var selectedMotorcycle: Motorcycle? {
        guard let id = appState.selectedMotorcycleID else { return motorcycles.first }
        return motorcycles.first(where: { $0.id == id }) ?? motorcycles.first
    }

    private var finalDriveType: MaintenanceType {
        selectedMotorcycle?.finalDriveType ?? .chain
    }

    var body: some View {
        List {
            if let motorcycle = selectedMotorcycle {
                Section {
                    Text("Searching for your \(motorcycle.displayName)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Browse on \(appSettings.defaultPartsRetailer.displayName)") {
                ForEach(PartCategory.allCases) { category in
                    Button {
                        activeLink = PartsLink(url: RevZillaSearch.url(
                            for: category,
                            motorcycle: selectedMotorcycle,
                            retailer: appSettings.defaultPartsRetailer
                        ))
                    } label: {
                        HStack {
                            Label(
                                category.title(finalDriveType: finalDriveType),
                                systemImage: category.systemImage(finalDriveType: finalDriveType)
                            )
                            .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    // Without this, a List row Button ignores the inner
                    // .foregroundStyle modifiers above and renders its whole
                    // label in the system accent blue instead — the same
                    // fix already used for row buttons in TripsView.
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Parts")
        .sheet(item: $activeLink) { link in
            SafariView(url: link.url)
                .ignoresSafeArea()
        }
        .toolbar {
            if motorcycles.count > 1 {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(motorcycles) { motorcycle in
                            Button {
                                appState.selectedMotorcycleID = motorcycle.id
                            } label: {
                                if motorcycle.id == selectedMotorcycle?.id {
                                    Label(motorcycle.displayName, systemImage: "checkmark")
                                } else {
                                    Text(motorcycle.displayName)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "motorcycle")
                    }
                }
            }
        }
    }
}

private struct PartsLink: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    PartsBrowseView()
        .environment(AppState())
        .environment(AppSettingsStore())
        .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}
