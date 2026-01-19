import Foundation

/// Service for providing meteor shower information
/// Uses static data - meteor showers occur on predictable dates each year
class MeteorShowerService {

    /// All major meteor showers with their annual peak dates
    static let showers: [MeteorShower] = [
        MeteorShower(
            name: "Quadrantids",
            peakMonth: 1, peakDay: 3,
            activeStart: (month: 12, day: 28), activeEnd: (month: 1, day: 12),
            zhr: 120,
            radiantConstellation: "Bootes",
            description: "Strong January shower, best after midnight"
        ),
        MeteorShower(
            name: "Lyrids",
            peakMonth: 4, peakDay: 22,
            activeStart: (month: 4, day: 16), activeEnd: (month: 4, day: 25),
            zhr: 18,
            radiantConstellation: "Lyra",
            description: "Spring shower from Comet Thatcher"
        ),
        MeteorShower(
            name: "Eta Aquariids",
            peakMonth: 5, peakDay: 6,
            activeStart: (month: 4, day: 19), activeEnd: (month: 5, day: 28),
            zhr: 50,
            radiantConstellation: "Aquarius",
            description: "Debris from Halley's Comet"
        ),
        MeteorShower(
            name: "Delta Aquariids",
            peakMonth: 7, peakDay: 30,
            activeStart: (month: 7, day: 12), activeEnd: (month: 8, day: 23),
            zhr: 20,
            radiantConstellation: "Aquarius",
            description: "Summer shower, best from southern latitudes"
        ),
        MeteorShower(
            name: "Perseids",
            peakMonth: 8, peakDay: 12,
            activeStart: (month: 7, day: 17), activeEnd: (month: 8, day: 24),
            zhr: 100,
            radiantConstellation: "Perseus",
            description: "Most popular summer shower"
        ),
        MeteorShower(
            name: "Orionids",
            peakMonth: 10, peakDay: 21,
            activeStart: (month: 10, day: 2), activeEnd: (month: 11, day: 7),
            zhr: 20,
            radiantConstellation: "Orion",
            description: "Another Halley's Comet shower"
        ),
        MeteorShower(
            name: "Leonids",
            peakMonth: 11, peakDay: 17,
            activeStart: (month: 11, day: 6), activeEnd: (month: 11, day: 30),
            zhr: 15,
            radiantConstellation: "Leo",
            description: "Fast meteors, occasional storms"
        ),
        MeteorShower(
            name: "Geminids",
            peakMonth: 12, peakDay: 14,
            activeStart: (month: 12, day: 4), activeEnd: (month: 12, day: 17),
            zhr: 150,
            radiantConstellation: "Gemini",
            description: "Strongest annual shower"
        ),
        MeteorShower(
            name: "Ursids",
            peakMonth: 12, peakDay: 22,
            activeStart: (month: 12, day: 17), activeEnd: (month: 12, day: 26),
            zhr: 10,
            radiantConstellation: "Ursa Minor",
            description: "Late December shower"
        )
    ]

    /// Get the current or next upcoming meteor shower
    /// - Parameter date: The reference date (typically today)
    /// - Returns: Information about the shower status, or nil if none within 30 days
    func getShowerStatus(for date: Date) -> MeteorShowerStatus? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        // Check each shower
        var closestShower: (shower: MeteorShower, peakDate: Date, daysUntil: Int, isActive: Bool)?

        for shower in MeteorShowerService.showers {
            // Get this year's peak date
            var peakComponents = DateComponents()
            peakComponents.year = year
            peakComponents.month = shower.peakMonth
            peakComponents.day = shower.peakDay

            guard let peakDate = calendar.date(from: peakComponents) else { continue }

            // Calculate active period for this year
            let (isActive, activeStart, activeEnd) = isShowerActive(shower: shower, date: date, year: year)

            // Calculate days until peak
            let daysUntilPeak = calendar.dateComponents([.day], from: date, to: peakDate).day ?? 999

            // If peak already passed this year, check next year
            if daysUntilPeak < -7 {
                peakComponents.year = year + 1
                guard let nextYearPeak = calendar.date(from: peakComponents) else { continue }
                let nextYearDays = calendar.dateComponents([.day], from: date, to: nextYearPeak).day ?? 999

                if closestShower == nil || nextYearDays < closestShower!.daysUntil {
                    closestShower = (shower, nextYearPeak, nextYearDays, false)
                }
            } else {
                // This year's shower is still relevant
                if closestShower == nil || daysUntilPeak < closestShower!.daysUntil || isActive {
                    // Prefer active showers
                    if isActive || closestShower == nil || (!closestShower!.isActive && daysUntilPeak < closestShower!.daysUntil) {
                        closestShower = (shower, peakDate, daysUntilPeak, isActive)
                    }
                }
            }
        }

        guard let result = closestShower else { return nil }

        // Only return if within 30 days or currently active
        if result.daysUntil > 30 && !result.isActive { return nil }

        return MeteorShowerStatus(
            shower: result.shower,
            peakDate: result.peakDate,
            daysUntilPeak: result.daysUntil,
            isActive: result.isActive
        )
    }

    /// Check if a shower is currently active
    private func isShowerActive(shower: MeteorShower, date: Date, year: Int) -> (isActive: Bool, start: Date?, end: Date?) {
        let calendar = Calendar.current

        // Build start date
        var startComponents = DateComponents()
        startComponents.year = shower.activeStart.month > shower.activeEnd.month ? year - 1 : year
        if shower.activeStart.month == 12 && shower.activeEnd.month == 1 {
            // Handle year wrap (e.g., Quadrantids: Dec 28 - Jan 12)
            let currentMonth = calendar.component(.month, from: date)
            if currentMonth == 1 {
                startComponents.year = year - 1
            } else {
                startComponents.year = year
            }
        }
        startComponents.month = shower.activeStart.month
        startComponents.day = shower.activeStart.day

        // Build end date
        var endComponents = DateComponents()
        endComponents.year = year
        if shower.activeStart.month > shower.activeEnd.month {
            // Wraps around year (e.g., Dec to Jan)
            let currentMonth = calendar.component(.month, from: date)
            if currentMonth >= shower.activeStart.month {
                endComponents.year = year + 1
            }
        }
        endComponents.month = shower.activeEnd.month
        endComponents.day = shower.activeEnd.day

        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return (false, nil, nil)
        }

        let isActive = date >= startDate && date <= endDate
        return (isActive, startDate, endDate)
    }
}

// MARK: - Models

struct MeteorShower {
    let name: String
    let peakMonth: Int
    let peakDay: Int
    let activeStart: (month: Int, day: Int)
    let activeEnd: (month: Int, day: Int)
    let zhr: Int  // Zenithal Hourly Rate (meteors per hour under ideal conditions)
    let radiantConstellation: String
    let description: String
}

struct MeteorShowerStatus {
    let shower: MeteorShower
    let peakDate: Date
    let daysUntilPeak: Int
    let isActive: Bool

    var statusText: String {
        if isActive {
            if daysUntilPeak == 0 {
                return "\(shower.name) peak tonight!"
            } else if daysUntilPeak > 0 {
                return "\(shower.name) active - peaks in \(daysUntilPeak)d"
            } else {
                return "\(shower.name) active - past peak"
            }
        } else {
            return "\(shower.name) in \(daysUntilPeak) days"
        }
    }

    var detailText: String {
        "~\(shower.zhr)/hr from \(shower.radiantConstellation)"
    }
}
