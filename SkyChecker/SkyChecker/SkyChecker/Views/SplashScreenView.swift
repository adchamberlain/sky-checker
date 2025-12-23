import SwiftUI

struct SplashScreenView: View {
    @State private var showText = false
    @State private var showStars = false
    @State private var showStatus = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // ASCII stars
                if showStars {
                    Text("""

                           *         .        *
                        .    *   .      *   .    *
                      *   .       *  .    *     .
                         .    *      .   *    .
                    """)
                    .font(.terminal(14))
                    .foregroundColor(.terminalGreen)
                    .opacity(showStars ? 1 : 0)
                    .transition(.opacity)
                }

                // App title
                if showText {
                    Text("SkyChecker")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalBright)
                        .opacity(showText ? 1 : 0)
                        .transition(.opacity)
                }

                // Status message
                if showStatus {
                    HStack(spacing: 4) {
                        Text(">")
                            .foregroundColor(.terminalGreen)
                        Text("Finding objects in view tonight...")
                            .foregroundColor(.terminalGreen)
                    }
                    .font(.terminal(16))
                    .opacity(showStatus ? 1 : 0)
                    .transition(.opacity)
                }

                Spacer()
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Sequence the animations
            withAnimation(.easeIn(duration: 0.3)) {
                showStars = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showText = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showStatus = true
                }
            }
        }
    }
}
