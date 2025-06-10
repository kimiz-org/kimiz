//
//  ContentView.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import AppKit
import Foundation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @EnvironmentObject var bottleManager: BottleManager
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
        modernTabView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernHeader: some View {
        HStack(spacing: 16) {
            // Enhanced branding section
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    // App logo with enhanced styling
                    ZStack {
                        // Background glow effect
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                            .blur(radius: 3)

                        // Logo with modern styling
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3), Color.white.opacity(0.1),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)

                    Text("kimiz")
                        .font(.system(size: 24, weight: .thin, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9), .blue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }

                Text("Windows Gaming on Mac")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.3)
            }

            Spacer()

            // Enhanced action buttons with better spacing and hierarchy
            HStack(spacing: 12) {
                // Epic Games Quick Connect Button with enhanced styling
                Button {
                    if gamePortingToolkitManager.isGPTKInstalled {
                        showingEpicConnection = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Epic Games")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: gamePortingToolkitManager.isGPTKInstalled
                                ? [Color.purple.opacity(0.9), Color.pink.opacity(0.8)]
                                : [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(
                        color: gamePortingToolkitManager.isGPTKInstalled
                            ? .purple.opacity(0.4)
                            : .clear,
                        radius: 8, x: 0, y: 3
                    )
                }
                .buttonStyle(.plain)  // Remove default button styling

                // Enhanced Quick Install Menu with better visual hierarchy
                Menu {
                    Section("Engine Management") {
                        Button {
                            selectedTab = 2  // Switch to Engine tab
                        } label: {
                            Label("Install GPTK Engine", systemImage: "gear.badge.checkmark")
                        }

                        Button {
                            selectedTab = 2  // Switch to Engine tab
                        } label: {
                            Label("Engine Performance", systemImage: "speedometer")
                        }
                    }

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
                        selectedTab = 3  // Go to Settings view
                    } label: {
                        Label("View All Options", systemImage: "arrow.right.circle")
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Install")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)  // Remove default button styling
                .menuStyle(.borderlessButton)

                // Enhanced GPTK Status indicator with better visual feedback
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                gamePortingToolkitManager.isGPTKInstalled
                                    ? .green.opacity(0.2) : .orange.opacity(0.2)
                            )
                            .frame(width: 16, height: 16)

                        Circle()
                            .fill(gamePortingToolkitManager.isGPTKInstalled ? .green : .orange)
                            .frame(width: 8, height: 8)
                            .shadow(
                                color: gamePortingToolkitManager.isGPTKInstalled
                                    ? .green.opacity(0.6) : .orange.opacity(0.6),
                                radius: 3, x: 0, y: 0)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("GPTK")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))

                        Text(gamePortingToolkitManager.isGPTKInstalled ? "Ready" : "Setup Required")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial.opacity(0.8))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Enhanced background with subtle pattern
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.2),
                        Color.purple.opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle noise texture effect - reduced opacity to prevent interference
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.2))
                    .blendMode(.overlay)
            }
        )
        .overlay(
            // Enhanced bottom border with gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.0),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1),
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
                .environmentObject(BottleManager.shared)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(
                            systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical"
                        )
                        .font(.system(size: 16, weight: .medium))
                        Text("Library")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .tag(0)

            InstallationView()
                .environmentObject(gamePortingToolkitManager)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 1 ? "plus.circle.fill" : "plus.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Install")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .tag(1)

            EngineView()
                .environmentObject(EngineManager.shared)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 2 ? "gear.badge.checkmark" : "gear.badge")
                            .font(.system(size: 16, weight: .medium))
                        Text("Engine")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .tag(2)

            SettingsView()
                .environmentObject(gamePortingToolkitManager)
                .environmentObject(epicGamesManager)
                .environmentObject(BottleManager.shared)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 3 ? "gear.circle.fill" : "gear.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Settings")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .tag(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
        .accentColor(.blue)
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

            EngineView()
                .environmentObject(EngineManager.shared)
                .tabItem {
                    Image(systemName: "gear.badge")
                    Text("Engine")
                }
                .tag(2)

            SettingsView()
                .environmentObject(gamePortingToolkitManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(GamePortingToolkitManager.shared)
        .environmentObject(EpicGamesManager.shared)
        .environmentObject(BottleManager.shared)
        .environmentObject(EngineManager.shared)
}
