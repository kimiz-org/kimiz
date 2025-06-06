//
//  ContentView.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import AppKit
import Foundation
import SwiftUI

// Explicitly import the managers and views if needed
// If these types are in subfolders but the same target, no import is needed
// If using a module, use: import kimiz

struct ContentView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var showingInstallMenu = false
    @State private var showingEpicConnection = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                modernMainInterface
            } else {
                OnboardingView(showOnboarding: $showOnboarding)
                    .environmentObject(gamePortingToolkitManager)
                    .environmentObject(epicGamesManager)
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

    private var modernMainInterface: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.12, blue: 0.16),
                    Color(red: 0.16, green: 0.12, blue: 0.20),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Main content with glassmorphism effect
            VStack(spacing: 0) {
                // Custom header with app branding
                modernHeader

                // Tab content with modern styling
                modernTabView
            }
        }
    }

    private var modernHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("kimiz")
                    .font(.system(size: 28, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Windows Gaming on Mac")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Modern Install Menu in Header
            HStack(spacing: 12) {
                // Epic Games Quick Connect Button
                Button {
                    showingEpicConnection = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("Epic")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.borderless)
                .disabled(!gamePortingToolkitManager.isGPTKInstalled)

                // Quick Install Menu
                Menu {
                    Section("Quick Install") {
                        Button {
                            selectedTab = 1  // Switch to Install tab
                        } label: {
                            Label("Steam Client", systemImage: "cloud.fill")
                        }

                        Button {
                            showingEpicConnection = true
                        } label: {
                            Label("Epic Games Store", systemImage: "gamecontroller.fill")
                        }

                        Button {
                            showingInstallMenu = true
                        } label: {
                            Label("Windows Executable", systemImage: "app.badge")
                        }
                    }

                    Divider()

                    Button {
                        selectedTab = 1  // Go to full install view
                    } label: {
                        Label("View All Options", systemImage: "arrow.right.circle")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                        Text("Install")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.borderless)
                .menuStyle(.borderlessButton)

                // GPTK Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(gamePortingToolkitManager.isGPTKInstalled ? .green : .orange)
                        .frame(width: 8, height: 8)

                    Text(
                        gamePortingToolkitManager.isGPTKInstalled
                            ? "GPTK Ready" : "GPTK Setup Required"
                    )
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(0.3))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.1)),
            alignment: .bottom
        )
        .sheet(isPresented: $showingEpicConnection) {
            EpicGamesConnectionView(isPresented: $showingEpicConnection)
                .environmentObject(epicGamesManager)
        }
    }

    private var modernTabView: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .environmentObject(gamePortingToolkitManager)
                .environmentObject(epicGamesManager)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
                    Text("Library")
                }
                .tag(0)

            InstallationView()
                .environmentObject(gamePortingToolkitManager)
                .environmentObject(epicGamesManager)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "plus.circle.fill" : "plus.circle")
                    Text("Install")
                }
                .tag(1)

            SettingsView()
                .environmentObject(gamePortingToolkitManager)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "gear.circle.fill" : "gear.circle")
                    Text("Settings")
                }
                .tag(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
    }

    // Keep original mainInterface for fallback
    private var mainInterface: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .environmentObject(gamePortingToolkitManager)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Library")
                }
                .tag(0)

            InstallationView()
                .environmentObject(gamePortingToolkitManager)
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Install")
                }
                .tag(1)

            SettingsView()
                .environmentObject(gamePortingToolkitManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(GamePortingToolkitManager.shared)
        .environmentObject(EpicGamesManager.shared)
}
