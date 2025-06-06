//
//  kimizApp.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

@main
struct kimizApp: App {
    @StateObject private var gamePortingToolkitManager = GamePortingToolkitManager.shared
    @StateObject private var epicGamesManager = EpicGamesManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gamePortingToolkitManager)
                .environmentObject(epicGamesManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 640, height: 480)
    }
}
