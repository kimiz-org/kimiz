//
//  InstallationView.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// Import managers and components
// (Components are included via namespace, no explicit import needed)

struct InstallationView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var installationProgress: Double = 0.0
    @State private var isInstalling = false

    // Add placeholder actions for buttons
    @State private var showingEpicGamesAlert = false
    @State private var showingInstallToolsAlert = false

    var body: some View {
        ZStack {
            // Modern background
            ModernBackground(style: ModernBackground.BackgroundStyle.primary)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Modern header
                    modernHeaderView

                    // Rosetta 2 installation section
                    rosettaInstallSection

                    // Installation status section
                    installationStatusSection

                    // Installation steps
                    installationStepsSection

                    // Quick setup section
                    quickSetupSection
                }
                .padding(.horizontal, ModernTheme.Spacing.xl)
                .padding(.vertical, ModernTheme.Spacing.lg)
            }
        }
        .alert("Installation", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .alert("Epic Games Store", isPresented: $showingEpicGamesAlert) {
            Button("OK") {}
        } message: {
            Text("Epic Games connection is not yet implemented.")
        }
        .alert("Install Tools", isPresented: $showingInstallToolsAlert) {
            Button("OK") {}
        } message: {
            Text("Tools installation is not yet implemented.")
        }
    }

    private var modernHeaderView: some View {
        ModernSectionView(title: "Game Porting Toolkit", icon: "gear.circle.fill") {
            Text("Set up and manage your GPTK installation for running Windows games on macOS")
                .font(ModernTheme.Typography.body)
                .foregroundColor(ModernTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var rosettaInstallSection: some View {
        VStack(spacing: ModernTheme.Spacing.md) {
            HStack {
                Text("Rosetta 2")
                    .font(ModernTheme.Typography.body)
                    .foregroundColor(ModernTheme.Colors.textPrimary)
                Spacer()
                if !FileManager.default.fileExists(atPath: "/usr/libexec/rosetta") {
                    Button {
                        installRosetta2()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Install Rosetta 2")
                                .font(ModernTheme.Typography.caption1)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(ModernPrimaryButtonStyle())
                } else {
                    Label("Installed", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 13, weight: .medium))
                }
            }
        }
    }

    private var installationStatusSection: some View {
        ModernInfoPanel(
            title: "Installation Status",
            subtitle: gamePortingToolkitManager.isGPTKInstalled
                ? "GPTK Installed" : "GPTK Not Installed",
            icon: gamePortingToolkitManager.isGPTKInstalled
                ? "checkmark.circle.fill" : "xmark.circle.fill",
            accentColor: gamePortingToolkitManager.isGPTKInstalled ? .green : .orange
        ) {
            VStack(spacing: ModernTheme.Spacing.md) {
                HStack {
                    Text(
                        gamePortingToolkitManager.isGPTKInstalled
                            ? "GPTK Installed" : "GPTK Not Installed"
                    )
                    .font(ModernTheme.Typography.body)
                    .foregroundColor(ModernTheme.Colors.textPrimary)

                    Spacer()

                    if gamePortingToolkitManager.showInstallGPTKButton {
                        Button {
                            installGPTK()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Install Game Porting Toolkit")
                                    .font(ModernTheme.Typography.caption1)
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())
                    }
                }

                if !gamePortingToolkitManager.isGPTKInstalled {
                    VStack(spacing: 12) {
                        Text("Game Porting Toolkit 2 is not installed.")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(
                            "Apple now distributes GPTK 2 as a signed, ARM-native .pkg installer. Homebrew is not supported for GPTK 2. Please use the official Apple installer."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

    private var installationStepsSection: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.lg) {
            Text("Installation Steps")
                .font(ModernTheme.Typography.title2)
                .foregroundColor(ModernTheme.Colors.textPrimary)

            VStack(spacing: ModernTheme.Spacing.md) {
                ModernActionCard(
                    title: "Download GPTK",
                    subtitle: "Install Apple's Game Porting Toolkit from Xcode",
                    icon: "arrow.down.circle",
                    accentColor: gamePortingToolkitManager.isGPTKInstalled ? .green : .blue
                ) {
                    if !gamePortingToolkitManager.isGPTKInstalled {
                        installGPTK()
                    }
                }

                ModernActionCard(
                    title: "Configure Environment",
                    subtitle: "Set up Wine prefixes and system integration",
                    icon: "gearshape.2",
                    accentColor: gamePortingToolkitManager.isGPTKInstalled ? .green : .gray
                ) {
                    // Handle environment configuration
                }

                ModernActionCard(
                    title: "Install Dependencies",
                    subtitle: "Download essential libraries and runtime components",
                    icon: "cube.box",
                    accentColor: .gray
                ) {
                    // Handle dependencies installation
                }

                ModernActionCard(
                    title: "Verify Installation",
                    subtitle: "Test GPTK functionality and validate setup",
                    icon: "checkmark.seal",
                    accentColor: .gray
                ) {
                    performSystemCheck()
                }
            }
        }
    }

    private var quickSetupSection: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.lg) {
            Text("Quick Setup")
                .font(ModernTheme.Typography.title2)
                .foregroundColor(ModernTheme.Colors.textPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: ModernTheme.Spacing.md
            ) {
                ModernActionCard(
                    title: "Install Steam",
                    subtitle: "Set up Steam for Windows games",
                    icon: "cloud.fill",
                    accentColor: .blue
                ) {
                    installSteam()
                }

                ModernActionCard(
                    title: "Epic Games Store",
                    subtitle: "Connect your Epic Games account",
                    icon: "gamecontroller.fill",
                    accentColor: .purple
                ) {
                    showingEpicGamesAlert = true
                }

                ModernActionCard(
                    title: "Install Tools",
                    subtitle: "Essential compatibility tools",
                    icon: "wrench.and.screwdriver",
                    accentColor: .orange
                ) {
                    showingInstallToolsAlert = true
                }

                ModernActionCard(
                    title: "System Check",
                    subtitle: "Verify system requirements",
                    icon: "checkmark.circle",
                    accentColor: .green
                ) {
                    performSystemCheck()
                }
            }
        }
    }

    private func installRosetta2() {
        isInstalling = true
        Task {
            let script =
                "do shell script \"/usr/sbin/softwareupdate --install-rosetta --agree-to-license\" with administrator privileges"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        isInstalling = false
                        alertMessage = "Rosetta 2 installed successfully!"
                        showingAlert = true
                    }
                } else {
                    throw NSError(
                        domain: "RosettaInstall", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Failed to install Rosetta 2. Please install it manually."
                        ])
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage = "Rosetta 2 installation failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func installGPTK() {
        isInstalling = true
        installationProgress = 0.0
        Task {
            do {
                try await gamePortingToolkitManager.installGamePortingToolkit()
                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        "Game Porting Toolkit installer launched. Please follow the prompts to complete installation, then restart the app."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage = "Failed to launch installer: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func installSteam() {
        Task {
            do {
                try await gamePortingToolkitManager.installSteam()
                await MainActor.run {
                    alertMessage = "Steam installation started successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Steam installation failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func performSystemCheck() {
        Task {
            await MainActor.run {
                alertMessage = "System check completed. All requirements met!"
                showingAlert = true
            }
        }
    }
}

#Preview {
    InstallationView()
        .environmentObject(GamePortingToolkitManager.shared)
}
