//
//  SettingsView.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    @AppStorage("autoDetectGames") private var autoDetectGames = true
    @AppStorage("enableHUD") private var enableHUD = false
    @AppStorage("useEsync") private var useEsync = true
    @AppStorage("useDXVKAsync") private var useDXVKAsync = false

    var body: some View {
        ZStack {
            // Modern background
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Modern header
                    modernHeaderView

                    // GPTK Status Section
                    gptkStatusSection

                    // Game Settings Section
                    gameSettingsSection

                    // Performance Settings Section
                    performanceSettingsSection

                    // Advanced Settings Section
                    advancedSettingsSection

                    // About Section
                    aboutSection
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Configure kimiz and Game Porting Toolkit settings")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var gptkStatusSection: some View {
        ModernSectionView(title: "Game Porting Toolkit", icon: "gamecontroller") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(gamePortingToolkitManager.isGPTKInstalled ? .green : .red)
                            .frame(width: 16, height: 16)

                        if gamePortingToolkitManager.isGPTKInstalled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            gamePortingToolkitManager.isGPTKInstalled
                                ? "GPTK Installed" : "GPTK Not Installed"
                        )
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                        Text(
                            gamePortingToolkitManager.isGPTKInstalled
                                ? "Game Porting Toolkit is ready to use"
                                : "Install GPTK to run Windows games"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }

                if gamePortingToolkitManager.isInitializing {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: gamePortingToolkitManager.installationProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))

                        Text(gamePortingToolkitManager.initializationStatus)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private var gameSettingsSection: some View {
        ModernSectionView(title: "Game Settings", icon: "gamecontroller.fill") {
            VStack(spacing: 16) {
                ModernToggleRow(
                    title: "Auto-detect installed games",
                    subtitle: "Automatically scan for Windows games when launching kimiz",
                    icon: "magnifyingglass.circle.fill",
                    isOn: $autoDetectGames
                )

                ModernToggleRow(
                    title: "Show performance overlay",
                    subtitle: "Display FPS and performance metrics during gameplay",
                    icon: "speedometer",
                    isOn: $enableHUD
                )

                Button {
                    Task {
                        await gamePortingToolkitManager.scanForGames()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Scan for Installed Games")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(!gamePortingToolkitManager.isGPTKInstalled)
            }
        }
    }

    private var performanceSettingsSection: some View {
        ModernSectionView(title: "Performance", icon: "bolt.circle.fill") {
            VStack(spacing: 16) {
                ModernToggleRow(
                    title: "Enable Esync",
                    subtitle: "Improves Wine performance by using eventfd-based synchronization",
                    icon: "bolt.circle.fill",
                    isOn: $useEsync
                )

                ModernToggleRow(
                    title: "DXVK Async",
                    subtitle: "Enables asynchronous shader compilation for smoother gameplay",
                    icon: "cpu",
                    isOn: $useDXVKAsync
                )
            }
        }
    }

    private var advancedSettingsSection: some View {
        ModernSectionView(title: "Advanced", icon: "gearshape.2") {
            VStack(spacing: 16) {
                ModernToggleRow(
                    title: "Debug mode",
                    subtitle: "Enable detailed logging and debug information",
                    icon: "ladybug.fill",
                    isOn: $enableDebugMode
                )

                VStack(spacing: 12) {
                    Button {
                        reinstallGPTK()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Reinstall Game Porting Toolkit")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        resetSettings()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Reset All Settings")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.red, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var aboutSection: some View {
        ModernSectionView(title: "About", icon: "info.circle") {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("kimiz")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Version 1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }

                Button {
                    if let url = URL(string: "https://github.com/your-repo/kimiz") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("View on GitHub")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reinstallGPTK() {
        Task {
            do {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = true
                    gamePortingToolkitManager.installationProgress = 0.1
                    gamePortingToolkitManager.installationStatus = "Starting installation..."
                }

                try await gamePortingToolkitManager.installGamePortingToolkit()

                await MainActor.run {
                    gamePortingToolkitManager.installationProgress = 0.9
                    gamePortingToolkitManager.installationStatus = "Verifying installation..."
                }

                await gamePortingToolkitManager.checkGPTKInstallation()

                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    gamePortingToolkitManager.installationProgress = 1.0
                    gamePortingToolkitManager.installationStatus = "Installation complete"
                }
            } catch GamePortingToolkitManager.GPTKError.homebrewRequired {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    gamePortingToolkitManager.installationStatus =
                        "Homebrew is required. Please install Homebrew first."
                }
            } catch {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    gamePortingToolkitManager.installationStatus =
                        "Installation failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func resetSettings() {
        enableDebugMode = false
        autoDetectGames = true
        enableHUD = false
        useEsync = true
        useDXVKAsync = false
    }
}

#Preview {
    SettingsView()
        .environmentObject(GamePortingToolkitManager.shared)
}
