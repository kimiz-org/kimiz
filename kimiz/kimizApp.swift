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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gamePortingToolkitManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 640, height: 480)
    }
}
