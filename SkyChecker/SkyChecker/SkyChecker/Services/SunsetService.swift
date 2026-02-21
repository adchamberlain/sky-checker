import Foundation

enum PolarCondition {
    case polarNight    // Sun stays below horizon all day
    case midnightSun   // Sun stays above horizon all day
    case normal        // Normal sunrise/sunset cycle
}

class SunsetService {
    private static let deg2rad = Double.pi / 180.0
    private static let rad2deg = 180.0 / Double.pi

    /// Get civil twilight end (when it's dark enough to observe) for a given date
    func getSunsetTime(for date: Date, at location: ObserverLocation) -> Date? {
        calculateSunEvent(for: date, at: location, angle: -6.0, isRising: false)
    }

    /// Get civil twilight start (when sky begins to lighten) for the next morning
    func getSunriseTime(for date: Date, at location: ObserverLocation) -> Date? {
        calculateSunEvent(for: date, at: location, angle: -6.0, isRising: true)
    }

    /// Detect if location is experiencing polar night or midnight sun
    func detectPolarCondition(for date: Date, at location: ObserverLocation) -> PolarCondition {
        // Calculate sun's declination for this date
        let calendar = Calendar(identifier: .gregorian)
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) else {
            return .normal
        }

        let year = calendar.component(.year, from: date)
        let isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        let gamma = (2 * Double.pi / (isLeap ? 366 : 365)) * (Double(dayOfYear) - 1 + 0.5)

        let decl = 0.006918 - 0.399912*cos(gamma) + 0.070257*sin(gamma) - 0.006758*cos(2*gamma) + 0.000907*sin(2*gamma) - 0.002697*cos(3*gamma) + 0.00148*sin(3*gamma)

        let latRad = location.latitude * Self.deg2rad
        let zenith = (90 - (-6.0)) * Self.deg2rad  // Civil twilight angle
        let cosHA = (cos(zenith) / (cos(latRad) * cos(decl))) - tan(latRad) * tan(decl)

        // If cosHA > 1: sun never rises above this angle (polar night)
        // If cosHA < -1: sun never sets below this angle (midnight sun)
        if cosHA > 1 {
            return .polarNight
        } else if cosHA < -1 {
            return .midnightSun
        } else {
            return .normal
        }
    }

    /// Get the observation window from sunset tonight to sunrise tomorrow morning
    /// Returns: (sunsetTonight, sunriseTomorrow) - the nighttime window for stargazing
    func getObservationWindow(for date: Date, at location: ObserverLocation) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }

        // Try civil twilight first (-6°)
        if let sunset = getSunsetTime(for: date, at: location),
           let sunrise = getSunriseTime(for: nextDay, at: location) {
            print("🌅 Observation window: Sunset \(Self.formatTime(sunset)) → Sunrise \(Self.formatTime(sunrise))")
            return (sunset, sunrise)
        }

        // Fallback: actual sunset/sunrise (0° angle) for near-polar latitudes
        // where the sun sets but civil twilight never fully ends
        if let sunset = calculateSunEvent(for: date, at: location, angle: 0, isRising: false),
           let sunrise = calculateSunEvent(for: nextDay, at: location, angle: 0, isRising: true) {
            print("🌅 Observation window (fallback to 0°): Sunset \(Self.formatTime(sunset)) → Sunrise \(Self.formatTime(sunrise))")
            return (sunset, sunrise)
        }

        print("⚠️ Could not calculate observation window for \(date)")
        return nil
    }
    
    /// Get midnight for calculating evening vs morning objects
    func getMidnight(for date: Date) -> Date {
        let calendar = Calendar.current
        var comp = calendar.dateComponents([.year, .month, .day], from: date)
        if let day = comp.day {
            comp.day = day + 1  // Next day
        }
        comp.hour = 0
        comp.minute = 0
        return calendar.date(from: comp) ?? date
    }
    
    private func calculateSunEvent(for date: Date, at location: ObserverLocation, angle: Double, isRising: Bool) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) else { return nil }
        
        let year = calendar.component(.year, from: date)
        let isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        let gamma = (2 * Double.pi / (isLeap ? 366 : 365)) * (Double(dayOfYear) - 1 + 0.5)
        
        let eqTime = 229.18 * (0.000075 + 0.001868*cos(gamma) - 0.032077*sin(gamma) - 0.014615*cos(2*gamma) - 0.040849*sin(2*gamma))
        let decl = 0.006918 - 0.399912*cos(gamma) + 0.070257*sin(gamma) - 0.006758*cos(2*gamma) + 0.000907*sin(2*gamma) - 0.002697*cos(3*gamma) + 0.00148*sin(3*gamma)
        
        let latRad = location.latitude * Self.deg2rad
        let zenith = (90 - angle) * Self.deg2rad
        let cosHA = (cos(zenith) / (cos(latRad) * cos(decl))) - tan(latRad) * tan(decl)
        guard cosHA >= -1, cosHA <= 1 else { return nil }
        
        // Hour angle in degrees - positive for sunset (PM), negative for sunrise (AM)
        var ha = acos(cosHA) * Self.rad2deg
        if isRising { ha = -ha }
        
        // Solar noon UTC = 720 - 4*longitude - eqTime
        // Sunrise/sunset = solar noon ± ha adjustment
        // The formula should ADD ha for sunset (later than noon) and SUBTRACT for sunrise (earlier than noon)
        // Since ha is negative for sunrise, we can just add: solarNoon + 4*ha
        let timeUTC = 720 - 4 * location.longitude - eqTime + 4 * ha
        var localTime = timeUTC + Double(TimeZone.current.secondsFromGMT(for: date)) / 60
        if localTime < 0 { localTime += 1440 } else if localTime >= 1440 { localTime -= 1440 }
        
        var comp = calendar.dateComponents([.year, .month, .day], from: date)
        comp.hour = Int(localTime / 60)
        comp.minute = Int(localTime.truncatingRemainder(dividingBy: 60))
        comp.timeZone = .current
        return calendar.date(from: comp)
    }
    
    static func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = .current  // Always use iPhone's local timezone
        f.dateFormat = "h:mma"  // e.g., "6:04AM" or "7:22PM"
        let result = f.string(from: date).lowercased()
        // Remove the 'm' from 'am'/'pm' to get "6:04a" or "7:22p"
        return result.replacingOccurrences(of: "m", with: "")
    }
}

