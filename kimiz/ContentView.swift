//
//  ContentView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainInterface
            } else {
                OnboardingView(showOnboarding: $showOnboarding)
                    .environmentObject(gamePortingToolkitManager)
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            } else if !gamePortingToolkitManager.isGPTKInstalled {
                // Check GPTK status on app launch if onboarding is complete
                Task {
                    await gamePortingToolkitManager.checkGPTKInstallation()
                }
            }
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue {
                hasCompletedOnboarding = true
            }
        }
    }

    private var mainInterface: some View {
        TabView(selection: $selectedTab) {
            GamesLibraryView()
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("Games")
                }
                .tag(0)
                .environmentObject(gamePortingToolkitManager)

            InstallationView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Install")
                }
                .tag(1)
                .environmentObject(gamePortingToolkitManager)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
                .environmentObject(gamePortingToolkitManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GamePortingToolkitManager.shared)
}
