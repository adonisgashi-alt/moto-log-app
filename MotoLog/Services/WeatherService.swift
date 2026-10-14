//
//  WeatherService.swift
//  MotoLog
//

import Foundation

/// Looks up the temperature at a coordinate and time using Open-Meteo's free
/// forecast API, which also serves the last couple of days of "recent past"
/// hourly observations with no API key or account needed — a good fit for
/// labeling a ride that just happened with its start/end temperatures.
struct WeatherService {
    enum WeatherError: Error {
        case invalidURL
        case noData
    }

    private struct ForecastResponse: Decodable {
        struct Hourly: Decodable {
            let time: [String]
            let temperature_2m: [Double]
        }
        let hourly: Hourly
    }

    /// Returns the temperature (Fahrenheit) for the hour closest to `date`
    /// at the given coordinate, or nil if the lookup fails for any reason —
    /// callers treat a missing temperature as "don't show a range" rather
    /// than a hard error, since it's a nice-to-have on top of the ride data.
    func temperatureFahrenheit(latitude: Double, longitude: Double, at date: Date) async -> Double? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "timezone", value: "UTC"),
            URLQueryItem(name: "past_days", value: "2"),
            URLQueryItem(name: "forecast_days", value: "1"),
        ]
        guard let url = components?.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            return closestTemperature(in: decoded.hourly, to: date)
        } catch {
            return nil
        }
    }

    private func closestTemperature(in hourly: ForecastResponse.Hourly, to date: Date) -> Double? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")

        var closestIndex: Int?
        var smallestDifference = Double.greatestFiniteMagnitude
        for (index, timeString) in hourly.time.enumerated() {
            guard let hourDate = formatter.date(from: timeString) else { continue }
            let difference = abs(hourDate.timeIntervalSince(date))
            if difference < smallestDifference {
                smallestDifference = difference
                closestIndex = index
            }
        }
        guard let closestIndex, closestIndex < hourly.temperature_2m.count else { return nil }
        return hourly.temperature_2m[closestIndex]
    }
}
