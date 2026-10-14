//
//  RevZillaSearch.swift
//  MotoLog
//

import Foundation

enum RevZillaSearch {
    static func url(for category: PartCategory, motorcycle: Motorcycle?, retailer: PartsRetailer) -> URL {
        let finalDriveType = motorcycle?.finalDriveType ?? .chain
        var terms: [String] = []
        if let motorcycle {
            terms.append("\(motorcycle.year) \(motorcycle.make) \(motorcycle.model)")
        }
        terms.append(category.searchKeyword(finalDriveType: finalDriveType))

        return retailer.searchURL(terms: terms.joined(separator: " "))
    }
}
