//
//  AppState.swift
//  MotoLog
//

import Foundation

enum AppTab: Hashable {
    case garage
    case trips
    case maintenance
    case settings
}

/// Tracks which motorcycle is active for the Maintenance and Parts screens,
/// and allows views to programmatically switch tabs (e.g. "View Maintenance"
/// from a bike's detail screen).
@Observable
final class AppState {
    var selectedMotorcycleID: UUID?
    var selectedTab: AppTab = .garage
}
