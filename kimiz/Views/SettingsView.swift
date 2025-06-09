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
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @EnvironmentObject var bottleManager: BottleManager
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    @AppStorage("autoDetectGames") private var autoDetectGames = true
    @AppStorage("enableHUD") private var enableHUD = false
    @AppStorage("useEsync") private var useEsync = true
    @AppStorage("useDXVKAsync") private var useDXVKAsync = false

    // Tools-related state
    @State private var showingBottleManager = false
    @State private var showingCompatibilityTools = false
    @State private var showingEpicConnection = false
    @State private var showingInstallationWizard = false
    @State private var showingFilePicker = false
    @State private var availableBottles: [String] = []
    @State private var showingEpicGamesAlert = false
    @State private var showingInstallToolsAlert = false

    var body: some View {
        ZStack {
            // Modern background with multiple layers
            ZStack {
                // Base gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.1, blue: 0.2),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Accent gradient overlay
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.08),
                        Color.purple.opacity(0.06),
                        Color.cyan.opacity(0.04),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle noise texture effect
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.15))
                    .blendMode(.overlay)
            }
            .ignoresSafeArea()

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

                    // Game Settings Section
                    gameSettingsSection

                    // Performance Settings Section
                    performanceSettingsSection

                    // Advanced Settings Section
                    advancedSettingsSection

                    // About Section
                    aboutSection
                }
                .padding(28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingBottleManager) {
            BottleManagerView(
                isPresented: $showingBottleManager, availableBottles: $availableBottles
            )
            .environmentObject(bottleManager)
        }
        .sheet(isPresented: $showingCompatibilityTools) {
            CompatibilityToolsView(isPresented: $showingCompatibilityTools)
                .environmentObject(gamePortingToolkitManager)
                .environmentObject(bottleManager)
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
        ModernSectionView(title: "Settings & Gaming Tools", icon: "wrench.and.screwdriver.fill") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configure kimiz settings and access gaming tools")
                            .font(.body)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            Text(
                                gamePortingToolkitManager.isGPTKInstalled
                                    ? "GPTK Ready" : "Setup Required"
                            )
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                gamePortingToolkitManager.isGPTKInstalled
                                    ? .green.opacity(0.2) : .orange.opacity(0.2)
                            )
                            .foregroundColor(
                                gamePortingToolkitManager.isGPTKInstalled ? .green : .orange
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text(epicGamesManager.isConnected ? "Epic Connected" : "Connect Epic")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    epicGamesManager.isConnected
                                        ? .green.opacity(0.2) : .blue.opacity(0.2)
                                )
                                .foregroundColor(epicGamesManager.isConnected ? .green : .blue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Spacer()
                }

                if !gamePortingToolkitManager.isGPTKInstalled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            Text("Setup Required")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Text("Install Game Porting Toolkit to access all gaming tools and features")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
                ToolActionCard(
                    title: "Install Game",
                    subtitle: "Add Windows game from file",
                    icon: "plus.app.fill",
                    accentColor: .blue
                ) {
                    showingFilePicker = true
                }

                ToolActionCard(
                    title: "Epic Games",
                    subtitle: "Connect your Epic account",
                    icon: "gamecontroller.fill",
                    accentColor: .purple
                ) {
                    showingEpicConnection = true
                }

                ToolActionCard(
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
                ToolInfoPanel(
                    title: "Game Installation Wizard",
                    subtitle:
                        "Guided installation process for Windows games with automatic configuration",
                    icon: "wand.and.stars.fill",
                    accentColor: .blue
                ) {
                    showingInstallationWizard = true
                }

                ToolInfoPanel(
                    title: "Manual Game Installation",
                    subtitle: "Install a Windows executable directly from your Mac",
                    icon: "app.badge.plus",
                    accentColor: .green
                ) {
                    showingFilePicker = true
                }

                ToolInfoPanel(
                    title: "Steam Compatibility",
                    subtitle: "Configure Steam games for optimal performance",
                    icon: "cloud.fill",
                    accentColor: .orange
                ) {
                    showingInstallToolsAlert = true
                }
            }
        }
    }

    private var modernBottleSection: some View {
        ModernSectionView(title: "Wine Bottles", icon: "server.rack") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Bottles")
                            .font(.headline)
                        Text("\(availableBottles.count)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Wine environments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory Usage")
                            .font(.headline)
                        Text("2.1 GB")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Current consumption")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                ToolInfoPanel(
                    title: "Bottle Manager",
                    subtitle: "Create, configure, and manage Wine bottles for different games",
                    icon: "slider.horizontal.3",
                    accentColor: .purple
                ) {
                    showingBottleManager = true
                }

                ToolInfoPanel(
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
                SystemToolCard(
                    title: "Registry Editor",
                    description: "Edit Windows registry for installed games",
                    icon: "doc.text.fill",
                    isEnabled: gamePortingToolkitManager.isGPTKInstalled
                ) {
                    openRegistryEditor()
                }

                SystemToolCard(
                    title: "File Manager",
                    description: "Browse game files and Wine directories",
                    icon: "folder.fill",
                    isEnabled: true
                ) {
                    openFileManager()
                }

                SystemToolCard(
                    title: "Task Manager",
                    description: "Monitor Wine processes and performance",
                    icon: "list.bullet.rectangle.fill",
                    isEnabled: gamePortingToolkitManager.isGPTKInstalled
                ) {
                    openTaskManager()
                }

                SystemToolCard(
                    title: "Wine Configuration",
                    description: "Configure Wine settings and preferences",
                    icon: "gearshape.fill",
                    isEnabled: gamePortingToolkitManager.isGPTKInstalled
                ) {
                    openWineConfiguration()
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

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Performance Tips")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Enable Esync for better CPU utilization")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("• DXVK Async can reduce stuttering but may cause graphical issues")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                        Text("Version 1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
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

    // MARK: - Helper Functions

    private func loadAvailableBottles() {
        availableBottles = bottleManager.bottles.map { $0.name }
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
                if let bottle = bottleManager.selectedBottle {
                    let winePath = [
                        "/opt/homebrew/bin/wine",
                        "/usr/local/bin/wine",
                        "/opt/homebrew/bin/wine64",
                        "/usr/local/bin/wine64",
                    ].first(where: { FileManager.default.fileExists(atPath: $0) })

                    guard let winePath = winePath else { return }

                    let environment = bottleManager.getOptimizedEnvironment(for: bottle)

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
                if let bottle = bottleManager.selectedBottle {
                    let winePath = [
                        "/opt/homebrew/bin/wine",
                        "/usr/local/bin/wine",
                        "/opt/homebrew/bin/wine64",
                        "/usr/local/bin/wine64",
                    ].first(where: { FileManager.default.fileExists(atPath: $0) })

                    guard let winePath = winePath else { return }

                    let environment = bottleManager.getOptimizedEnvironment(for: bottle)

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
                if let bottle = bottleManager.selectedBottle {
                    let winePath = [
                        "/opt/homebrew/bin/wine",
                        "/usr/local/bin/wine",
                        "/opt/homebrew/bin/wine64",
                        "/usr/local/bin/wine64",
                    ].first(where: { FileManager.default.fileExists(atPath: $0) })

                    guard let winePath = winePath else { return }

                    let environment = bottleManager.getOptimizedEnvironment(for: bottle)

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
            } catch GPTKError.homebrewRequired {
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

// MARK: - Supporting Views

struct ToolActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(accentColor)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
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
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ToolInfoPanel: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SystemToolCard: View {
    let title: String
    let description: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isEnabled ? .blue : .secondary)

                    Spacer()

                    if isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isEnabled ? .primary : .secondary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(16)
            .frame(height: 120)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEnabled ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.2),
                        lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GamePortingToolkitManager.shared)
        .environmentObject(EpicGamesManager.shared)
        .environmentObject(BottleManager.shared)
}
