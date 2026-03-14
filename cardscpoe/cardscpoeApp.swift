//
//  cardscpoeApp.swift
//  cardscpoe
//
//  Created by reverse game on 2026/3/12.
//

import SwiftUI
import SwiftData

@main
struct cardscpoeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            StoredCard.self,
            StoredPlayer.self,
            StoredScanHistory.self,
        ])
    }
}
