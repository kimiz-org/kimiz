//
//  ContentView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wineManager: WineManager
    @State private var selectedTab = 0
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if wineManager.embeddedWineManager.isWineInstalled && !wineManager.winePrefixes.isEmpty {
                MainTabView(selectedTab: $selectedTab)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() {
        // Check if we need to show onboarding
        showOnboarding = !wineManager.embeddedWineManager.isWineInstalled || wineManager.winePrefixes.isEmpty
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var wineManager: WineManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GamesLibraryView()
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("Games")
                }
                .tag(0)

            WinePrefixesView()
                .tabItem {
                    Image(systemName: "server.rack")
                    Text("Wine Prefixes")
                }
                .tag(1)

            InstallationView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Install")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .environmentObject(wineManager)
    }
}

#Preview {
    ContentView()
}
