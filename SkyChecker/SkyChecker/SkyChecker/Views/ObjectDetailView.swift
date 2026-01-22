import SwiftUI

struct ObjectDetailView: View {
    let objectId: String
    @ObservedObject var viewModel: SkyCheckerViewModel
    
    private var object: CelestialObject? {
        viewModel.objects.first { $0.id == objectId }
            ?? CelestialObject.solarSystemObjects.first { $0.id == objectId }
            ?? CelestialObject.messierObjects.first { $0.id == objectId }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let object = object {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // Header
                        Text("Object: \(object.name)")
                            .foregroundColor(.terminalBright)

                        Text("Type: \(object.type.displayName)")
                            .foregroundColor(.terminalGreen)

                        Text("Equipment: \(object.difficulty.rawValue)")
                            .foregroundColor(.terminalGreen)

                        Text("Status: \(statusText)")
                            .foregroundColor(object.isVisible ? .terminalBright : .terminalGreen)
                    
                    // Moon phase
                    if object.type == .moon, let phase = object.moonPhase {
                        Text("")
                        Text("── Lunar Data ──")
                            .foregroundColor(.terminalDim)
                        Text("Phase: \(phase.rawValue)")
                            .foregroundColor(.terminalGreen)
                        if let ill = object.illuminationPercent {
                            Text("Illumination: \(String(format: "%.1f", ill))%")
                                .foregroundColor(.terminalGreen)
                        }
                        Text(moonAsciiArt(phase: phase))
                            .foregroundColor(.terminalBright)
                    }

                    // Planet art
                    if object.type == .planet, let art = planetAsciiArt(objectId: object.id) {
                        Text("")
                        Text(art)
                            .foregroundColor(.terminalBright)
                    }

                    // Deep sky object art
                    if object.type == .messier, let art = messierAsciiArt(objectId: object.id) {
                        Text("")
                        Text(art)
                            .foregroundColor(.terminalBright)
                    }

                    // Satellite art (ISS)
                    if object.type == .satellite, let art = satelliteAsciiArt(objectId: object.id) {
                        Text("")
                        Text(art)
                            .foregroundColor(.terminalBright)
                    }

                    // Schedule
                    Text("")
                    Text("── Tonight's Schedule ──")
                        .foregroundColor(.terminalDim)

                    // Current position
                    HStack {
                        Text("Now:")
                            .frame(width: 50, alignment: .leading)
                        if let currentAlt = object.currentAltitude {
                            Text("[\(String(format: "%.1f", currentAlt))°]")
                                .foregroundColor(.terminalDim)
                        } else {
                            Text("[--]")
                                .foregroundColor(.terminalDim)
                        }
                        if let currentDir = object.currentDirection {
                            Text("[\(currentDir.rawValue)]")
                                .foregroundColor(.terminalDim)
                        } else {
                            Text("[--]")
                                .foregroundColor(.terminalDim)
                        }
                    }
                    .foregroundColor(.terminalGreen)

                    if let rise = object.riseTime {
                        HStack {
                            Text("Rise:")
                                .frame(width: 50, alignment: .leading)
                            Text(formatTime(rise))
                            if let dir = object.riseDirection {
                                Text("[\(dir.rawValue)]")
                                    .foregroundColor(.terminalDim)
                            }
                        }
                        .foregroundColor(.terminalGreen)
                    } else if object.transitTime != nil || object.setTime != nil {
                        Text("Rise: Already up at sunset")
                            .foregroundColor(.terminalGreen)
                    }
                    
                    if let transit = object.transitTime {
                        HStack {
                            Text("Peak:")
                                .frame(width: 50, alignment: .leading)
                            Text(formatTime(transit))
                            if let alt = object.transitAltitude {
                                Text("[\(String(format: "%.1f", alt))°]")
                                    .foregroundColor(.terminalDim)
                            }
                            if let dir = object.transitDirection {
                                Text("[\(dir.rawValue)]")
                                    .foregroundColor(.terminalDim)
                            }
                        }
                        .foregroundColor(.terminalGreen)
                    }
                    
                    if let set = object.setTime {
                        HStack {
                            Text("Set:")
                                .frame(width: 50, alignment: .leading)
                            Text(formatTime(set))
                            if let dir = object.setDirection {
                                Text("[\(dir.rawValue)]")
                                    .foregroundColor(.terminalDim)
                            }
                        }
                        .foregroundColor(.terminalGreen)
                    } else if object.riseTime != nil || object.transitTime != nil {
                        Text("Set: Still up at sunrise")
                            .foregroundColor(.terminalGreen)
                    }
                    
                    if object.riseTime == nil && object.transitTime == nil && object.setTime == nil {
                        Text("* Not visible tonight *")
                            .foregroundColor(.terminalDim)
                    }

                    // Wikipedia link
                    Text("")
                    Text("── Learn More ──")
                        .foregroundColor(.terminalDim)

                    if let url = object.wikipediaURL {
                        Link(destination: url) {
                            Text("[Read]")
                                .foregroundColor(.terminalBright)
                                .underline()
                        }
                    }

                        Spacer()
                    }
                    .font(.terminalCaption)
                    .padding()
                }
            } else {
                Text("Object not found")
                    .foregroundColor(.terminalDim)
                    .font(.terminalCaption)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("< \(object?.name ?? "Unknown") >")
                    .font(.terminalTitle)
                    .foregroundColor(.terminalGreen)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let object = object {
                    ShareLink(item: object.shareText()) {
                        Text("[Share]")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalGreen)
                    }
                }
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    private var statusText: String {
        switch object?.visibilityStatus {
        case .visible: return "Visible Now"
        case .notYetRisen: return "Rises Later"
        case .alreadySet: return "Already Set"
        case .belowHorizon: return "Below Horizon"
        case .tooCloseToSun: return "Too Close to Sun"
        case .none: return "?"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        SunsetService.formatTime(date)
    }
    
    private func moonAsciiArt(phase: MoonPhase) -> String {
        switch phase {
        case .newMoon:
            return "    .---.   \n   /     \\  \n  |       | \n   \\     /  \n    '---'   "
        case .waxingCrescent:
            return "    .---.   \n   /    ))  \n  |    ))   \n   \\    ))  \n    '---'   "
        case .firstQuarter:
            return "    .---.   \n   /   ||   \n  |    ||   \n   \\   ||   \n    '---'   "
        case .waxingGibbous:
            return "    .---.   \n   ((   |   \n  ((    |   \n   ((   |   \n    '---'   "
        case .fullMoon:
            return "    .---.   \n   (     )  \n  (       ) \n   (     )  \n    '---'   "
        case .waningGibbous:
            return "    .---.   \n   |   ))   \n  |    ))   \n   |   ))   \n    '---'   "
        case .lastQuarter:
            return "    .---.   \n   ||   \\   \n   ||    |  \n   ||   /   \n    '---'   "
        case .waningCrescent:
            return "    .---.   \n  ((    \\   \n   ((    |  \n  ((    /   \n    '---'   "
        }
    }

    private func planetAsciiArt(objectId: String) -> String? {
        switch objectId {
        case "mercury":
            return "    .---.   \n   / . . \\  \n  | .   . | \n   \\ . . /  \n    '---'   "
        case "venus":
            return "    .---.   \n   /~~~~~\\  \n  |~~~~~~~| \n   \\~~~~~/  \n    '---'   "
        case "mars":
            return "    .---.   \n   / ___ \\  \n  | (   ) | \n   \\ ___ /  \n    '---'   "
        case "jupiter":
            return "     .------.\n    /========\\\n   | -======- |\n    \\=====@==/\n     '------'   "
        case "saturn":
            return "       .---.       \n      /     \\   \n-----|-------|-----\n      \\     /\n       '---'       "
        case "uranus":
            return "    .---.   \n   /  |  \\  \n  |   |   | \n   \\  |  /  \n    '---'   "
        case "neptune":
            return "    .---.   \n   / ~~~ \\  \n  | ~ * ~ | \n   \\ ~~~ /  \n    '---'   "
        default:
            return nil
        }
    }

    private func messierAsciiArt(objectId: String) -> String? {
        switch objectId {
        case "m31":
            // Andromeda Galaxy - spiral shape
            return "       .  *  .       \n    *    .    *    \n  .   ~~~~~~~~   .  \n *  ~~~~~~~~~~~~  * \n  .   ~~~~~~~~   .  \n    *    .    *    \n       .  *  .       "
        case "m42":
            // Orion Nebula - cloud shape
            return "      . * . *       \n   .* ~ ~ ~ ~ *.   \n  * ~ ~ * ~ ~ ~ *  \n   .* ~ ~ ~ ~ *.   \n      . * . *       "
        case "m22":
            // Globular Cluster - dense star ball
            return "      . * .       \n    * * * * *    \n   * * * * * *   \n    * * * * *    \n      . * .       "
        case "m45":
            // Pleiades - Seven Sisters pattern
            return "     *           *  \n        *     *     \n      *   * *       \n        *     *     \n     *           *  "
        case "m44":
            // Beehive Cluster - scattered stars
            return "    *   *   *     \n      *   *   *   \n    *   *   *   * \n      *   *   *   \n    *   *   *     "
        case "m13":
            // Hercules Cluster - dense globular
            return "       . * .       \n     * * * * *     \n    * * * * * *    \n   * * * * * * *   \n    * * * * * *    \n     * * * * *     \n       . * .       "
        default:
            return nil
        }
    }

    private func satelliteAsciiArt(objectId: String) -> String? {
        switch objectId {
        case "iss":
            // ISS - simplified space station shape
            return "    |==|==|    \n  ]=======|    \n----[=====]----\n  ]=======|    \n    |==|==|    "
        default:
            return nil
        }
    }
}
