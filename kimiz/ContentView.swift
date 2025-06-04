//
//  ContentView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var embeddedWineManager = EmbeddedWineManager()
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainInterface
            } else {
                OnboardingView(showOnboarding: $showOnboarding)
                    .environmentObject(embeddedWineManager)
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            } else if !embeddedWineManager.hasCheckedWineStatus {
                // Check Wine status on app launch if onboarding is complete
                Task {
                    await embeddedWineManager.checkWineInstallation()
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
                .environmentObject(embeddedWineManager)

            InstallationView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Install")
                }
                .tag(1)
                .environmentObject(embeddedWineManager)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
                .environmentObject(embeddedWineManager)
        }
    }
}

#Preview {
    ContentView()
}
