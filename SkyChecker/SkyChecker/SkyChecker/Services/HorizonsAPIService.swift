import Foundation

enum HorizonsAPIError: LocalizedError {
    case invalidURL, networkError(Error), invalidResponse, parsingError(String), apiError(String), noData
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .invalidResponse: return "Invalid response"
        case .parsingError(let m): return "Parsing error: \(m)"
        case .apiError(let m): return "API error: \(m)"
        case .noData: return "No data"
        }
    }
}

struct EphemerisData {
    var riseTime, setTime, transitTime: Date?
    var riseAzimuth, setAzimuth, transitAzimuth, transitAltitude, currentAltitude, currentAzimuth, illumination, sunElongation: Double?
    var altitudeAtStart: Double?  // Altitude at observation window start
}

class HorizonsAPIService {
    private let baseURL = "https://ssd.jpl.nasa.gov/api/horizons.api"
    private let session: URLSession
    private let dateFormatter: DateFormatter
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        session = URLSession(configuration: config)
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
    }
    
    func fetchEphemeris(for object: CelestialObject, location: ObserverLocation, startTime: Date, endTime: Date) async throws -> EphemerisData {
        var components = URLComponents(string: baseURL)!
        
        // Request illumination (10) and sun elongation (23) for the Moon to calculate phase
        let quantities = object.type == .moon ? "4,10,23" : "4"
        
        components.queryItems = [
            URLQueryItem(name: "format", value: "text"),
            URLQueryItem(name: "COMMAND", value: "'\(object.horizonsCommand)'"),
            URLQueryItem(name: "OBJ_DATA", value: "'NO'"),
            URLQueryItem(name: "MAKE_EPHEM", value: "'YES'"),
            URLQueryItem(name: "EPHEM_TYPE", value: "'OBSERVER'"),
            URLQueryItem(name: "CENTER", value: "'coord@399'"),
            URLQueryItem(name: "COORD_TYPE", value: "'GEODETIC'"),
            URLQueryItem(name: "SITE_COORD", value: "'\(location.horizonsSiteCoord)'"),
            URLQueryItem(name: "START_TIME", value: "'\(dateFormatter.string(from: startTime))'"),
            URLQueryItem(name: "STOP_TIME", value: "'\(dateFormatter.string(from: endTime))'"),
            URLQueryItem(name: "STEP_SIZE", value: "'1 h'"),
            URLQueryItem(name: "QUANTITIES", value: "'\(quantities)'")
        ]
        
        // Retry up to 5 times with exponential backoff for rate-limited API
        for attempt in 1...5 {
            do {
                print("🔭 Fetching \(object.name)... (attempt \(attempt))")
                let (data, response) = try await session.data(from: components.url!)
                guard let http = response as? HTTPURLResponse else { throw HorizonsAPIError.invalidResponse }
                if http.statusCode == 503 || http.statusCode == 429 {
                    let waitTime = attempt * 2  // 2s, 4s, 6s, 8s, 10s
                    print("⏳ \(object.name): Server busy (\(http.statusCode)), retrying in \(waitTime) seconds...")
                    if attempt < 5 { try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000); continue }
                }
                guard http.statusCode == 200 else { throw HorizonsAPIError.apiError("HTTP \(http.statusCode)") }
                guard let text = String(data: data, encoding: .utf8) else { throw HorizonsAPIError.noData }
                print("✅ Got \(object.name)")
                return try parseResponse(text, for: object)
            } catch {
                if attempt == 5 { throw error }
                let waitTime = attempt * 2
                try? await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
            }
        }
        throw HorizonsAPIError.noData
    }
    
    func fetchAllEphemeris(objects: [CelestialObject], location: ObserverLocation, startTime: Date, endTime: Date) async throws -> [String: EphemerisData] {
        var results: [String: EphemerisData] = [:]
        
        // Stagger requests to avoid overwhelming the NASA API
        // NASA Horizons is rate-limited, so we add delays between requests
        try await withThrowingTaskGroup(of: (String, EphemerisData?).self) { group in
            for (index, obj) in objects.enumerated() {
                // Add a staggered delay: 0ms, 300ms, 600ms, 900ms, etc.
                let delayMs = index * 300
                group.addTask {
                    if delayMs > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
                    }
                    do { return (obj.id, try await self.fetchEphemeris(for: obj, location: location, startTime: startTime, endTime: endTime)) }
                    catch { print("❌ Failed \(obj.name): \(error)"); return (obj.id, nil) }
                }
            }
            for try await (id, data) in group { if let d = data { results[id] = d } }
        }
        return results
    }
    
    private func parseResponse(_ response: String, for object: CelestialObject) throws -> EphemerisData {
        var data = EphemerisData()
        var inData = false
        var dataPoints: [(time: Date, az: Double, alt: Double, illumination: Double?, sunElongation: Double?)] = []
        let isMoon = object.type == .moon
        
        for line in response.components(separatedBy: .newlines) {
            if line.contains("$$SOE") { inData = true; continue }
            if line.contains("$$EOE") { break }
            if inData, let parsed = parseLine(line, isMoon: isMoon) {
                dataPoints.append(parsed)
            }
        }
        
        print("📊 \(object.name): Parsed \(dataPoints.count) data points")
        guard !dataPoints.isEmpty else { return data }
        
        // Extract illumination and sun elongation for Moon
        if isMoon {
            if let firstIllumination = dataPoints.first?.illumination {
                data.illumination = firstIllumination
                print("🌙 Moon illumination: \(firstIllumination)%")
            }
            if let sunElong = dataPoints.first?.sunElongation {
                data.sunElongation = sunElong
                let phase = sunElong < 180 ? "Waxing" : "Waning"
                print("🌙 Sun elongation: \(sunElong)° (\(phase))")
            }
        }
        
        // Find the highest point (transit)
        var maxAlt = -90.0
        var maxAltIndex = 0
        for i in 0..<dataPoints.count {
            if dataPoints[i].alt > maxAlt {
                maxAlt = dataPoints[i].alt
                maxAltIndex = i
            }
        }

        // Only set transit if object gets above horizon
        if maxAlt > 0 {
            data.transitTime = dataPoints[maxAltIndex].time
            data.transitAltitude = maxAlt
            data.transitAzimuth = dataPoints[maxAltIndex].az
            print("   Transit: \(data.transitTime!) at \(maxAlt)° (az: \(dataPoints[maxAltIndex].az)°)")
        }
        
        // Find rise time (crossing from negative to positive altitude)
        for i in 1..<dataPoints.count {
            let prev = dataPoints[i - 1]
            let curr = dataPoints[i]
            if prev.alt < 0 && curr.alt >= 0 {
                data.riseTime = curr.time
                data.riseAzimuth = curr.az
                print("   Rise: \(curr.time) at az \(curr.az)°")
                break
            }
        }
        
        // Find set time (crossing from positive to negative altitude)
        for i in 1..<dataPoints.count {
            let prev = dataPoints[i - 1]
            let curr = dataPoints[i]
            if prev.alt >= 0 && curr.alt < 0 {
                data.setTime = curr.time
                data.setAzimuth = curr.az
                print("   Set: \(curr.time) at az \(curr.az)°")
                break
            }
        }
        
        // Handle objects already visible at window start (don't fake a rise time)
        // Just leave riseTime as nil - the UI will handle this
        
        // Handle objects still visible at window end (don't fake a set time)
        // Just leave setTime as nil - the UI will handle this

        // Set positions from data points
        data.altitudeAtStart = dataPoints.first?.alt

        // Calculate current position by interpolating between data points
        let now = Date()
        if let (currentAlt, currentAz) = interpolateCurrentPosition(dataPoints: dataPoints, currentTime: now) {
            data.currentAltitude = currentAlt
            data.currentAzimuth = currentAz
            print("   Current position: alt=\(String(format: "%.1f", currentAlt))° az=\(String(format: "%.1f", currentAz))°")
        } else {
            // Fallback to first data point if current time is before window
            data.currentAltitude = dataPoints.first?.alt
            data.currentAzimuth = dataPoints.first?.az
        }

        return data
    }
    
    private func interpolateCurrentPosition(dataPoints: [(time: Date, az: Double, alt: Double, illumination: Double?, sunElongation: Double?)], currentTime: Date) -> (altitude: Double, azimuth: Double)? {
        guard !dataPoints.isEmpty else { return nil }

        // If current time is before all data points, return the first point
        if currentTime < dataPoints.first!.time {
            return (dataPoints.first!.alt, dataPoints.first!.az)
        }

        // If current time is after all data points, return the last point
        if currentTime > dataPoints.last!.time {
            return (dataPoints.last!.alt, dataPoints.last!.az)
        }

        // Find the two data points that bracket the current time
        for i in 1..<dataPoints.count {
            let prev = dataPoints[i - 1]
            let curr = dataPoints[i]

            if currentTime >= prev.time && currentTime <= curr.time {
                // Linear interpolation
                let timeDiff = curr.time.timeIntervalSince(prev.time)
                let timeOffset = currentTime.timeIntervalSince(prev.time)
                let ratio = timeOffset / timeDiff

                let interpolatedAlt = prev.alt + (curr.alt - prev.alt) * ratio

                // Handle azimuth interpolation carefully (wraps at 360°)
                var interpolatedAz: Double
                let azDiff = curr.az - prev.az
                if abs(azDiff) > 180 {
                    // Handle wraparound (e.g., 350° to 10°)
                    let adjustedDiff = azDiff > 0 ? azDiff - 360 : azDiff + 360
                    interpolatedAz = prev.az + adjustedDiff * ratio
                    if interpolatedAz < 0 { interpolatedAz += 360 }
                    if interpolatedAz >= 360 { interpolatedAz -= 360 }
                } else {
                    interpolatedAz = prev.az + azDiff * ratio
                }

                return (interpolatedAlt, interpolatedAz)
            }
        }

        return nil
    }

    private func parseLine(_ line: String, isMoon: Bool = false) -> (time: Date, az: Double, alt: Double, illumination: Double?, sunElongation: Double?)? {
        // NASA Horizons format: "2025-Dec-11 18:00 *m  143.033787  18.149777"
        // For Moon with illumination+elongation: "2025-Dec-12 01:00 C   332.011110 -46.835628   48.39220   88.0030 /L"
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard parts.count >= 3 else { return nil }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MMM-dd HH:mm"
        df.timeZone = TimeZone(identifier: "UTC")
        
        let dateStr = "\(parts[0]) \(parts[1])"
        guard let date = df.date(from: dateStr) else { 
            return nil 
        }
        
        // Find all numeric values from the line
        var numbers: [Double] = []
        for part in parts {
            if let num = Double(part) {
                numbers.append(num)
            }
        }
        
        // Need at least azimuth and altitude
        guard numbers.count >= 2 else { return nil }
        
        let az = numbers[0]
        let alt = numbers[1]
        let illumination: Double? = (isMoon && numbers.count >= 3) ? numbers[2] : nil
        let sunElongation: Double? = (isMoon && numbers.count >= 4) ? numbers[3] : nil
        
        return (date, az, alt, illumination, sunElongation)
    }
}

