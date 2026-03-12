//
//  ContentView.swift
//  cardscpoe
//
//  Created by reverse game on 2026/3/12.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(onComplete: {
                    appState.hasCompletedOnboarding = true
                })
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(AppState.shared)
}
