import SwiftUI

struct AboutView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("── About SkyChecker v2.0 ──")
                            .foregroundColor(.terminalDim)

                        Text("What it does:")
                            .foregroundColor(.terminalBright)

                        Text("""
                        Your complete guide to tonight's sky. See what's visible from your location:

                        [*] Visible now
                        [~] Rising soon
                        [x] Already set
                        [-] Below horizon

                        Objects tracked:

                        • Moon (with phase & illumination)
                        • All planets (Mercury - Neptune)
                        • Deep sky objects (M31, M42, M45...)
                        • ISS passes
                        • Meteor shower alerts

                        Features:

                        • Live weather conditions & forecast
                        • Equipment difficulty ratings
                        • GPS or manual location
                        • Plan future observing sessions
                        • Share tonight's sky with friends
                        • Rise, peak, and set times
                        • ASCII art visualizations!

                        Data from:
                        """)
                            .foregroundColor(.terminalGreen)
                            .fixedSize(horizontal: false, vertical: true)

                        Link("NASA JPL Horizons API", destination: URL(string: "https://ssd-api.jpl.nasa.gov/doc/horizons.html")!)
                            .foregroundColor(.terminalGreen)
                            .underline()

                        Link("Open-Meteo Weather API", destination: URL(string: "https://open-meteo.com")!)
                            .foregroundColor(.terminalGreen)
                            .underline()

                        Text("")

                        Text("── Credits ──")
                            .foregroundColor(.terminalDim)

                        Text("Created by:")
                            .foregroundColor(.terminalGreen)

                        Text("Andrew Chamberlain, Ph.D.")
                            .foregroundColor(.terminalBright)

                        Link("andrewchamberlain.com", destination: URL(string: "https://andrewchamberlain.com")!)
                            .foregroundColor(.terminalGreen)
                            .underline()

                        Text("")

                        Text("── App Store ──")
                            .foregroundColor(.terminalDim)

                        Link("Rate on App Store", destination: URL(string: "https://apps.apple.com/us/app/skychecker/id6757621845")!)
                            .foregroundColor(.terminalGreen)
                            .underline()

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
                    Text("About")
                        .font(.terminalTitle)
                        .foregroundColor(.terminalGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { onDismiss() } label: {
                        Text("[Close]")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalGreen)
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
