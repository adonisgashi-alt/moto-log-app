//
//  MotorcycleCatalog.swift
//  MotoLog
//

import Foundation

/// Manufacturer-sourced reference data for a specific motorcycle model, used to
/// seed sensible default maintenance intervals when a bike is added. These are
/// researched defaults (owner's manual / manufacturer spec data where available,
/// otherwise a category-based estimate) — riders can still edit intervals per bike.
struct MotorcycleModelInfo: Hashable {
    let name: String
    let oilChangeIntervalMiles: Int
    /// The time-based half of "X miles or Y months, whichever comes first" —
    /// applied to oil, final-drive, and tire inspection items.
    let serviceIntervalMonths: Int
    let finalDriveType: MaintenanceType
    let finalDriveIntervalMiles: Int
    let brakeInspectionIntervalMiles: Int
    let tireInspectionIntervalMiles: Int
}

/// Static reference data used to populate make/model pickers.
/// Users can always fall back to "Other" and type a custom make/model,
/// which uses generic MaintenanceType defaults instead of model-specific ones.
enum MotorcycleCatalog {
    static let other = "Other"

    static let makesAndModels: [String: [MotorcycleModelInfo]] = [
        "Honda": [
            MotorcycleModelInfo(name: "CBR600RR", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "CBR1000RR-R", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "CB500F", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "CB650R", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Africa Twin", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Rebel 500", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Gold Wing", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 24000, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Shadow Phantom", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 24000, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "CB300R", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "CRF300L", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "CB1000R", oilChangeIntervalMiles: 8000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000)
        ],
        "Yamaha": [
            MotorcycleModelInfo(name: "YZF-R1", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "YZF-R6", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "YZF-R3", oilChangeIntervalMiles: 3000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "MT-07", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "MT-09", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "MT-03", oilChangeIntervalMiles: 3000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "Tenere 700", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Bolt", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "V Star 250", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 300, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "XSR900", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "XSR700", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "R7", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000)
        ],
        "Kawasaki": [
            MotorcycleModelInfo(name: "Ninja ZX-6R", oilChangeIntervalMiles: 7600, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 400, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Ninja ZX-10R", oilChangeIntervalMiles: 7500, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 400, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Ninja 400", oilChangeIntervalMiles: 7600, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 400, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Ninja 650", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 400, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Z900", oilChangeIntervalMiles: 7600, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Z650", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Versys 650", oilChangeIntervalMiles: 7500, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Vulcan S", oilChangeIntervalMiles: 7500, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "KLR650", oilChangeIntervalMiles: 7600, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000)
        ],
        "Suzuki": [
            MotorcycleModelInfo(name: "GSX-R600", oilChangeIntervalMiles: 3750, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "GSX-R750", oilChangeIntervalMiles: 3750, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "GSX-R1000", oilChangeIntervalMiles: 3500, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "SV650", oilChangeIntervalMiles: 3800, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "V-Strom 650", oilChangeIntervalMiles: 3500, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Boulevard C50", oilChangeIntervalMiles: 4000, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 8000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "GSX-8S", oilChangeIntervalMiles: 3750, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "GSX-S750", oilChangeIntervalMiles: 3500, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000)
        ],
        "Ducati": [
            MotorcycleModelInfo(name: "Panigale V2", oilChangeIntervalMiles: 9000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Panigale V4", oilChangeIntervalMiles: 7500, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Monster", oilChangeIntervalMiles: 7500, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Multistrada V4", oilChangeIntervalMiles: 9000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "Scrambler Icon", oilChangeIntervalMiles: 7500, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "Diavel", oilChangeIntervalMiles: 9000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "SuperSport 950", oilChangeIntervalMiles: 9000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000)
        ],
        "Harley-Davidson": [
            MotorcycleModelInfo(name: "Sportster S", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Iron 883", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Street Bob", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Road King", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Fat Boy", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Street Glide", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Nightster", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Low Rider S", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 12, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000)
        ],
        "BMW": [
            MotorcycleModelInfo(name: "S 1000 RR", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "F 900 R", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 400, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "R 1250 GS", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 12000, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "G 310 R", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 400, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "R nineT", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 12000, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "F 850 GS", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 400, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "K 1600 GT", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 12000, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000)
        ],
        "KTM": [
            MotorcycleModelInfo(name: "390 Duke", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "890 Duke", oilChangeIntervalMiles: 9300, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "1290 Super Duke R", oilChangeIntervalMiles: 9300, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "690 Enduro R", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "890 Adventure", oilChangeIntervalMiles: 9300, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000),
            MotorcycleModelInfo(name: "125 Duke", oilChangeIntervalMiles: 4650, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4000, tireInspectionIntervalMiles: 4000)
        ],
        "Triumph": [
            MotorcycleModelInfo(name: "Street Triple", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "Speed Triple", oilChangeIntervalMiles: 10000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 10000, tireInspectionIntervalMiles: 10000),
            MotorcycleModelInfo(name: "Bonneville T120", oilChangeIntervalMiles: 10000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 10000, tireInspectionIntervalMiles: 10000),
            MotorcycleModelInfo(name: "Tiger 900", oilChangeIntervalMiles: 6000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 6000, tireInspectionIntervalMiles: 6000),
            MotorcycleModelInfo(name: "Trident 660", oilChangeIntervalMiles: 10000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 10000, tireInspectionIntervalMiles: 10000),
            MotorcycleModelInfo(name: "Scrambler 900", oilChangeIntervalMiles: 10000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 10000, tireInspectionIntervalMiles: 10000)
        ],
        "Royal Enfield": [
            MotorcycleModelInfo(name: "Classic 350", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "Meteor 350", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "Interceptor 650", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "Continental GT 650", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "Himalayan", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 300, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "Hunter 350", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000)
        ],
        "Aprilia": [
            MotorcycleModelInfo(name: "RS 660", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 6200, tireInspectionIntervalMiles: 6200),
            MotorcycleModelInfo(name: "Tuono 660", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 6200, tireInspectionIntervalMiles: 6200),
            MotorcycleModelInfo(name: "RSV4", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "Tuareg 660", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 6200, tireInspectionIntervalMiles: 6200)
        ],
        "Moto Guzzi": [
            MotorcycleModelInfo(name: "V7", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 12000, brakeInspectionIntervalMiles: 6200, tireInspectionIntervalMiles: 6200),
            MotorcycleModelInfo(name: "V85 TT", oilChangeIntervalMiles: 6200, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 18000, brakeInspectionIntervalMiles: 6200, tireInspectionIntervalMiles: 6200),
            MotorcycleModelInfo(name: "V100 Mandello", oilChangeIntervalMiles: 7500, serviceIntervalMonths: 12, finalDriveType: .shaft, finalDriveIntervalMiles: 15000, brakeInspectionIntervalMiles: 7500, tireInspectionIntervalMiles: 7500)
        ],
        "Husqvarna": [
            MotorcycleModelInfo(name: "Svartpilen 401", oilChangeIntervalMiles: 4650, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4650, tireInspectionIntervalMiles: 4650),
            MotorcycleModelInfo(name: "Vitpilen 401", oilChangeIntervalMiles: 4650, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 4650, tireInspectionIntervalMiles: 4650),
            MotorcycleModelInfo(name: "Norden 901", oilChangeIntervalMiles: 9300, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 500, brakeInspectionIntervalMiles: 9300, tireInspectionIntervalMiles: 9300)
        ],
        "Indian": [
            MotorcycleModelInfo(name: "Scout", oilChangeIntervalMiles: 10000, serviceIntervalMonths: 6, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Chief", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 6, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "Chieftain", oilChangeIntervalMiles: 5000, serviceIntervalMonths: 6, finalDriveType: .belt, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000),
            MotorcycleModelInfo(name: "FTR", oilChangeIntervalMiles: 10000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 5000, brakeInspectionIntervalMiles: 5000, tireInspectionIntervalMiles: 5000)
        ],
        "CFMoto": [
            MotorcycleModelInfo(name: "300NK", oilChangeIntervalMiles: 3000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "700CL-X", oilChangeIntervalMiles: 3000, serviceIntervalMonths: 12, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000),
            MotorcycleModelInfo(name: "450MT", oilChangeIntervalMiles: 3000, serviceIntervalMonths: 6, finalDriveType: .chain, finalDriveIntervalMiles: 600, brakeInspectionIntervalMiles: 3000, tireInspectionIntervalMiles: 3000)
        ]
    ]

    static var allMakes: [String] {
        var makes = makesAndModels.keys.sorted()
        makes.append(other)
        return makes
    }

    /// Model names for a make's picker, with "Other" appended as a free-text fallback.
    static func modelNames(for make: String) -> [String] {
        var names = (makesAndModels[make] ?? []).map(\.name)
        names.append(other)
        return names
    }

    /// Researched maintenance data for a specific make/model, if known.
    static func info(for make: String, modelName: String) -> MotorcycleModelInfo? {
        makesAndModels[make]?.first { $0.name == modelName }
    }
}
