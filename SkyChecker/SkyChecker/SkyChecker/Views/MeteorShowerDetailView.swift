import SwiftUI

struct MeteorShowerDetailView: View {
    let status: MeteorShowerStatus

    private var shower: MeteorShower { status.shower }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    Text("Shower: \(shower.name)")
                        .foregroundColor(.terminalBright)

                    Text("Type: Meteor Shower")
                        .foregroundColor(.terminalGreen)

                    Text("Status: \(statusText)")
                        .foregroundColor(status.isActive ? .terminalBright : .terminalGreen)

                    // ASCII art
                    Text("")
                    Text(meteorAsciiArt)
                        .foregroundColor(.terminalBright)

                    // Details
                    Text("")
                    Text("── Shower Details ──")
                        .foregroundColor(.terminalDim)

                    HStack {
                        Text("Rate:")
                            .frame(width: 80, alignment: .leading)
                        Text("~\(shower.zhr) meteors/hour")
                    }
                    .foregroundColor(.terminalGreen)

                    HStack {
                        Text("Radiant:")
                            .frame(width: 80, alignment: .leading)
                        Text(shower.radiantConstellation)
                    }
                    .foregroundColor(.terminalGreen)

                    HStack {
                        Text("Source:")
                            .frame(width: 80, alignment: .leading)
                        Text(shower.parentBody)
                    }
                    .foregroundColor(.terminalGreen)

                    // Schedule
                    Text("")
                    Text("── Schedule ──")
                        .foregroundColor(.terminalDim)

                    HStack {
                        Text("Peak:")
                            .frame(width: 80, alignment: .leading)
                        Text(formatPeakDate)
                    }
                    .foregroundColor(.terminalGreen)

                    HStack {
                        Text("Active:")
                            .frame(width: 80, alignment: .leading)
                        Text(activeRangeText)
                    }
                    .foregroundColor(.terminalGreen)

                    if status.isActive {
                        Text("")
                        Text("* Shower is currently active! *")
                            .foregroundColor(.terminalBright)
                    }

                    // Tips
                    Text("")
                    Text("── Viewing Tips ──")
                        .foregroundColor(.terminalDim)

                    Text(shower.description)
                        .foregroundColor(.terminalGreen)

                    Text("")
                    Text("Best viewing: After midnight")
                        .foregroundColor(.terminalGreen)
                    Text("Look toward: \(shower.radiantConstellation)")
                        .foregroundColor(.terminalGreen)

                    // Wikipedia link
                    Text("")
                    Text("── Learn More ──")
                        .foregroundColor(.terminalDim)

                    if let url = shower.wikipediaURL {
                        Link(destination: url) {
                            Text("[Read on Wikipedia]")
                                .foregroundColor(.terminalBright)
                                .underline()
                        }
                    }

                    Spacer()
                }
                .font(.terminalCaption)
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("< \(shower.name) >")
                    .font(.terminalTitle)
                    .foregroundColor(.terminalGreen)
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var statusText: String {
        if status.isActive {
            if status.daysUntilPeak == 0 {
                return "Peak Tonight!"
            } else if status.daysUntilPeak > 0 {
                return "Active - \(status.daysUntilPeak)d to peak"
            } else {
                return "Active - Past Peak"
            }
        } else {
            return "\(status.daysUntilPeak) days away"
        }
    }

    private var formatPeakDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: status.peakDate)
    }

    private var activeRangeText: String {
        let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let startMonth = months[shower.activeStart.month]
        let endMonth = months[shower.activeEnd.month]
        return "\(startMonth) \(shower.activeStart.day) - \(endMonth) \(shower.activeEnd.day)"
    }

    private var meteorAsciiArt: String {
        """
              *
             /
            /
        ___/___
           \\
            \\  *
             \\
              *
        """
    }
}
