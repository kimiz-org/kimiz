//
//  kimizApp.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import SwiftUI

@main
struct kimizApp: App {
    @StateObject private var gamePortingToolkitManager = GamePortingToolkitManager.shared
    @StateObject private var epicGamesManager = EpicGamesManager.shared
    @StateObject private var bottleManager = BottleManager.shared
    @StateObject private var engineManager = EngineManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gamePortingToolkitManager)
                .environmentObject(epicGamesManager)
                .environmentObject(bottleManager)
                .environmentObject(engineManager)
                .onOpenURL { url in
                    handleURLScheme(url)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 640, height: 480)
    }

    private func handleURLScheme(_ url: URL) {
        // Handle Epic Games OAuth redirect
        if url.scheme == "kimiz" && url.host == "oauth" {
            // The ASWebAuthenticationSession handles this automatically
            // This is just for additional logging or custom handling if needed
            print("Received OAuth callback URL: \(url)")
        }
    }
}
