import Foundation

enum CelestialObjectType: String, Codable, CaseIterable {
    case planet
    case moon
    case messier
    case satellite

    var displayName: String {
        switch self {
        case .planet: return "Planet"
        case .moon: return "Moon"
        case .messier: return "Deep Sky Object"
        case .satellite: return "Satellite"
        }
    }
}

enum MoonPhase: String, Codable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"
    
    var emoji: String {
        switch self {
        case .newMoon: return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter: return "🌓"
        case .waxingGibbous: return "🌔"
        case .fullMoon: return "🌕"
        case .waningGibbous: return "🌖"
        case .lastQuarter: return "🌗"
        case .waningCrescent: return "🌘"
        }
    }
    
    static func from(illumination: Double, isWaxing: Bool) -> MoonPhase {
        switch illumination {
        case 0..<3: return .newMoon
        case 3..<47: return isWaxing ? .waxingCrescent : .waningCrescent
        case 47..<53: return isWaxing ? .firstQuarter : .lastQuarter
        case 53..<97: return isWaxing ? .waxingGibbous : .waningGibbous
        default: return .fullMoon
        }
    }
}

enum SkyDirection: String, Codable {
    case north = "N", northEast = "NE", east = "E", southEast = "SE"
    case south = "S", southWest = "SW", west = "W", northWest = "NW"
    
    var fullName: String {
        switch self {
        case .north: return "North"
        case .northEast: return "Northeast"
        case .east: return "East"
        case .southEast: return "Southeast"
        case .south: return "South"
        case .southWest: return "Southwest"
        case .west: return "West"
        case .northWest: return "Northwest"
        }
    }
    
    static func from(azimuth: Double) -> SkyDirection {
        let n = azimuth.truncatingRemainder(dividingBy: 360)
        switch n {
        case 337.5..<360, 0..<22.5: return .north
        case 22.5..<67.5: return .northEast
        case 67.5..<112.5: return .east
        case 112.5..<157.5: return .southEast
        case 157.5..<202.5: return .south
        case 202.5..<247.5: return .southWest
        case 247.5..<292.5: return .west
        case 292.5..<337.5: return .northWest
        default: return .north
        }
    }
}

enum VisibilityStatus: Codable {
    case visible, notYetRisen, alreadySet, belowHorizon, tooCloseToSun

    var displayText: String {
        switch self {
        case .visible: return "Visible Now"
        case .notYetRisen: return "Rises Later"
        case .alreadySet: return "Already Set"
        case .belowHorizon: return "Below Horizon"
        case .tooCloseToSun: return "Too Close to Sun"
        }
    }
}

enum DifficultyRating: String, Codable, CaseIterable {
    case nakedEye = "Naked Eye"
    case binoculars = "Binoculars"
    case smallTelescope = "Small Telescope"
    case largeTelescope = "Large Telescope"

    var shortName: String {
        switch self {
        case .nakedEye: return "Eye"
        case .binoculars: return "Bino"
        case .smallTelescope: return "Scope"
        case .largeTelescope: return "L.Scope"
        }
    }

    var terminalIndicator: String {
        switch self {
        case .nakedEye: return "[*]"
        case .binoculars: return "[B]"
        case .smallTelescope: return "[T]"
        case .largeTelescope: return "[L]"
        }
    }
}

struct CelestialObject: Identifiable, Codable {
    let id: String
    let name: String
    var shortName: String?  // Short name for list view (defaults to name if nil)
    let type: CelestialObjectType
    let horizonsCommand: String
    let difficulty: DifficultyRating
    // Fixed coordinates for deep sky objects (RA in hours, Dec in degrees)
    var rightAscension: Double?
    var declination: Double?
    var riseTime: Date?
    var setTime: Date?
    var riseAzimuth: Double?
    var setAzimuth: Double?
    var currentAltitude: Double?
    var currentAzimuth: Double?
    var transitTime: Date?
    var transitAltitude: Double?
    var transitAzimuth: Double?
    var moonPhase: MoonPhase?
    var illuminationPercent: Double?
    var visibilityStatus: VisibilityStatus?
    var lastUpdated: Date?
    var iconName: String
    var description: String

    var riseDirection: SkyDirection? { riseAzimuth.map { SkyDirection.from(azimuth: $0) } }
    var setDirection: SkyDirection? { setAzimuth.map { SkyDirection.from(azimuth: $0) } }
    var transitDirection: SkyDirection? { transitAzimuth.map { SkyDirection.from(azimuth: $0) } }
    var currentDirection: SkyDirection? { currentAzimuth.map { SkyDirection.from(azimuth: $0) } }
    var isVisible: Bool { visibilityStatus == .visible }
    var displayName: String { shortName ?? name }  // Use shortName for lists, falls back to name

    var wikipediaURL: URL? {
        // Map object IDs to Wikipedia article names
        let articleName: String
        switch id {
        case "moon": articleName = "Moon"
        case "mercury": articleName = "Mercury_(planet)"
        case "venus": articleName = "Venus"
        case "mars": articleName = "Mars"
        case "jupiter": articleName = "Jupiter"
        case "saturn": articleName = "Saturn"
        case "uranus": articleName = "Uranus"
        case "neptune": articleName = "Neptune"
        case "m31": articleName = "Andromeda_Galaxy"
        case "m42": articleName = "Orion_Nebula"
        case "m22": articleName = "Messier_22"
        case "m45": articleName = "Pleiades"
        case "m44": articleName = "Beehive_Cluster"
        case "m13": articleName = "Messier_13"
        case "iss": articleName = "International_Space_Station"
        default: articleName = name.replacingOccurrences(of: " ", with: "_")
        }
        return URL(string: "https://en.wikipedia.org/wiki/\(articleName)")
    }

    /// Generate shareable text for this object
    func shareText() -> String {
        var lines: [String] = []

        // Header
        lines.append("\(name) - Tonight's Visibility")
        lines.append("")

        // Status
        if let status = visibilityStatus {
            lines.append("Status: \(status.displayText)")
        }
        lines.append("Equipment: \(difficulty.rawValue)")

        // Moon phase info
        if type == .moon, let phase = moonPhase {
            lines.append("Phase: \(phase.rawValue)")
            if let ill = illuminationPercent {
                lines.append("Illumination: \(String(format: "%.0f", ill))%")
            }
        }

        // Current position
        if let alt = currentAltitude, let dir = currentDirection {
            lines.append("Current: \(String(format: "%.0f", alt))° altitude, \(dir.fullName)")
        }

        // Schedule
        if riseTime != nil || transitTime != nil || setTime != nil {
            lines.append("")
            if let rise = riseTime {
                let dir = riseDirection?.rawValue ?? ""
                lines.append("Rise: \(formatTimeForShare(rise)) \(dir)")
            }
            if let transit = transitTime {
                let alt = transitAltitude.map { String(format: "%.0f°", $0) } ?? ""
                lines.append("Peak: \(formatTimeForShare(transit)) \(alt)")
            }
            if let set = setTime {
                let dir = setDirection?.rawValue ?? ""
                lines.append("Set: \(formatTimeForShare(set)) \(dir)")
            }
        }

        lines.append("")
        lines.append("via SkyChecker")

        return lines.joined(separator: "\n")
    }

    private func formatTimeForShare(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

extension CelestialObject {
    static let solarSystemObjects: [CelestialObject] = [
        CelestialObject(id: "moon", name: "The Moon", shortName: "Moon", type: .moon, horizonsCommand: "301", difficulty: .nakedEye, iconName: "moon.fill", description: "Earth's natural satellite"),
        CelestialObject(id: "mercury", name: "Mercury", type: .planet, horizonsCommand: "199", difficulty: .nakedEye, iconName: "circle.fill", description: "The smallest planet"),
        CelestialObject(id: "venus", name: "Venus", type: .planet, horizonsCommand: "299", difficulty: .nakedEye, iconName: "sparkle", description: "The morning/evening star"),
        CelestialObject(id: "mars", name: "Mars", type: .planet, horizonsCommand: "499", difficulty: .nakedEye, iconName: "circle.fill", description: "The Red Planet"),
        CelestialObject(id: "jupiter", name: "Jupiter", type: .planet, horizonsCommand: "599", difficulty: .nakedEye, iconName: "circle.fill", description: "The largest planet"),
        CelestialObject(id: "saturn", name: "Saturn", type: .planet, horizonsCommand: "699", difficulty: .nakedEye, iconName: "circle.fill", description: "The ringed planet"),
        CelestialObject(id: "uranus", name: "Uranus", type: .planet, horizonsCommand: "799", difficulty: .binoculars, iconName: "circle.fill", description: "The ice giant"),
        CelestialObject(id: "neptune", name: "Neptune", type: .planet, horizonsCommand: "899", difficulty: .smallTelescope, iconName: "circle.fill", description: "The distant blue planet")
    ]

    static let messierObjects: [CelestialObject] = [
        CelestialObject(id: "m31", name: "M31 Andromeda Galaxy", shortName: "M31", type: .messier, horizonsCommand: "", difficulty: .nakedEye, rightAscension: 0.7122, declination: 41.27, iconName: "sparkles", description: "The nearest major galaxy"),
        CelestialObject(id: "m42", name: "M42 Orion Nebula", shortName: "M42", type: .messier, horizonsCommand: "", difficulty: .nakedEye, rightAscension: 5.59, declination: -5.45, iconName: "cloud.fill", description: "The great nebula in Orion"),
        CelestialObject(id: "m22", name: "M22 Globular Cluster", shortName: "M22", type: .messier, horizonsCommand: "", difficulty: .binoculars, rightAscension: 18.607, declination: -23.90, iconName: "star.fill", description: "Bright globular cluster"),
        CelestialObject(id: "m45", name: "M45 Pleiades", shortName: "M45", type: .messier, horizonsCommand: "", difficulty: .nakedEye, rightAscension: 3.7833, declination: 24.1167, iconName: "star.fill", description: "The Seven Sisters star cluster"),
        CelestialObject(id: "m44", name: "M44 Beehive Cluster", shortName: "M44", type: .messier, horizonsCommand: "", difficulty: .nakedEye, rightAscension: 8.6733, declination: 19.6717, iconName: "star.fill", description: "Open cluster in Cancer"),
        CelestialObject(id: "m13", name: "M13 Hercules Cluster", shortName: "M13", type: .messier, horizonsCommand: "", difficulty: .binoculars, rightAscension: 16.6947, declination: 36.4617, iconName: "star.fill", description: "Great globular in Hercules")
    ]

    static let satelliteObjects: [CelestialObject] = [
        CelestialObject(id: "iss", name: "ISS", shortName: "ISS", type: .satellite, horizonsCommand: "", difficulty: .nakedEye, iconName: "airplane", description: "International Space Station")
    ]
}

