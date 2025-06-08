//
//  ToolsView.swift
//  kimiz
//
//  Created temidaradev on 6.06.2025.
//

import SwiftUI

struct ToolsView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @State private var showingBottleManager = false
    @State private var showingCompatibilityTools = false
    @State private var showingEpicConnection = false
    @State private var showingInstallationWizard = false
    @State private var showingFilePicker = false
    @State private var availableBottles: [String] = []

    var body: some View {
        ZStack {
            // Modern background
            ModernBackground(style: .primary)

            ScrollView {
                VStack(spacing: 32) {
                    // Modern header
                    modernHeaderView

                    // Quick Actions Section
                    modernQuickActionsSection

                    // Installation Tools Section
                    modernInstallationSection

                    // Bottle Management Section
                    modernBottleSection

                    // System Tools Section
                    modernSystemToolsSection
                }
                .padding(28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingBottleManager) {
            BottleManagerView(
                isPresented: $showingBottleManager, availableBottles: $availableBottles
            )
            .environmentObject(gamePortingToolkitManager)
        }
        .sheet(isPresented: $showingCompatibilityTools) {
            CompatibilityToolsView(isPresented: $showingCompatibilityTools)
                .environmentObject(gamePortingToolkitManager)
        }
        .sheet(isPresented: $showingEpicConnection) {
            EpicGamesConnectionView(isPresented: $showingEpicConnection)
                .environmentObject(epicGamesManager)
        }
        .sheet(isPresented: $showingInstallationWizard) {
            InstallationWizardView(isPresented: $showingInstallationWizard)
                .environmentObject(gamePortingToolkitManager)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.exe],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onAppear {
            loadAvailableBottles()
        }
    }

    private var modernHeaderView: some View {
        ModernSectionView(title: "Gaming Tools & Utilities", icon: "wrench.and.screwdriver.fill") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Everything you need to run Windows games")
                            .font(ModernTheme.Typography.body)
                            .foregroundColor(ModernTheme.Colors.textSecondary)

                        HStack(spacing: 16) {
                            ModernStatusBadge(
                                text: gamePortingToolkitManager.isGPTKInstalled
                                    ? "GPTK Ready" : "Setup Required",
                                status: gamePortingToolkitManager.isGPTKInstalled
                                    ? .success : .warning,
                                size: .medium
                            )

                            ModernStatusBadge(
                                text: epicGamesManager.isConnected
                                    ? "Epic Connected" : "Connect Epic",
                                status: epicGamesManager.isConnected ? .success : .info,
                                size: .medium
                            )
                        }
                    }

                    Spacer()
                }

                if !gamePortingToolkitManager.isGPTKInstalled {
                    ModernAlertCard(
                        title: "Setup Required",
                        message:
                            "Install Game Porting Toolkit to access all gaming tools and features",
                        type: .warning,
                        dismissAction: nil
                    )
                }
            }
        }
    }

    private var modernQuickActionsSection: some View {
        ModernSectionView(title: "Quick Actions", icon: "bolt.fill") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 16
            ) {
                ModernActionCard(
                    title: "Install Game",
                    subtitle: "Add Windows game from file",
                    icon: "plus.app.fill",
                    accentColor: .blue
                ) {
                    showingFilePicker = true
                }

                ModernActionCard(
                    title: "Epic Games",
                    subtitle: "Connect your Epic account",
                    icon: "gamecontroller.fill",
                    accentColor: .purple
                ) {
                    showingEpicConnection = true
                }

                ModernActionCard(
                    title: "Installation Wizard",
                    subtitle: "Step-by-step game setup",
                    icon: "wand.and.stars.fill",
                    accentColor: .cyan
                ) {
                    showingInstallationWizard = true
                }
            }
        }
    }

    private var modernInstallationSection: some View {
        ModernSectionView(title: "Installation Tools", icon: "arrow.down.circle.fill") {
            VStack(spacing: 12) {
                ModernInfoPanel(
                    title: "Game Installation Wizard",
                    subtitle:
                        "Guided installation process for Windows games with automatic configuration",
                    icon: "wand.and.stars.fill",
                    accentColor: .blue
                ) {
                    showingInstallationWizard = true
                }

                ModernInfoPanel(
                    title: "Manual Game Installation",
                    subtitle: "Install a Windows executable directly from your Mac",
                    icon: "app.badge.plus",
                    accentColor: .green
                ) {
                    showingFilePicker = true
                }

                ModernInfoPanel(
                    title: "Steam Compatibility",
                    subtitle: "Configure Steam games for optimal performance",
                    icon: "cloud.fill",
                    accentColor: .orange
                ) {
                    // Handle Steam configuration
                }
            }
        }
    }

    private var modernBottleSection: some View {
        ModernSectionView(title: "Wine Bottles", icon: "server.rack") {
            VStack(spacing: 16) {
                HStack {
                    ModernStatisticsCard(
                        title: "Active Bottles",
                        value: "\(availableBottles.count)",
                        subtitle: "Wine environments",
                        icon: "server.rack",
                        accentColor: .blue
                    )

                    ModernStatisticsCard(
                        title: "Memory Usage",
                        value: "2.1 GB",
                        subtitle: "Current consumption",
                        icon: "memorychip",
                        accentColor: .green
                    )
                }

                ModernInfoPanel(
                    title: "Bottle Manager",
                    subtitle: "Create, configure, and manage Wine bottles for different games",
                    icon: "slider.horizontal.3",
                    accentColor: .purple
                ) {
                    showingBottleManager = true
                }

                ModernInfoPanel(
                    title: "Compatibility Tools",
                    subtitle: "Install and configure DXVK, VKD3D, and other compatibility layers",
                    icon: "wrench.adjustable.fill",
                    accentColor: .orange
                ) {
                    showingCompatibilityTools = true
                }
            }
        }
    }

    private var modernSystemToolsSection: some View {
        ModernSectionView(title: "System Tools", icon: "gearshape.2.fill") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 16
            ) {
                ModernSystemToolCard(
                    title: "Registry Editor",
                    description: "Edit Windows registry for installed games",
                    icon: "doc.text.fill",
                    status: gamePortingToolkitManager.isGPTKInstalled ? .available : .disabled
                ) {
                    openRegistryEditor()
                }

                ModernSystemToolCard(
                    title: "File Manager",
                    description: "Browse game files and Wine directories",
                    icon: "folder.fill",
                    status: .available
                ) {
                    openFileManager()
                }

                ModernSystemToolCard(
                    title: "Task Manager",
                    description: "Monitor Wine processes and performance",
                    icon: "list.bullet.rectangle.fill",
                    status: gamePortingToolkitManager.isGPTKInstalled ? .available : .disabled
                ) {
                    openTaskManager()
                }

                ModernSystemToolCard(
                    title: "Wine Configuration",
                    description: "Configure Wine settings and preferences",
                    icon: "gearshape.fill",
                    status: gamePortingToolkitManager.isGPTKInstalled ? .available : .disabled
                ) {
                    openWineConfiguration()
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func loadAvailableBottles() {
        availableBottles = gamePortingToolkitManager.bottles.map { $0.name }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedFile = urls.first else { return }
            // Quick add to library without wizard
            Task {
                await addGameDirectly(from: selectedFile)
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }

    private func addGameDirectly(from url: URL) async {
        let gameName = url.deletingPathExtension().lastPathComponent
        let game = Game(
            name: gameName,
            executablePath: url.path,
            installPath: url.deletingLastPathComponent().path
        )
        // Add to library manager
        await LibraryManager.shared.addUserGame(game)
    }

    // MARK: - System Tool Actions

    private func openRegistryEditor() {
        guard gamePortingToolkitManager.isGPTKInstalled else { return }
        Task {
            do {
                if let bottle = gamePortingToolkitManager.selectedBottle {
                    let winePath = [
                        "/opt/homebrew/bin/wine",
                        "/usr/local/bin/wine",
                        "/opt/homebrew/bin/wine64",
                        "/usr/local/bin/wine64",
                    ].first(where: { FileManager.default.fileExists(atPath: $0) })
                    
                    guard let winePath = winePath else { return }
                    
                    let environment = gamePortingToolkitManager.getOptimizedEnvironment(for: bottle)
                    
                    try await WineManager.shared.runWineProcess(
                        winePath: winePath,
                        executablePath: "regedit",
                        environment: environment,
                        workingDirectory: bottle.path,
                        defaultBottlePath: bottle.path
                    )
                }
            } catch {
                print("Failed to open registry editor: \(error)")
            }
        }
    }

    private func openFileManager() {
        // Open Finder to show wine bottles directory
        let bottlesPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".wine")
            .path

        NSWorkspace.shared.open(URL(fileURLWithPath: bottlesPath))
    }

    private func openTaskManager() {
        guard gamePortingToolkitManager.isGPTKInstalled else { return }
        Task {
            do {
                if let bottle = gamePortingToolkitManager.selectedBottle {
                    let winePath = [
                        "/opt/homebrew/bin/wine",
                        "/usr/local/bin/wine",
                        "/opt/homebrew/bin/wine64",
                        "/usr/local/bin/wine64",
                    ].first(where: { FileManager.default.fileExists(atPath: $0) })
                    
                    guard let winePath = winePath else { return }
                    
                    let environment = gamePortingToolkitManager.getOptimizedEnvironment(for: bottle)
                    
                    try await WineManager.shared.runWineProcess(
                        winePath: winePath,
                        executablePath: "taskmgr",
                        environment: environment,
                        workingDirectory: bottle.path,
                        defaultBottlePath: bottle.path
                    )
                }
            } catch {
                print("Failed to open task manager: \(error)")
            }
        }
    }

    private func openWineConfiguration() {
        guard gamePortingToolkitManager.isGPTKInstalled else { return }
        Task {
            do {
                if let bottle = gamePortingToolkitManager.selectedBottle {
                    let winePath = [
                        "/opt/homebrew/bin/wine",
                        "/usr/local/bin/wine",
                        "/opt/homebrew/bin/wine64",
                        "/usr/local/bin/wine64",
                    ].first(where: { FileManager.default.fileExists(atPath: $0) })
                    
                    guard let winePath = winePath else { return }
                    
                    let environment = gamePortingToolkitManager.getOptimizedEnvironment(for: bottle)
                    
                    try await WineManager.shared.runWineProcess(
                        winePath: winePath,
                        executablePath: "winecfg",
                        environment: environment,
                        workingDirectory: bottle.path,
                        defaultBottlePath: bottle.path
                    )
                }
            } catch {
                print("Failed to open wine configuration: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct ToolCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(16)
            .frame(height: 120)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CompactToolCard: View {
    let title: String
    let description: String
    let icon: String
    let isInstalled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isInstalled ? .green : .blue)

                    Spacer()

                    if isInstalled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .frame(height: 80)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct SystemIntegrationCard: View {
    let title: String
    let description: String
    let icon: String
    let action: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action) {
                onAction()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ToolsView()
        .environmentObject(GamePortingToolkitManager.shared)
        .environmentObject(EpicGamesManager.shared)
}
