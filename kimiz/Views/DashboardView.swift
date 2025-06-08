//
//  DashboardView.swift
//  kimiz
//
//  Created by temidaradev on 7.06.2025.
//

import SwiftUI
import Foundation

struct DashboardView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @StateObject private var libraryManager = LibraryManager.shared

    @State private var recentGames: [Game] = []
    @State private var systemStats = SystemStats()
    @State private var showingAllGames = false

    struct SystemStats {
        var cpuUsage: Double = 0.0
        var memoryUsage: Double = 0.0
        var activeProcesses: Int = 0
        var wineBottles: Int = 0
    }

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.1, blue: 0.2),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Welcome Section
                    welcomeSection

                    // Quick Stats
                    quickStatsSection

                    // System Status
                    systemStatusSection

                    // Recent Games
                    recentGamesSection

                    // Quick Actions
                    quickActionsSection
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .onAppear {
            loadDashboardData()
        }
    }

    private var welcomeSection: some View {
        ModernSectionView(title: "Welcome Back", icon: "house.fill") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready to game")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Your gaming environment is set up and ready to go")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }

                if !gamePortingToolkitManager.isGPTKInstalled {
                    ModernAlertCard(
                        title: "Setup Required",
                        message: "Game Porting Toolkit needs to be installed to run Windows games",
                        type: .warning,
                        dismissAction: nil
                    )
                }
            }
        }
    }

    private var quickStatsSection: some View {
        ModernSectionView(title: "At a Glance", icon: "chart.bar.fill") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 16
            ) {
                ModernStatisticsCard(
                    title: "Games",
                    value: "\(libraryManager.discoveredGames.count)",
                    icon: "gamecontroller.fill",
                    accentColor: .blue
                )

                ModernStatisticsCard(
                    title: "CPU Usage",
                    value: "\(Int(systemStats.cpuUsage))%",
                    icon: "cpu",
                    trend: systemStats.cpuUsage > 80
                        ? .up : systemStats.cpuUsage < 30 ? .down : .neutral,
                    accentColor: .green
                )

                ModernStatisticsCard(
                    title: "Memory",
                    value: "\(Int(systemStats.memoryUsage))%",
                    icon: "memorychip",
                    trend: systemStats.memoryUsage > 80
                        ? .up : systemStats.memoryUsage < 50 ? .down : .neutral,
                    accentColor: .orange
                )

                ModernStatisticsCard(
                    title: "Wine Processes",
                    value: "\(systemStats.activeProcesses)",
                    icon: "gearshape.2.fill",
                    accentColor: .purple
                )
            }
        }
    }

    private var systemStatusSection: some View {
        ModernSectionView(title: "System Status", icon: "info.circle.fill") {
            VStack(spacing: 12) {
                ModernInfoPanel(
                    title: gamePortingToolkitManager.isGPTKInstalled
                        ? "GPTK Ready" : "GPTK Not Installed",
                    subtitle: gamePortingToolkitManager.isGPTKInstalled
                        ? "Game Porting Toolkit is installed and ready"
                        : "Install GPTK to run Windows games",
                    icon: gamePortingToolkitManager.isGPTKInstalled
                        ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    accentColor: gamePortingToolkitManager.isGPTKInstalled ? .green : .orange,
                    action: gamePortingToolkitManager.isGPTKInstalled
                        ? nil
                        : {
                            // Trigger GPTK installation
                        }
                )

                ModernInfoPanel(
                    title: epicGamesManager.isConnected
                        ? "Epic Games Connected" : "Epic Games Available",
                    subtitle: epicGamesManager.isConnected
                        ? "Connected and ready to sync games"
                        : "Connect to access your Epic Games library",
                    icon: "gamecontroller.fill",
                    accentColor: epicGamesManager.isConnected ? .green : .blue,
                    action: epicGamesManager.isConnected
                        ? nil
                        : {
                            // Show Epic Games connection
                        }
                )

                ModernInfoPanel(
                    title: "Performance Mode",
                    subtitle: "Optimized settings for best gaming experience",
                    icon: "bolt.circle.fill",
                    accentColor: .yellow,
                    action: {
                        // Show performance settings
                    }
                )
            }
        }
    }

    private var recentGamesSection: some View {
        ModernSectionView(title: "Recent Games", icon: "clock.fill") {
            VStack(spacing: 16) {
                if recentGames.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white.opacity(0.3))

                        Text("No recent games")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        Text("Your recently played games will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ],
                        spacing: 16
                    ) {
                        ForEach(recentGames.prefix(6)) { game in
                            ModernGameCard(
                                game: game,
                                isHovered: false,
                                onLaunch: {
                                    // Launch game action
                                },
                                onDelete: { },
                                onHover: { _ in }
                            )
                        }
                    }

                    if recentGames.count > 6 {
                        Button {
                            showingAllGames = true
                        } label: {
                            Text("View All Games")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(ModernSecondaryButtonStyle())
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        ModernSectionView(title: "Quick Actions", icon: "bolt.fill") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 16
            ) {
                QuickActionCard(
                    title: "Install Game",
                    icon: "plus.circle.fill",
                    accentColor: .blue
                ) {
                    // Show install dialog
                }

                QuickActionCard(
                    title: "Performance",
                    icon: "speedometer",
                    accentColor: .green
                ) {
                    // Show performance view
                }

                QuickActionCard(
                    title: "Settings",
                    icon: "gearshape.fill",
                    accentColor: .gray
                ) {
                    // Show settings
                }

                QuickActionCard(
                    title: "Wine Config",
                    icon: "wrench.fill",
                    accentColor: .orange
                ) {
                    // Show wine configuration
                }

                QuickActionCard(
                    title: "Epic Games",
                    icon: "gamecontroller.fill",
                    accentColor: .purple
                ) {
                    // Show Epic Games view
                }

                QuickActionCard(
                    title: "Scan Games",
                    icon: "magnifyingglass.circle.fill",
                    accentColor: .cyan
                ) {
                    // Scan for games
                }
            }
        }
    }

    private func loadDashboardData() {
        // Load recent games
        recentGames = Array(libraryManager.discoveredGames.prefix(6))

        // Simulate system stats (in a real app, you'd get actual system info)
        systemStats = SystemStats(
            cpuUsage: Double.random(in: 15...45),
            memoryUsage: Double.random(in: 40...70),
            activeProcesses: Int.random(in: 0...3),
            wineBottles: Int.random(in: 1...5)
        )
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(accentColor)
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environmentObject(GamePortingToolkitManager.shared)
        .environmentObject(EpicGamesManager.shared)
}
