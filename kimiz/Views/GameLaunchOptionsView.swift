//
//  GameLaunchOptionsView.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import SwiftUI

struct GameLaunchOptionsView: View {
    let game: Game
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var launchArguments: String = ""
    @State private var enableDXVK = true
    @State private var enableEsync = true
    @State private var showHUD = false
    @State private var windowMode: WindowMode = .windowed
    @Binding var isPresented: Bool

    @AppStorage("defaultWindowMode") private var defaultWindowMode = WindowMode.windowed.rawValue
    @AppStorage("defaultDXVK") private var defaultDXVK = true
    @AppStorage("defaultEsync") private var defaultEsync = true

    enum WindowMode: String, CaseIterable, Identifiable {
        case windowed = "Windowed"
        case fullscreen = "Fullscreen"
        case borderless = "Borderless"

        var id: String { self.rawValue }
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

            VStack(spacing: 0) {
                // Modern header
                modernHeaderView

                // Content with glass morphism
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    ScrollView {
                        VStack(spacing: 24) {
                            // Game info section
                            gameInfoSection

                            // Launch arguments section
                            launchArgumentsSection

                            // Display mode section
                            displayModeSection

                            // Performance section
                            performanceSection

                            // Actions section
                            actionsSection
                        }
                        .padding(24)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 600, height: 550)
        .onAppear {
            loadSavedSettings()
        }
    }

    private var modernHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Launch Options")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Configure how \(game.name) will run")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var gameInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Game icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(game.executablePath)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()
            }
        }
    }

    private var launchArgumentsSection: some View {
        ModernSectionView(title: "Launch Arguments", icon: "terminal") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Add custom command-line arguments for advanced configuration")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                TextField("Enter launch arguments (optional)", text: $launchArguments)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.white)
            }
        }
    }

    private var displayModeSection: some View {
        ModernSectionView(title: "Display Mode", icon: "display") {
            VStack(spacing: 12) {
                Picker("Window Mode", selection: $windowMode) {
                    ForEach(WindowMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)
            }
        }
    }

    private var performanceSection: some View {
        ModernSectionView(title: "Graphics & Performance", icon: "speedometer") {
            VStack(spacing: 16) {
                ModernToggleRow(
                    title: "DXVK Translation",
                    subtitle: "DirectX to Vulkan for better performance",
                    icon: "cpu",
                    isOn: $enableDXVK
                )

                ModernToggleRow(
                    title: "Event Synchronization",
                    subtitle: "Esync for improved game compatibility",
                    icon: "arrow.triangle.2.circlepath",
                    isOn: $enableEsync
                )

                ModernToggleRow(
                    title: "Performance HUD",
                    subtitle: "Show real-time performance metrics",
                    icon: "chart.line.uptrend.xyaxis",
                    isOn: $showHUD
                )

                if let recommendation = performanceRecommendation {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))

                        Text(recommendation)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(12)
                    .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button {
                saveAsDefault()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14))
                    Text("Save as Default Settings")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                Button {
                    isPresented = false
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)

                Button {
                    launchGameWithOptions()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Launch Game")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var performanceRecommendation: String? {
        if game.name.lowercased().contains("cyberpunk") {
            return "Recommendation: DXVK and Esync recommended for Cyberpunk 2077"
        } else if game.name.lowercased().contains("witcher") {
            return "Recommendation: DXVK recommended for The Witcher series"
        }
        return nil
    }

    private func loadSavedSettings() {
        windowMode = WindowMode(rawValue: defaultWindowMode) ?? .windowed
        enableDXVK = defaultDXVK
        enableEsync = defaultEsync
    }

    private func saveAsDefault() {
        defaultWindowMode = windowMode.rawValue
        defaultDXVK = enableDXVK
        defaultEsync = enableEsync
    }

    private func launchGameWithOptions() {
        Task {
            do {
                // Close the options sheet
                isPresented = false

                // Launch the game using GPTK manager
                try await gamePortingToolkitManager.launchGame(game)
            } catch {
                print("Failed to launch game: \(error)")
            }
        }
    }
}

// MARK: - Supporting Components - Using shared ModernComponents
