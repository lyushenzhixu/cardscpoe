import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        Group {
            if appState.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(appState)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
