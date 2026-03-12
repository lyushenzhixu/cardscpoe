//
//  cardscpoeApp.swift
//  cardscpoe
//
//  Created by reverse game on 2026/3/12.
//

import SwiftUI

@main
struct cardscpoeApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
