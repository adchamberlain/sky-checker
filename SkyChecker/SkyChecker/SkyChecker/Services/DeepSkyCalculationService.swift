import Foundation

/// Service for calculating ephemeris data for deep sky objects (galaxies, nebulae, clusters)
/// using their fixed RA/Dec coordinates. Unlike planets, these objects don't move
/// significantly and can be calculated locally without an API call.
class DeepSkyCalculationService {

    /// Calculate ephemeris data for a deep sky object
    /// - Parameters:
    ///   - ra: Right Ascension in hours (0-24)
    ///   - dec: Declination in degrees (-90 to +90)
    ///   - location: Observer location
    ///   - startTime: Observation window start (typically sunset)
    ///   - endTime: Observation window end (typically sunrise)
    /// - Returns: EphemerisData with rise/set/transit times and current position
    func calculateEphemeris(ra: Double, dec: Double, location: ObserverLocation, startTime: Date, endTime: Date) -> EphemerisData {
        var data = EphemerisData()

        // Generate hourly data points throughout the observation window
        var dataPoints: [(time: Date, alt: Double, az: Double)] = []
        var currentTime = startTime
        let calendar = Calendar.current

        while currentTime <= endTime {
            let (alt, az) = altitudeAzimuth(ra: ra, dec: dec, latitude: location.latitude, longitude: location.longitude, time: currentTime)
            dataPoints.append((currentTime, alt, az))
            currentTime = calendar.date(byAdding: .hour, value: 1, to: currentTime) ?? endTime
        }

        guard !dataPoints.isEmpty else { return data }

        // Find transit (highest altitude)
        var maxAlt = -90.0
        var maxAltIndex = 0
        for i in 0..<dataPoints.count {
            if dataPoints[i].alt > maxAlt {
                maxAlt = dataPoints[i].alt
                maxAltIndex = i
            }
        }

        if maxAlt > 0 {
            data.transitTime = dataPoints[maxAltIndex].time
            data.transitAltitude = maxAlt
            data.transitAzimuth = dataPoints[maxAltIndex].az
        }

        // Find rise time (crossing from negative to positive altitude)
        for i in 1..<dataPoints.count {
            let prev = dataPoints[i - 1]
            let curr = dataPoints[i]
            if prev.alt < 0 && curr.alt >= 0 {
                data.riseTime = curr.time
                data.riseAzimuth = curr.az
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
                break
            }
        }

        // Calculate current position
        let now = Date()
        let (currentAlt, currentAz) = altitudeAzimuth(ra: ra, dec: dec, latitude: location.latitude, longitude: location.longitude, time: now)
        data.currentAltitude = currentAlt
        data.currentAzimuth = currentAz
        data.altitudeAtStart = dataPoints.first?.alt

        return data
    }

    /// Calculate altitude and azimuth for a celestial object
    /// - Parameters:
    ///   - ra: Right Ascension in hours
    ///   - dec: Declination in degrees
    ///   - latitude: Observer latitude in degrees
    ///   - longitude: Observer longitude in degrees
    ///   - time: Time of observation
    /// - Returns: Tuple of (altitude, azimuth) in degrees
    private func altitudeAzimuth(ra: Double, dec: Double, latitude: Double, longitude: Double, time: Date) -> (altitude: Double, azimuth: Double) {
        let lst = localSiderealTime(longitude: longitude, time: time)
        let ha = (lst - ra).truncatingRemainder(dividingBy: 24)
        let haHours = ha < 0 ? ha + 24 : ha

        // Convert to radians
        let haRad = haHours * 15 * .pi / 180  // HA in degrees, then to radians
        let decRad = dec * .pi / 180
        let latRad = latitude * .pi / 180

        // Calculate altitude
        let sinAlt = sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(haRad)
        let altitude = asin(sinAlt) * 180 / .pi

        // Calculate azimuth
        let cosAz = (sin(decRad) - sin(latRad) * sinAlt) / (cos(latRad) * cos(asin(sinAlt)))
        var azimuth = acos(max(-1, min(1, cosAz))) * 180 / .pi

        // Adjust azimuth for quadrant
        if sin(haRad) > 0 {
            azimuth = 360 - azimuth
        }

        return (altitude, azimuth)
    }

    /// Calculate Local Sidereal Time in hours
    /// - Parameters:
    ///   - longitude: Observer longitude in degrees (positive East)
    ///   - time: Time of observation
    /// - Returns: LST in hours (0-24)
    private func localSiderealTime(longitude: Double, time: Date) -> Double {
        // Calculate Julian Date
        let jd = julianDate(from: time)

        // Julian centuries since J2000.0
        let t = (jd - 2451545.0) / 36525.0

        // Greenwich Mean Sidereal Time in degrees
        var gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0)
        gmst += 0.000387933 * t * t - t * t * t / 38710000.0
        gmst = gmst.truncatingRemainder(dividingBy: 360)
        if gmst < 0 { gmst += 360 }

        // Convert to hours and add longitude
        var lst = gmst / 15.0 + longitude / 15.0
        lst = lst.truncatingRemainder(dividingBy: 24)
        if lst < 0 { lst += 24 }

        return lst
    }

    /// Calculate Julian Date from a Date
    private func julianDate(from date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)

        var year = Double(components.year ?? 2000)
        var month = Double(components.month ?? 1)
        let day = Double(components.day ?? 1)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)

        // Adjust for January and February
        if month <= 2 {
            year -= 1
            month += 12
        }

        let a = floor(year / 100)
        let b = 2 - a + floor(a / 4)

        let jd = floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524.5
        let dayFraction = (hour + minute / 60.0 + second / 3600.0) / 24.0

        return jd + dayFraction
    }
}
