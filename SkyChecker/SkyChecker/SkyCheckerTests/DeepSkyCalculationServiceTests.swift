import XCTest
@testable import SkyChecker

final class DeepSkyCalculationServiceTests: XCTestCase {

    var sut: DeepSkyCalculationService!

    override func setUp() {
        super.setUp()
        sut = DeepSkyCalculationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Julian Date Tests

    func testJulianDate_J2000Epoch_ReturnsCorrectValue() {
        // J2000.0 epoch at noon UTC = JD 2451545.0
        let j2000 = DateTestHelpers.j2000Epoch

        let jd = sut.testableJulianDate(from: j2000)

        XCTAssertEqual(jd, 2451545.0, accuracy: 0.0001,
                       "J2000 epoch should equal JD 2451545.0")
    }

    func testJulianDate_Jan1_2000_Midnight_ReturnsCorrectValue() {
        // January 1, 2000 at 00:00:00 UTC = JD 2451544.5
        let date = DateTestHelpers.jan1_2000_midnight

        let jd = sut.testableJulianDate(from: date)

        XCTAssertEqual(jd, 2451544.5, accuracy: 0.0001,
                       "Jan 1, 2000 midnight should equal JD 2451544.5")
    }

    func testJulianDate_KnownDate_ReturnsExpectedValue() {
        // March 15, 2024 at 18:00 UTC should be approximately JD 2460385.25
        let date = DateTestHelpers.march15_2024_evening

        let jd = sut.testableJulianDate(from: date)

        // March 15, 2024 at 18:00 UTC = JD 2460385.25
        XCTAssertEqual(jd, 2460385.25, accuracy: 0.01,
                       "March 15, 2024 at 18:00 UTC should be close to JD 2460385.25")
    }

    // MARK: - Local Sidereal Time Tests

    func testLST_Greenwich_AtJ2000_ReturnsCorrectValue() {
        // At J2000.0 epoch, GMST should be approximately 18.697 hours
        let j2000 = DateTestHelpers.j2000Epoch

        let lst = sut.testableLST(longitude: 0.0, time: j2000)

        // GMST at J2000.0 = 18.697374558 hours (from USNO)
        XCTAssertEqual(lst, 18.697, accuracy: 0.1,
                       "LST at Greenwich for J2000 should be ~18.7 hours")
    }

    func testLST_EastLongitude_IncreasesLST() {
        let date = DateTestHelpers.j2000Epoch
        let greenwichLST = sut.testableLST(longitude: 0.0, time: date)

        // 15° East should add 1 hour to LST
        let eastLST = sut.testableLST(longitude: 15.0, time: date)

        var expectedLST = greenwichLST + 1.0
        if expectedLST >= 24.0 { expectedLST -= 24.0 }

        XCTAssertEqual(eastLST, expectedLST, accuracy: 0.01,
                       "15° East longitude should add 1 hour to LST")
    }

    func testLST_WestLongitude_DecreasesLST() {
        let date = DateTestHelpers.j2000Epoch
        let greenwichLST = sut.testableLST(longitude: 0.0, time: date)

        // 15° West should subtract 1 hour from LST
        let westLST = sut.testableLST(longitude: -15.0, time: date)

        var expectedLST = greenwichLST - 1.0
        if expectedLST < 0 { expectedLST += 24.0 }

        XCTAssertEqual(westLST, expectedLST, accuracy: 0.01,
                       "15° West longitude should subtract 1 hour from LST")
    }

    func testLST_ReturnsValueInValidRange() {
        let dates = [
            DateTestHelpers.j2000Epoch,
            DateTestHelpers.winterSolstice2024,
            DateTestHelpers.summerSolstice2024
        ]

        for date in dates {
            let lst = sut.testableLST(longitude: TestFixtures.sanFrancisco.longitude, time: date)

            XCTAssertGreaterThanOrEqual(lst, 0.0, "LST should be >= 0")
            XCTAssertLessThan(lst, 24.0, "LST should be < 24")
        }
    }

    // MARK: - Altitude/Azimuth Tests

    func testAltAz_Polaris_AltitudeApproximatelyEqualsLatitude() {
        // Polaris altitude should approximately equal the observer's latitude
        let location = TestFixtures.sanFrancisco
        let date = DateTestHelpers.march15_2024_evening

        let (altitude, _) = sut.testableAltAz(
            ra: TestFixtures.Polaris.ra,
            dec: TestFixtures.Polaris.dec,
            latitude: location.latitude,
            longitude: location.longitude,
            time: date
        )

        // Polaris altitude ≈ observer latitude (within ~1° due to Polaris not being exactly at pole)
        XCTAssertEqual(altitude, location.latitude, accuracy: 2.0,
                       "Polaris altitude should approximately equal observer latitude")
    }

    func testAltAz_Polaris_AlwaysPositiveFromNorthernHemisphere() {
        // Polaris should always be above the horizon from San Francisco
        let location = TestFixtures.sanFrancisco
        let testDates = [
            DateTestHelpers.winterSolstice2024,
            DateTestHelpers.summerSolstice2024,
            DateTestHelpers.vernalEquinox2024,
            DateTestHelpers.march15_2024_evening
        ]

        for date in testDates {
            let (altitude, _) = sut.testableAltAz(
                ra: TestFixtures.Polaris.ra,
                dec: TestFixtures.Polaris.dec,
                latitude: location.latitude,
                longitude: location.longitude,
                time: date
            )

            XCTAssertGreaterThan(altitude, 0,
                                 "Polaris should always be above horizon from \(location.name ?? "Northern Hemisphere")")
        }
    }

    func testAltAz_SigmaOctantis_NeverVisibleFromNorthernHemisphere() {
        // Sigma Octantis (south pole star) should never be visible from San Francisco
        let location = TestFixtures.sanFrancisco
        let testDates = [
            DateTestHelpers.winterSolstice2024,
            DateTestHelpers.summerSolstice2024,
            DateTestHelpers.vernalEquinox2024,
            DateTestHelpers.march15_2024_evening
        ]

        for date in testDates {
            let (altitude, _) = sut.testableAltAz(
                ra: TestFixtures.SigmaOctantis.ra,
                dec: TestFixtures.SigmaOctantis.dec,
                latitude: location.latitude,
                longitude: location.longitude,
                time: date
            )

            XCTAssertLessThan(altitude, 0,
                              "Sigma Octantis should never be visible from Northern Hemisphere")
        }
    }

    func testAltAz_SigmaOctantis_AlwaysVisibleFromSydney() {
        // Sigma Octantis should always be above horizon from Sydney
        let location = TestFixtures.sydney
        let testDates = [
            DateTestHelpers.winterSolstice2024,
            DateTestHelpers.summerSolstice2024
        ]

        for date in testDates {
            let (altitude, _) = sut.testableAltAz(
                ra: TestFixtures.SigmaOctantis.ra,
                dec: TestFixtures.SigmaOctantis.dec,
                latitude: location.latitude,
                longitude: location.longitude,
                time: date
            )

            XCTAssertGreaterThan(altitude, 0,
                                 "Sigma Octantis should always be visible from Southern Hemisphere")
        }
    }

    func testAltAz_TransitAltitude_MatchesFormula() {
        // Transit altitude = 90° - |latitude - declination|
        let location = TestFixtures.sanFrancisco
        let date = DateTestHelpers.march15_2024_evening

        // Use Vega which transits at a reasonable altitude
        // Expected transit altitude = 90 - |37.77 - 38.78| = 90 - 1.01 = ~88.99°
        let expectedMaxAltitude = 90.0 - abs(location.latitude - TestFixtures.Vega.dec)

        // Find the transit time by checking multiple hours
        var maxAltitude = -90.0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        for hour in 0..<24 {
            let testDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let (altitude, _) = sut.testableAltAz(
                ra: TestFixtures.Vega.ra,
                dec: TestFixtures.Vega.dec,
                latitude: location.latitude,
                longitude: location.longitude,
                time: testDate
            )
            maxAltitude = max(maxAltitude, altitude)
        }

        XCTAssertEqual(maxAltitude, expectedMaxAltitude, accuracy: 2.0,
                       "Maximum altitude should match transit altitude formula")
    }

    // MARK: - Circumpolar Object Tests

    func testCircumpolar_PolarisNeverSets_FromSanFrancisco() {
        // Polaris should be above horizon at all hours
        let location = TestFixtures.sanFrancisco
        let baseDate = DateTestHelpers.march15_2024_evening
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var minAltitude = 90.0

        for hour in 0..<24 {
            let testDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate)!
            let (altitude, _) = sut.testableAltAz(
                ra: TestFixtures.Polaris.ra,
                dec: TestFixtures.Polaris.dec,
                latitude: location.latitude,
                longitude: location.longitude,
                time: testDate
            )
            minAltitude = min(minAltitude, altitude)
        }

        XCTAssertGreaterThan(minAltitude, 0,
                             "Polaris should never set from San Francisco (min altitude: \(minAltitude)°)")
    }

    // MARK: - Rise/Transit/Set Cycle Tests

    func testCalculateEphemeris_OrionNebula_HasRiseSetTimes() {
        // Orion Nebula should have normal rise/set cycle from San Francisco
        let location = TestFixtures.sanFrancisco

        // Use a winter evening when Orion is well-placed
        let startTime = DateTestHelpers.utcDate(year: 2024, month: 1, day: 15, hour: 2, minute: 0)  // ~6pm PST
        let endTime = DateTestHelpers.utcDate(year: 2024, month: 1, day: 15, hour: 14, minute: 0)   // ~6am PST next day

        let ephemeris = sut.calculateEphemeris(
            ra: TestFixtures.OrionNebula.ra,
            dec: TestFixtures.OrionNebula.dec,
            location: location,
            startTime: startTime,
            endTime: endTime
        )

        // Orion Nebula should transit during a winter night
        XCTAssertNotNil(ephemeris.transitTime,
                        "Orion Nebula should have a transit time in winter")
        XCTAssertNotNil(ephemeris.transitAltitude,
                        "Orion Nebula should have a transit altitude")

        if let transitAlt = ephemeris.transitAltitude {
            XCTAssertGreaterThan(transitAlt, 0,
                                 "Orion Nebula transit altitude should be positive")
        }
    }

    func testCalculateEphemeris_ReturnsValidAltitudeAtStart() {
        let location = TestFixtures.sanFrancisco
        let startTime = DateTestHelpers.utcDate(year: 2024, month: 1, day: 15, hour: 2, minute: 0)
        let endTime = DateTestHelpers.utcDate(year: 2024, month: 1, day: 15, hour: 14, minute: 0)

        let ephemeris = sut.calculateEphemeris(
            ra: TestFixtures.Vega.ra,
            dec: TestFixtures.Vega.dec,
            location: location,
            startTime: startTime,
            endTime: endTime
        )

        XCTAssertNotNil(ephemeris.altitudeAtStart,
                        "Ephemeris should include altitude at start time")
    }
}
