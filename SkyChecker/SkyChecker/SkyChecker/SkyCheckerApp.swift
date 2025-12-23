import SwiftUI

@main
struct SkyCheckerApp: App {
    @State private var showSplash = true

    init() {
        CacheService.shared.clearExpiredCache()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showSplash {
                    SplashScreenView()
                        .zIndex(1)
                        .onAppear {
                            // Dismiss splash screen after 4 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                showSplash = false
                            }
                        }
                }
            }
        }
    }
}
