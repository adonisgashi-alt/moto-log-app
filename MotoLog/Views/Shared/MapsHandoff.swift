//
//  MapsHandoff.swift
//  MotoLog
//

import CoreLocation
import MapKit
import UIKit

/// Hands a route off to Apple or Google Maps for turn-by-turn navigation.
/// Shared by `SuggestedRoutesResultView` (a generated loop: origin ->
/// waypoint -> back to origin) and the Feed's "Clone" action on a shared
/// trip (just origin -> destination, no waypoint) — both just need driving
/// directions through zero or one named stop, not an arbitrary polyline.
enum MapsHandoff {
    static func openInAppleMaps(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        waypoint: (coordinate: CLLocationCoordinate2D, name: String)? = nil
    ) {
        let originItem = MKMapItem(location: CLLocation(latitude: origin.latitude, longitude: origin.longitude), address: nil)
        let destinationItem = MKMapItem(location: CLLocation(latitude: destination.latitude, longitude: destination.longitude), address: nil)

        var items = [originItem]
        if let waypoint {
            let waypointItem = MKMapItem(location: CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude), address: nil)
            waypointItem.name = waypoint.name
            items.append(waypointItem)
        }
        items.append(destinationItem)

        MKMapItem.openMaps(
            with: items,
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }

    /// Google's documented "Maps URLs" scheme — a plain https link, so it
    /// works whether or not the Google Maps app is installed (opens the
    /// app if present, falls back to maps.google.com in Safari otherwise)
    /// with no API key and no Info.plist entry needed.
    static func openInGoogleMaps(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        waypoint: CLLocationCoordinate2D? = nil
    ) {
        var components = URLComponents(string: "https://www.google.com/maps/dir/")!
        var queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
        ]
        if let waypoint {
            queryItems.append(URLQueryItem(name: "waypoints", value: "\(waypoint.latitude),\(waypoint.longitude)"))
        }
        queryItems.append(URLQueryItem(name: "travelmode", value: "driving"))
        components.queryItems = queryItems

        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }
}
