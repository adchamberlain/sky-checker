import Foundation
@testable import SkyChecker

/// Test fixtures for astronomical calculations
enum TestFixtures {

    // MARK: - Location Fixtures

    /// San Francisco, California (37.7749°N, 122.4194°W)
    /// Mid-latitude Northern Hemisphere location
    static let sanFrancisco = ObserverLocation(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 16,
        name: "San Francisco"
    )

    /// Tromsø, Norway (69.6496°N, 18.9560°E)
    /// Arctic location - experiences midnight sun but still has civil twilight in winter
    static let tromso = ObserverLocation(
        latitude: 69.6496,
        longitude: 18.9560,
        altitude: 10,
        name: "Tromsø"
    )

    /// Longyearbyen, Svalbard (78.2232°N, 15.6267°E)
    /// High Arctic location - experiences true civil twilight polar night
    static let longyearbyen = ObserverLocation(
        latitude: 78.2232,
        longitude: 15.6267,
        altitude: 0,
        name: "Longyearbyen"
    )

    /// Quito, Ecuador (0.1807°S, 78.4678°W)
    /// Equatorial location - consistent sunrise/sunset year-round
    static let quito = ObserverLocation(
        latitude: -0.1807,
        longitude: -78.4678,
        altitude: 2850,
        name: "Quito"
    )

    /// Sydney, Australia (33.8688°S, 151.2093°E)
    /// Southern Hemisphere mid-latitude - reversed seasons
    static let sydney = ObserverLocation(
        latitude: -33.8688,
        longitude: 151.2093,
        altitude: 58,
        name: "Sydney"
    )

    /// Greenwich, UK (51.4772°N, 0.0°E)
    /// Prime meridian reference point for LST calculations
    static let greenwich = ObserverLocation(
        latitude: 51.4772,
        longitude: 0.0,
        altitude: 0,
        name: "Greenwich"
    )

    /// North Pole (90°N, 0°E)
    /// Extreme latitude where azimuth is undefined
    static let northPole = ObserverLocation(
        latitude: 90.0,
        longitude: 0.0,
        altitude: 0,
        name: "North Pole"
    )

    /// South Pole (90°S, 0°E)
    /// Extreme latitude where azimuth is undefined
    static let southPole = ObserverLocation(
        latitude: -90.0,
        longitude: 0.0,
        altitude: 0,
        name: "South Pole"
    )

    // MARK: - Celestial Object Fixtures

    /// Polaris (North Star)
    /// RA: 2h 31m 49s = 2.5303h, Dec: +89° 15' 51" = +89.2642°
    /// Circumpolar from Northern Hemisphere, never visible from Southern
    struct Polaris {
        static let ra: Double = 2.5303     // hours
        static let dec: Double = 89.2642   // degrees
        static let name = "Polaris"
    }

    /// Sigma Octantis (South Pole Star)
    /// RA: 21h 08m 47s = 21.1464h, Dec: -88° 57' 23" = -88.9564°
    /// Circumpolar from Southern Hemisphere, never visible from Northern
    struct SigmaOctantis {
        static let ra: Double = 21.1464    // hours
        static let dec: Double = -88.9564  // degrees
        static let name = "Sigma Octantis"
    }

    /// Vega (Alpha Lyrae)
    /// RA: 18h 36m 56s = 18.6156h, Dec: +38° 47' 01" = +38.7836°
    /// Bright star, visible from most locations
    struct Vega {
        static let ra: Double = 18.6156    // hours
        static let dec: Double = 38.7836   // degrees
        static let name = "Vega"
    }

    /// Orion Nebula (M42)
    /// RA: 5h 35m 17s = 5.5881h, Dec: -5° 23' 28" = -5.3911°
    /// Winter object in Northern Hemisphere, rises and sets normally
    struct OrionNebula {
        static let ra: Double = 5.5881     // hours
        static let dec: Double = -5.3911   // degrees
        static let name = "Orion Nebula"
    }

    /// Canopus (Alpha Carinae)
    /// RA: 6h 23m 57s = 6.3992h, Dec: -52° 41' 44" = -52.6956°
    /// Visible from southern latitudes and far south in Northern Hemisphere
    struct Canopus {
        static let ra: Double = 6.3992     // hours
        static let dec: Double = -52.6956  // degrees
        static let name = "Canopus"
    }
}
