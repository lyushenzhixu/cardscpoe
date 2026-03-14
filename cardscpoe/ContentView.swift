import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var appState = AppState()
    @Environment(\.modelContext) private var modelContext

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
        .task {
            await appState.bootstrap(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
}
