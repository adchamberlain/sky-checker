import Foundation

struct WeatherData: Codable {
    let cloudCover: Int          // Total cloud cover percentage (0-100)
    let cloudCoverLow: Int       // Low clouds (0-100)
    let cloudCoverMid: Int       // Mid-level clouds (0-100)
    let cloudCoverHigh: Int      // High clouds (0-100)
    let visibility: Double       // Visibility in meters
    let humidity: Int            // Relative humidity percentage
    let windSpeed: Double        // Wind speed in km/h
    let timestamp: Date

    var cloudDescription: String {
        switch cloudCover {
        case 0..<10: return "Clear"
        case 10..<25: return "Mostly Clear"
        case 25..<50: return "Partly Cloudy"
        case 50..<75: return "Mostly Cloudy"
        default: return "Overcast"
        }
    }

    var visibilityDescription: String {
        switch visibility {
        case 20000...: return "Excellent"
        case 10000..<20000: return "Good"
        case 5000..<10000: return "Fair"
        default: return "Poor"
        }
    }

    var observationRating: Int {
        // Calculate a 1-5 star rating based on conditions
        var score = 5.0

        // Cloud cover is most important (0-100, lower is better)
        score -= Double(cloudCover) / 25.0  // -0 to -4 points

        // Visibility bonus/penalty
        if visibility < 10000 { score -= 0.5 }
        if visibility > 20000 { score += 0.5 }

        // High humidity penalty (dew risk)
        if humidity > 85 { score -= 0.5 }

        // High wind penalty (telescope shake)
        if windSpeed > 30 { score -= 0.5 }

        return max(1, min(5, Int(score.rounded())))
    }

    var ratingDescription: String {
        switch observationRating {
        case 5: return "Excellent"
        case 4: return "Good"
        case 3: return "Fair"
        case 2: return "Poor"
        default: return "Bad"
        }
    }

    var ratingStars: String {
        String(repeating: "*", count: observationRating) + String(repeating: "-", count: 5 - observationRating)
    }
}

struct HourlyWeather: Codable {
    let hour: Date
    let cloudCover: Int
    let visibility: Double
    let humidity: Int

    var isGoodForObserving: Bool {
        cloudCover < 30 && visibility > 10000
    }
}

class WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "cloud_cover,relative_humidity_2m,wind_speed_10m"),
            URLQueryItem(name: "hourly", value: "cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,visibility"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        let (data, response) = try await session.data(from: components.url!)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return parseResponse(decoded)
    }

    func fetchHourlyForecast(latitude: Double, longitude: Double, startHour: Date, endHour: Date) async throws -> [HourlyWeather] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: "cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,visibility,relative_humidity_2m"),
            URLQueryItem(name: "forecast_days", value: "2"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        let (data, response) = try await session.data(from: components.url!)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return parseHourlyResponse(decoded, startHour: startHour, endHour: endHour)
    }

    private func parseResponse(_ response: OpenMeteoResponse) -> WeatherData {
        // Get current hour index
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // Find the index for current hour in the hourly data
        let index = min(currentHour, (response.hourly.cloud_cover?.count ?? 1) - 1)

        return WeatherData(
            cloudCover: response.current?.cloud_cover ?? response.hourly.cloud_cover?[index] ?? 0,
            cloudCoverLow: response.hourly.cloud_cover_low?[index] ?? 0,
            cloudCoverMid: response.hourly.cloud_cover_mid?[index] ?? 0,
            cloudCoverHigh: response.hourly.cloud_cover_high?[index] ?? 0,
            visibility: response.hourly.visibility?[index] ?? 20000,
            humidity: response.current?.relative_humidity_2m ?? response.hourly.relative_humidity_2m?[index] ?? 50,
            windSpeed: response.current?.wind_speed_10m ?? 0,
            timestamp: now
        )
    }

    private func parseHourlyResponse(_ response: OpenMeteoResponse, startHour: Date, endHour: Date) -> [HourlyWeather] {
        guard let times = response.hourly.time,
              let cloudCover = response.hourly.cloud_cover,
              let visibility = response.hourly.visibility else {
            return []
        }

        let humidity = response.hourly.relative_humidity_2m ?? Array(repeating: 50, count: times.count)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        var hourlyData: [HourlyWeather] = []

        for i in 0..<times.count {
            // Parse the time string (format: "2025-01-22T18:00")
            let timeString = times[i]
            guard let date = parseOpenMeteoDate(timeString) else { continue }

            // Only include hours within our observation window
            if date >= startHour && date <= endHour {
                hourlyData.append(HourlyWeather(
                    hour: date,
                    cloudCover: cloudCover[i],
                    visibility: visibility[i],
                    humidity: humidity[i]
                ))
            }
        }

        return hourlyData
    }

    private func parseOpenMeteoDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = .current
        return formatter.date(from: string)
    }
}

enum WeatherError: LocalizedError {
    case invalidResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid weather response"
        case .noData: return "No weather data available"
        }
    }
}

// MARK: - Open-Meteo API Response Models

struct OpenMeteoResponse: Codable {
    let current: OpenMeteoCurrent?
    let hourly: OpenMeteoHourly
}

struct OpenMeteoCurrent: Codable {
    let cloud_cover: Int?
    let relative_humidity_2m: Int?
    let wind_speed_10m: Double?
}

struct OpenMeteoHourly: Codable {
    let time: [String]?
    let cloud_cover: [Int]?
    let cloud_cover_low: [Int]?
    let cloud_cover_mid: [Int]?
    let cloud_cover_high: [Int]?
    let visibility: [Double]?
    let relative_humidity_2m: [Int]?
}
