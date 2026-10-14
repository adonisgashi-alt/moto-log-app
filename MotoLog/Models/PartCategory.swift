//
//  PartCategory.swift
//  MotoLog
//

import Foundation

enum PartCategory: String, CaseIterable, Identifiable {
    case oilAndFilters
    case finalDrive
    case brakes
    case tires
    case gearAndApparel
    case accessories

    var id: String { rawValue }

    /// The final-drive category's label/icon/keyword depend on the bike's actual
    /// drivetrain (chain/belt/shaft), since "Chain & Sprockets" is meaningless
    /// for a shaft- or belt-drive bike.
    func title(finalDriveType: MaintenanceType) -> String {
        switch self {
        case .oilAndFilters: return "Oil & Filters"
        case .finalDrive:
            switch finalDriveType {
            case .belt: return "Drive Belt"
            case .shaft: return "Shaft Drive"
            default: return "Chain & Sprockets"
            }
        case .brakes: return "Brakes"
        case .tires: return "Tires"
        case .gearAndApparel: return "Gear & Apparel"
        case .accessories: return "Accessories"
        }
    }

    func systemImage(finalDriveType: MaintenanceType) -> String {
        switch self {
        case .oilAndFilters: return "drop.fill"
        case .finalDrive: return finalDriveType.systemImage
        case .brakes: return "circle.hexagongrid.fill"
        case .tires: return "circle.dashed"
        case .gearAndApparel: return "figure.outdoor.cycle"
        case .accessories: return "bag.fill"
        }
    }

    func searchKeyword(finalDriveType: MaintenanceType) -> String {
        switch self {
        case .oilAndFilters: return "oil filter"
        case .finalDrive:
            switch finalDriveType {
            case .belt: return "drive belt"
            case .shaft: return "shaft drive gear oil"
            default: return "drive chain sprocket"
            }
        case .brakes: return "brake pads"
        case .tires: return "motorcycle tires"
        case .gearAndApparel: return "motorcycle riding gear"
        case .accessories: return "motorcycle accessories"
        }
    }
}
