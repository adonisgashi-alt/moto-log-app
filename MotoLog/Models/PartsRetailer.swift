//
//  PartsRetailer.swift
//  MotoLog
//

import Foundation

/// A motorcycle parts retailer the Parts tab can deep-link searches to.
///
/// Only RevZilla's search URL pattern (`/search?query=`) is a verified direct
/// link — confirmed to actually filter by the search term. The other four
/// were tested directly (fetching `/search?q=<term>` and inspecting the
/// response) and their `q` parameter is silently ignored: Cycle Gear and
/// Dennis Kirk both render their full unfiltered catalog (10,000 and
/// 149,780 "results") no matter what the query says, rather than real
/// matches. Guessing at another unverified parameter name wouldn't be any
/// more trustworthy, so these four instead route through a site-scoped
/// Google search, which reliably surfaces real matching products on that
/// retailer's own site regardless of how its internal search is built.
enum PartsRetailer: String, CaseIterable, Identifiable {
    case revzilla
    case cycleGear
    case jpCycles
    case dennisKirk
    case bikeBandit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .revzilla: return "RevZilla"
        case .cycleGear: return "Cycle Gear"
        case .jpCycles: return "J&P Cycles"
        case .dennisKirk: return "Dennis Kirk"
        case .bikeBandit: return "BikeBandit"
        }
    }

    private var siteDomain: String? {
        switch self {
        case .revzilla: return nil
        case .cycleGear: return "cyclegear.com"
        case .jpCycles: return "jpcycles.com"
        case .dennisKirk: return "denniskirk.com"
        case .bikeBandit: return "bikebandit.com"
        }
    }

    func searchURL(terms: String) -> URL {
        guard let siteDomain else {
            var components = URLComponents(string: "https://www.revzilla.com/search")!
            components.queryItems = [URLQueryItem(name: "query", value: terms)]
            return components.url!
        }
        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: "site:\(siteDomain) \(terms)")]
        return components.url!
    }
}
