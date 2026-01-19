import Foundation

/// Helper functions for creating deterministic test dates
enum DateTestHelpers {

    /// Create a UTC date with specific components
    /// - Parameters:
    ///   - year: Year (e.g., 2000)
    ///   - month: Month (1-12)
    ///   - day: Day (1-31)
    ///   - hour: Hour (0-23), default 0
    ///   - minute: Minute (0-59), default 0
    ///   - second: Second (0-59), default 0
    /// - Returns: Date in UTC
    static func utcDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone(identifier: "UTC")

        return calendar.date(from: components)!
    }

    // MARK: - Epoch Dates

    /// J2000.0 epoch - January 1, 2000 at 12:00:00 TT (approximately 11:58:55.816 UTC)
    /// For testing purposes, we use noon UTC which gives JD = 2451545.0
    static let j2000Epoch = utcDate(year: 2000, month: 1, day: 1, hour: 12, minute: 0, second: 0)

    /// Unix epoch - January 1, 1970 at 00:00:00 UTC
    static let unixEpoch = utcDate(year: 1970, month: 1, day: 1, hour: 0, minute: 0, second: 0)

    // MARK: - Solstice and Equinox Dates (2024)

    /// Winter Solstice 2024 (Northern Hemisphere) - December 21, 2024
    /// Shortest day in Northern Hemisphere
    static let winterSolstice2024 = utcDate(year: 2024, month: 12, day: 21, hour: 12, minute: 0, second: 0)

    /// Summer Solstice 2024 (Northern Hemisphere) - June 20, 2024
    /// Longest day in Northern Hemisphere, midnight sun in Arctic
    static let summerSolstice2024 = utcDate(year: 2024, month: 6, day: 20, hour: 12, minute: 0, second: 0)

    /// Vernal (Spring) Equinox 2024 - March 20, 2024
    /// Day and night approximately equal
    static let vernalEquinox2024 = utcDate(year: 2024, month: 3, day: 20, hour: 12, minute: 0, second: 0)

    /// Autumnal Equinox 2024 - September 22, 2024
    /// Day and night approximately equal
    static let autumnalEquinox2024 = utcDate(year: 2024, month: 9, day: 22, hour: 12, minute: 0, second: 0)

    // MARK: - Known Julian Date Reference Points

    /// January 1, 2000 at 00:00:00 UTC = JD 2451544.5
    static let jan1_2000_midnight = utcDate(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0)

    /// March 15, 2024 at 18:00:00 UTC - arbitrary test date
    static let march15_2024_evening = utcDate(year: 2024, month: 3, day: 15, hour: 18, minute: 0, second: 0)

    // MARK: - Month/Year Boundary Dates

    /// December 31, 2024 at 23:59:00 UTC - for testing year boundary
    static let dec31_2024_late = utcDate(year: 2024, month: 12, day: 31, hour: 23, minute: 59, second: 0)

    /// January 31, 2024 at 23:59:00 UTC - for testing month boundary
    static let jan31_2024_late = utcDate(year: 2024, month: 1, day: 31, hour: 23, minute: 59, second: 0)
}
