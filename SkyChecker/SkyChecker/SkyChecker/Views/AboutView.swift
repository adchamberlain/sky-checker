import SwiftUI

struct AboutView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("── About SkyChecker ──")
                            .foregroundColor(.terminalDim)

                        Text("What it does:")
                            .foregroundColor(.terminalBright)

                        Text("""
                        Quickly see which objects are visible tonight with a telescope, based on your current location and time:

                        [*] Visible now
                        [~] Rising soon
                        [x] Already set
                        [-] Won't rise tonight

                        Features:

                        • Use GPS or manual location
                        • Check current or future nights
                        • See planet details:
                          - Current direction and altitude
                          - Rise, peak, and set times
                          - Moon phase and illumination
                          - Sweet ASCII art included!

                        Data from:
                        """)
                            .foregroundColor(.terminalGreen)
                            .fixedSize(horizontal: false, vertical: true)

                        Link("NASA JPL Horizons API.", destination: URL(string: "https://ssd-api.jpl.nasa.gov/doc/horizons.html")!)
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
