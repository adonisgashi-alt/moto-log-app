//
//  MaintenanceType.swift
//  MotoLog
//

import Foundation

enum MaintenanceType: String, Codable, CaseIterable, Identifiable {
    case oilChange
    case chain
    case belt
    case shaft
    case brakes
    case tires
    case custom

    var id: String { rawValue }

    var defaultName: String {
        switch self {
        case .oilChange: return "Oil Change"
        case .chain: return "Chain Service"
        case .belt: return "Belt Inspection"
        case .shaft: return "Shaft Drive Service"
        case .brakes: return "Brake Service"
        case .tires: return "Tires"
        case .custom: return "Custom"
        }
    }

    var defaultIntervalMiles: Int {
        switch self {
        case .oilChange: return 3000
        case .chain: return 500
        case .belt: return 5000
        case .shaft: return 12000
        case .brakes: return 1000
        case .tires: return 5000
        case .custom: return 1000
        }
    }

    /// Generic fallback time-based interval, used when a bike isn't in the
    /// researched catalog. Brake fluid is a fixed 24-month industry standard
    /// (DOT fluid is hygroscopic) regardless of make/model, so it's not
    /// overridden by catalog data the way mileage intervals are.
    var defaultIntervalMonths: Int {
        switch self {
        case .oilChange: return 6
        case .chain: return 6
        case .belt: return 12
        case .shaft: return 12
        case .brakes: return 24
        case .tires: return 12
        case .custom: return 12
        }
    }

    var systemImage: String {
        switch self {
        case .oilChange: return "drop.fill"
        case .chain: return "link"
        case .belt: return "arrow.triangle.2.circlepath"
        case .shaft: return "gearshape.2.fill"
        case .brakes: return "circle.hexagongrid.fill"
        case .tires: return "circle.dashed"
        case .custom: return "wrench.and.screwdriver.fill"
        }
    }

    /// Search keywords used when building a parts-retailer search URL.
    var partSearchKeyword: String {
        switch self {
        case .oilChange: return "oil filter"
        case .chain: return "drive chain"
        case .belt: return "drive belt"
        case .shaft: return "shaft drive gear oil"
        case .brakes: return "brake pads"
        case .tires: return "tires"
        case .custom: return ""
        }
    }
}
