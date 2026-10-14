//
//  MaintenanceDashboardView.swift
//  MotoLog
//

import SwiftUI
import SwiftData

struct MaintenanceDashboardView: View {
    @Query(sort: \Motorcycle.dateAdded) private var motorcycles: [Motorcycle]
    @Environment(AppState.self) private var appState

    private var selectedMotorcycle: Motorcycle? {
        guard let id = appState.selectedMotorcycleID else { return motorcycles.first }
        return motorcycles.first(where: { $0.id == id }) ?? motorcycles.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let motorcycle = selectedMotorcycle {
                    List {
                        Section {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(motorcycle.displayName).font(.headline)
                                    Text("\(motorcycle.currentMileage) mi").foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadge(status: motorcycle.overallStatus)
                            }
                        }
                        Section("Maintenance") {
                            MaintenanceSectionView(motorcycle: motorcycle)
                        }
                        Section {
                            NavigationLink {
                                PartsBrowseView()
                            } label: {
                                Label("Shop Parts", systemImage: "shippingbox.fill")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.top, 16, for: .scrollContent)
                } else {
                    ContentUnavailableView {
                        Label("No Motorcycle Selected", systemImage: "wrench.and.screwdriver")
                    } description: {
                        Text("Add a motorcycle in the Garage tab to start tracking maintenance.")
                    } actions: {
                        Button("Go to Garage") { appState.selectedTab = .garage }
                            .buttonStyle(.primaryAction)
                            .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Maintenance")
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
}

#Preview {
    MaintenanceDashboardView()
        .environment(AppState())
        .modelContainer(for: [Motorcycle.self, MaintenanceItem.self], inMemory: true)
}
