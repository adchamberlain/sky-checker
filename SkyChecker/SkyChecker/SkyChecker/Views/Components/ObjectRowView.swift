import SwiftUI

struct ObjectRowView: View {
    let object: CelestialObject
    
    var body: some View {
        HStack(spacing: 0) {
            // Object name with indicator
            HStack(spacing: 4) {
                Text(statusIndicator)
                Text(object.displayName)
            }
            .frame(width: 100, alignment: .leading)
            
            // Status
            Text(statusText)
                .frame(width: 70, alignment: .leading)
            
            // Rise time
            Text(riseTimeText)
                .frame(width: 60, alignment: .leading)
            
            // Current position
            Text(currentPositionText)
                .frame(width: 80, alignment: .leading)
        }
        .font(.terminalCaption)
        .foregroundColor(object.isVisible ? .terminalBright : .terminalGreen)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(object.isVisible ? Color.terminalGreen.opacity(0.1) : Color.clear)
        )
    }
    
    private var statusIndicator: String {
        switch object.visibilityStatus {
        case .visible: return "[*]"
        case .notYetRisen: return "[~]"
        case .alreadySet: return "[x]"
        case .belowHorizon: return "[-]"
        case .tooCloseToSun: return "[!]"
        case .none: return "[?]"
        }
    }

    private var statusText: String {
        switch object.visibilityStatus {
        case .visible: return "Visible"
        case .notYetRisen: return "Rising"
        case .alreadySet: return "Set"
        case .belowHorizon: return "Below"
        case .tooCloseToSun: return "Sun"
        case .none: return "?"
        }
    }

    private var riseTimeText: String {
        if let riseTime = object.riseTime {
            // If rise time has passed, show "Up" instead
            if riseTime < Date() {
                return "Up"
            }
            return formatTime(riseTime)
        }
        // If no rise time but object is visible, it was already up at sunset
        if object.visibilityStatus == .visible {
            return "Up"
        }
        return "--:--"
    }

    private var currentPositionText: String {
        if let alt = object.currentAltitude, let dir = object.currentDirection {
            return "\(Int(alt))° \(dir.rawValue)"
        }
        return "--"
    }

    private func formatTime(_ date: Date) -> String {
        SunsetService.formatTime(date)
    }
}
