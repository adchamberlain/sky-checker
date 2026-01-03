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

            // Set time
            Text(setTimeText)
                .frame(width: 60, alignment: .leading)
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
            return formatTime(riseTime)
        }
        return "—"
    }

    private var setTimeText: String {
        if let setTime = object.setTime {
            return formatTime(setTime)
        }
        return "—"
    }

    private func formatTime(_ date: Date) -> String {
        SunsetService.formatTime(date)
    }
}
