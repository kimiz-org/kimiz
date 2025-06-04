//
//  kimizApp.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

@main
struct kimizApp: App {
    @StateObject private var wineManager = WineManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wineManager)
        }
    }
}
