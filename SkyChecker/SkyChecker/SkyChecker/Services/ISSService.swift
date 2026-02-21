import Foundation

/// Service for fetching ISS (International Space Station) pass predictions
/// Uses the Open Notify API (free, no authentication required)
class ISSService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        session = URLSession(configuration: config)
    }

    /// Fetch ISS passes for a given location and time window
    /// - Parameters:
    ///   - location: Observer location
    ///   - startTime: Start of observation window (typically sunset)
    ///   - endTime: End of observation window (typically sunrise)
    /// - Returns: EphemerisData with next visible pass information
    func fetchISSPasses(location: ObserverLocation, startTime: Date, endTime: Date) async throws -> EphemerisData {
        // Use the Open Notify ISS pass prediction API
        // Note: This API returns passes for the next few days from current time
        let urlString = "http://api.open-notify.org/iss-pass.json?lat=\(location.latitude)&lon=\(location.longitude)&n=10"

        guard let url = URL(string: urlString) else {
            throw ISSServiceError.invalidURL
        }

        print("🛸 Fetching ISS passes from Open Notify API...")

        // Retry logic with exponential backoff
        for attempt in 1...3 {
            do {
                let (data, response) = try await session.data(from: url)

                guard let http = response as? HTTPURLResponse else {
                    throw ISSServiceError.invalidResponse
                }

                if http.statusCode != 200 {
                    if attempt < 3 {
                        let waitTime = attempt * 2
                        print("⏳ ISS API returned \(http.statusCode), retrying in \(waitTime)s...")
                        try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                        continue
                    }
                    throw ISSServiceError.apiError("HTTP \(http.statusCode)")
                }

                // Parse the JSON response
                let passResponse = try JSONDecoder().decode(ISSPassResponse.self, from: data)

                if passResponse.message != "success" {
                    throw ISSServiceError.apiError(passResponse.message)
                }

                print("✅ Got \(passResponse.response.count) ISS passes")

                // Find passes within our observation window (tonight)
                return parsePassesToEphemeris(passes: passResponse.response, startTime: startTime, endTime: endTime, location: location)

            } catch let error as ISSServiceError {
                throw error
            } catch {
                if attempt < 3 {
                    let waitTime = attempt * 2
                    print("⏳ ISS fetch error, retrying in \(waitTime)s: \(error)")
                    try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                    continue
                }
                throw ISSServiceError.networkError(error)
            }
        }

        throw ISSServiceError.noData
    }

    /// Parse ISS pass data into EphemerisData format
    private func parsePassesToEphemeris(passes: [ISSPass], startTime: Date, endTime: Date, location: ObserverLocation) -> EphemerisData {
        var data = EphemerisData()

        // Filter passes to those occurring during our observation window
        let tonightPasses = passes.filter { pass in
            let riseTime = Date(timeIntervalSince1970: TimeInterval(pass.risetime))
            return riseTime >= startTime && riseTime <= endTime
        }

        guard let nextPass = tonightPasses.first else {
            print("🛸 No ISS passes tonight within observation window")
            return data
        }

        // Convert the next pass to ephemeris data
        let riseTime = Date(timeIntervalSince1970: TimeInterval(nextPass.risetime))
        let duration = TimeInterval(nextPass.duration)
        let setTime = riseTime.addingTimeInterval(duration)
        let transitTime = riseTime.addingTimeInterval(duration / 2)

        data.riseTime = riseTime
        data.setTime = setTime
        data.transitTime = transitTime

        // ISS passes are typically short (a few minutes) and reach high altitudes
        // The API doesn't provide exact altitude/azimuth, so we estimate
        // ISS typically reaches 30-90° altitude depending on the pass
        data.transitAltitude = 45.0  // Reasonable estimate for a good pass

        // Estimate azimuths based on observer hemisphere
        if location.latitude >= 0 {
            // Northern Hemisphere: ISS transits through south
            data.riseAzimuth = 225.0   // SW
            data.setAzimuth = 45.0     // NE
            data.transitAzimuth = 180.0 // S
        } else {
            // Southern Hemisphere: ISS transits through north
            data.riseAzimuth = 315.0   // NW
            data.setAzimuth = 135.0    // SE
            data.transitAzimuth = 0.0   // N
        }

        // Calculate current position if we're in the observation window
        let now = Date()
        if now >= startTime && now <= endTime {
            if now >= riseTime && now <= setTime {
                // ISS is currently passing overhead
                let progress = now.timeIntervalSince(riseTime) / duration
                data.currentAltitude = data.transitAltitude! * sin(progress * .pi)  // Parabolic approximation
                data.currentAzimuth = data.riseAzimuth! + progress * (data.setAzimuth! - data.riseAzimuth!)
            } else if now < riseTime {
                // ISS not yet risen
                data.currentAltitude = -10.0  // Below horizon
                data.currentAzimuth = data.riseAzimuth
            } else {
                // ISS already set
                data.currentAltitude = -10.0
                data.currentAzimuth = data.setAzimuth
            }
        }

        let passCount = tonightPasses.count
        print("🛸 Next ISS pass: \(riseTime) (duration: \(Int(duration))s, \(passCount) passes tonight)")

        return data
    }
}

// MARK: - API Response Models

struct ISSPassResponse: Codable {
    let message: String
    let request: ISSPassRequest
    let response: [ISSPass]
}

struct ISSPassRequest: Codable {
    let latitude: Double
    let longitude: Double
    let passes: Int
}

struct ISSPass: Codable {
    let risetime: Int
    let duration: Int
}

// MARK: - Errors

enum ISSServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid ISS API URL"
        case .invalidResponse: return "Invalid response from ISS API"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .apiError(let m): return "ISS API error: \(m)"
        case .noData: return "No ISS pass data available"
        }
    }
}
