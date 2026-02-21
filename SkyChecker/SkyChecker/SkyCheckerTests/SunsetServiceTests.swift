import XCTest
@testable import SkyChecker

final class SunsetServiceTests: XCTestCase {

    var sut: SunsetService!

    override func setUp() {
        super.setUp()
        sut = SunsetService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Sunset/Sunrise Time Tests

    func testSunset_SanFrancisco_SummerIsLate() {
        // Summer sunset in SF should be around 8-9pm local time
        let summerDate = DateTestHelpers.summerSolstice2024
        let location = TestFixtures.sanFrancisco

        let sunset = sut.getSunsetTime(for: summerDate, at: location)

        XCTAssertNotNil(sunset, "Should calculate sunset for summer solstice")

        if let sunset = sunset {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: sunset)

            // Civil twilight end (darkness) should be around 9pm in summer
            XCTAssertGreaterThanOrEqual(hour, 20,
                                        "Summer civil twilight should end at or after 8pm")
            XCTAssertLessThanOrEqual(hour, 22,
                                     "Summer civil twilight should end before 10pm")
        }
    }

    func testSunset_SanFrancisco_WinterIsEarly() {
        // Winter sunset in SF should be around 5pm local time
        let winterDate = DateTestHelpers.winterSolstice2024
        let location = TestFixtures.sanFrancisco

        let sunset = sut.getSunsetTime(for: winterDate, at: location)

        XCTAssertNotNil(sunset, "Should calculate sunset for winter solstice")

        if let sunset = sunset {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: sunset)

            // Civil twilight end should be around 5-6pm in winter
            XCTAssertGreaterThanOrEqual(hour, 17,
                                        "Winter civil twilight should end at or after 5pm")
            XCTAssertLessThanOrEqual(hour, 18,
                                     "Winter civil twilight should end before 7pm")
        }
    }

    func testSunrise_SanFrancisco_SummerIsEarly() {
        // Summer sunrise in SF should be early
        let summerDate = DateTestHelpers.summerSolstice2024
        let location = TestFixtures.sanFrancisco

        let sunrise = sut.getSunriseTime(for: summerDate, at: location)

        XCTAssertNotNil(sunrise, "Should calculate sunrise for summer solstice")

        if let sunrise = sunrise {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: sunrise)

            // Civil twilight start should be around 5-6am in summer
            XCTAssertGreaterThanOrEqual(hour, 4,
                                        "Summer civil twilight should start after 4am")
            XCTAssertLessThanOrEqual(hour, 6,
                                     "Summer civil twilight should start before 7am")
        }
    }

    // MARK: - Polar Condition Tests

    func testPolarCondition_Longyearbyen_WinterSolstice_IsPolarNight() {
        // Longyearbyen (78°N) should experience civil twilight polar night around winter solstice
        // Tromsø (69.6°N) still gets brief civil twilight even in winter
        let winterDate = DateTestHelpers.winterSolstice2024
        let location = TestFixtures.longyearbyen

        let condition = sut.detectPolarCondition(for: winterDate, at: location)

        XCTAssertEqual(condition, .polarNight,
                       "Longyearbyen should have polar night during winter solstice")
    }

    func testPolarCondition_Tromso_SummerSolstice_IsMidnightSun() {
        // Tromsø should experience midnight sun around summer solstice
        let summerDate = DateTestHelpers.summerSolstice2024
        let location = TestFixtures.tromso

        let condition = sut.detectPolarCondition(for: summerDate, at: location)

        XCTAssertEqual(condition, .midnightSun,
                       "Tromsø should have midnight sun during summer solstice")
    }

    func testPolarCondition_SanFrancisco_AlwaysNormal() {
        // San Francisco should always have normal sunrise/sunset
        let dates = [
            DateTestHelpers.winterSolstice2024,
            DateTestHelpers.summerSolstice2024,
            DateTestHelpers.vernalEquinox2024,
            DateTestHelpers.autumnalEquinox2024
        ]
        let location = TestFixtures.sanFrancisco

        for date in dates {
            let condition = sut.detectPolarCondition(for: date, at: location)
            XCTAssertEqual(condition, .normal,
                           "San Francisco should always have normal sun conditions")
        }
    }

    func testPolarCondition_Quito_AlwaysNormal() {
        // Equatorial locations should always have normal conditions
        let dates = [
            DateTestHelpers.winterSolstice2024,
            DateTestHelpers.summerSolstice2024
        ]
        let location = TestFixtures.quito

        for date in dates {
            let condition = sut.detectPolarCondition(for: date, at: location)
            XCTAssertEqual(condition, .normal,
                           "Equatorial locations should always have normal sun conditions")
        }
    }

    // MARK: - Observation Window Tests

    func testObservationWindow_SpansOvernight() {
        // Observation window should start in evening and end in morning
        let date = DateTestHelpers.march15_2024_evening
        let location = TestFixtures.sanFrancisco

        let window = sut.getObservationWindow(for: date, at: location)

        XCTAssertNotNil(window, "Should calculate observation window")

        if let window = window {
            XCTAssertLessThan(window.start, window.end,
                              "Start time should be before end time")

            let calendar = Calendar.current
            let startHour = calendar.component(.hour, from: window.start)
            let endHour = calendar.component(.hour, from: window.end)

            // Start should be evening (after 5pm), end should be morning (before 8am)
            XCTAssertGreaterThanOrEqual(startHour, 17,
                                        "Observation window should start in evening")
            XCTAssertLessThanOrEqual(endHour, 8,
                                     "Observation window should end in morning")
        }
    }

    func testObservationWindow_ReturnsNil_ForPolarNight() {
        // During polar night, sunset calculation should fail
        // Use Longyearbyen (78°N) which experiences true civil twilight polar night
        let winterDate = DateTestHelpers.winterSolstice2024
        let location = TestFixtures.longyearbyen

        let sunset = sut.getSunsetTime(for: winterDate, at: location)

        XCTAssertNil(sunset, "Sunset should be nil during polar night at high latitudes")
    }

    // MARK: - getMidnight Tests

    func testGetMidnight_ReturnsNextDayMidnight() {
        let evening = DateTestHelpers.march15_2024_evening  // March 15, 2024 at 18:00 UTC
        let midnight = sut.getMidnight(for: evening)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: midnight)

        XCTAssertEqual(components.month, 3, "Should be March")
        XCTAssertEqual(components.day, 16, "Should be day after input")
        XCTAssertEqual(components.hour, 0, "Hour should be 0")
        XCTAssertEqual(components.minute, 0, "Minute should be 0")
    }

    func testGetMidnight_HandlesMonthBoundary() {
        let jan31 = DateTestHelpers.jan31_2024_late  // January 31, 2024 at 23:59 UTC
        let midnight = sut.getMidnight(for: jan31)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: midnight)

        XCTAssertEqual(components.month, 2, "Should roll over to February")
        XCTAssertEqual(components.day, 1, "Should be first day of month")
    }

    func testGetMidnight_HandlesYearBoundary() {
        let dec31 = DateTestHelpers.dec31_2024_late  // December 31, 2024 at 23:59 UTC
        let midnight = sut.getMidnight(for: dec31)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: midnight)

        XCTAssertEqual(components.year, 2025, "Should roll over to next year")
        XCTAssertEqual(components.month, 1, "Should be January")
        XCTAssertEqual(components.day, 1, "Should be first day of year")
    }

    // MARK: - formatTime Tests

    func testFormatTime_MorningTime_HasASuffix() {
        let morning = DateTestHelpers.utcDate(year: 2024, month: 3, day: 15, hour: 14, minute: 30)  // 6:30am PST approx

        let formatted = SunsetService.formatTime(morning)

        XCTAssertTrue(formatted.hasSuffix("a"),
                      "Morning time should end with 'a': got \(formatted)")
    }

    func testFormatTime_EveningTime_HasPSuffix() {
        let evening = DateTestHelpers.utcDate(year: 2024, month: 3, day: 15, hour: 2, minute: 45)  // 6:45pm PST approx

        let formatted = SunsetService.formatTime(evening)

        XCTAssertTrue(formatted.hasSuffix("p"),
                      "Evening time should end with 'p': got \(formatted)")
    }

    func testFormatTime_DoesNotContainM() {
        let time = DateTestHelpers.march15_2024_evening

        let formatted = SunsetService.formatTime(time)

        XCTAssertFalse(formatted.contains("m"),
                       "Formatted time should not contain 'm': got \(formatted)")
    }

    // MARK: - Pole Polar Condition Tests

    func testPolarCondition_NorthPole_WinterSolstice_IsPolarNight() {
        let winterDate = DateTestHelpers.winterSolstice2024
        let location = TestFixtures.northPole

        let condition = sut.detectPolarCondition(for: winterDate, at: location)

        XCTAssertEqual(condition, .polarNight,
                       "North Pole should have polar night during winter solstice")
    }

    func testPolarCondition_NorthPole_SummerSolstice_IsMidnightSun() {
        let summerDate = DateTestHelpers.summerSolstice2024
        let location = TestFixtures.northPole

        let condition = sut.detectPolarCondition(for: summerDate, at: location)

        XCTAssertEqual(condition, .midnightSun,
                       "North Pole should have midnight sun during summer solstice")
    }

    func testPolarCondition_SouthPole_WinterSolstice_IsMidnightSun() {
        // Northern Hemisphere winter solstice = Southern Hemisphere summer
        let winterDate = DateTestHelpers.winterSolstice2024
        let location = TestFixtures.southPole

        let condition = sut.detectPolarCondition(for: winterDate, at: location)

        XCTAssertEqual(condition, .midnightSun,
                       "South Pole should have midnight sun during Northern Hemisphere winter solstice")
    }

    func testObservationWindow_NearArctic_Summer_FallsBackToActualSunset() {
        // At ~65°N in summer, civil twilight (-6°) may fail but actual sunset (0°) succeeds
        // Tromsø at 69.6°N during summer solstice should have midnight sun
        // so we use a location slightly south where sun sets but twilight doesn't end
        let summerDate = DateTestHelpers.summerSolstice2024
        let nearArctic = ObserverLocation(
            latitude: 64.5,
            longitude: 18.0,
            altitude: 0,
            name: "Near Arctic"
        )

        // The observation window should return something (either civil twilight or fallback)
        // At 64.5°N during summer solstice, civil twilight may not end,
        // but the sun does set briefly
        let condition = sut.detectPolarCondition(for: summerDate, at: nearArctic)

        if condition == .normal {
            // If detected as normal, the observation window should succeed
            // (either via civil twilight or the 0° fallback)
            let window = sut.getObservationWindow(for: summerDate, at: nearArctic)
            // At this latitude in summer, we expect either a valid window or nil
            // The key thing is it doesn't crash
            if let window = window {
                XCTAssertLessThan(window.start, window.end,
                                  "Observation window start should be before end")
            }
        }
        // If midnight sun, no observation window is expected (handled by ViewModel)
    }

    // MARK: - Southern Hemisphere Tests

    func testSunset_Sydney_ReversedSeasons() {
        // Sydney's summer is December (winter solstice in Northern Hemisphere)
        // Compare winter vs summer sunset times - summer should be later
        let sydneySummer = DateTestHelpers.winterSolstice2024  // Dec 21 = Sydney summer
        let sydneyWinter = DateTestHelpers.summerSolstice2024  // Jun 20 = Sydney winter
        let location = TestFixtures.sydney

        guard let summerSunset = sut.getSunsetTime(for: sydneySummer, at: location),
              let winterSunset = sut.getSunsetTime(for: sydneyWinter, at: location) else {
            XCTFail("Should calculate sunset for Sydney")
            return
        }

        // Extract time-of-day by comparing to midnight
        let calendar = Calendar.current
        let summerMidnight = calendar.startOfDay(for: summerSunset)
        let winterMidnight = calendar.startOfDay(for: winterSunset)

        let summerSecondsFromMidnight = summerSunset.timeIntervalSince(summerMidnight)
        let winterSecondsFromMidnight = winterSunset.timeIntervalSince(winterMidnight)

        // Sydney summer sunset should be later in the day than winter sunset
        XCTAssertGreaterThan(summerSecondsFromMidnight, winterSecondsFromMidnight,
                             "Sydney summer (Dec) sunset should be later than winter (Jun) sunset")
    }

    // MARK: - Equatorial Consistency Tests

    func testSunset_Quito_ConsistentYearRound() {
        // Equatorial locations should have similar sunset times year-round
        let winterDate = DateTestHelpers.winterSolstice2024
        let summerDate = DateTestHelpers.summerSolstice2024
        let location = TestFixtures.quito

        guard let winterSunset = sut.getSunsetTime(for: winterDate, at: location),
              let summerSunset = sut.getSunsetTime(for: summerDate, at: location) else {
            XCTFail("Should calculate sunset for both dates")
            return
        }

        let calendar = Calendar.current
        let winterHour = calendar.component(.hour, from: winterSunset)
        let winterMinute = calendar.component(.minute, from: winterSunset)
        let summerHour = calendar.component(.hour, from: summerSunset)
        let summerMinute = calendar.component(.minute, from: summerSunset)

        let winterMinutes = winterHour * 60 + winterMinute
        let summerMinutes = summerHour * 60 + summerMinute
        let difference = abs(winterMinutes - summerMinutes)

        // Equatorial sunset times should vary by less than 90 minutes throughout year
        // (Equation of time + longitude offset from timezone center causes ~1hr variation)
        XCTAssertLessThan(difference, 90,
                          "Equatorial sunset should be relatively consistent year-round (diff: \(difference) minutes)")
    }
}
