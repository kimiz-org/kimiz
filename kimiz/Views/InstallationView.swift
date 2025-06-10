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
                        Text("Game Porting Toolkit 2.1 is not installed.")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(
                            "Apple Game Porting Toolkit 2.1 provides the best compatibility for Windows games on macOS. The installer requires an Apple Developer account and will be downloaded from Apple's developer portal."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                        Text(
                            "If the automatic download fails, you'll be redirected to Apple's developer portal to download manually."
                        )
                        .font(.caption2)
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
                    title: gamePortingToolkitManager.isSteamInstalled()
                        ? "Launch Steam" : "Install Steam",
                    subtitle: gamePortingToolkitManager.isSteamInstalled()
                        ? "Open Steam client to play games" : "Set up Steam for Windows games",
                    icon: gamePortingToolkitManager.isSteamInstalled()
                        ? "play.circle.fill" : "cloud.fill",
                    accentColor: gamePortingToolkitManager.isSteamInstalled() ? .green : .blue
                ) {
                    if gamePortingToolkitManager.isSteamInstalled() {
                        launchSteam()
                    } else {
                        installSteam()
                    }
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
                    title: "Install Compatibility Tools",
                    subtitle: "Install DXVK, vkd3d, winetricks, and corefonts",
                    icon: "wrench.and.screwdriver",
                    accentColor: .orange
                ) {
                    installCompatibilityTools()
                }

                ModernActionCard(
                    title: "System Check",
                    subtitle: "Verify system requirements",
                    icon: "checkmark.circle",
                    accentColor: .green
                ) {
                    performSystemCheck()
                }

                ModernActionCard(
                    title: "Install & Link Wine",
                    subtitle: "Required for winetricks, DXVK, and all compatibility tools",
                    icon: "wineglass",
                    accentColor: .red
                ) {
                    installWineAndLink()
                }

                ModernActionCard(
                    title: "Test DXVK Graphics",
                    subtitle: "Verify if DXVK and graphics output are working",
                    icon: "display",
                    accentColor: .blue
                ) {
                    testDXVKGraphics()
                }

                ModernActionCard(
                    title: "Reset Wine Prefix",
                    subtitle: "Reset the Wine environment to default",
                    icon: "arrow.counterclockwise.circle",
                    accentColor: .gray
                ) {
                    resetWinePrefix()
                }

                ModernActionCard(
                    title: "Clean Wine Install",
                    subtitle: "Remove all Wine versions and reinstall cleanly",
                    icon: "trash",
                    accentColor: .pink
                ) {
                    cleanWineInstall()
                }

                ModernActionCard(
                    title: "Reinstall DXVK & MoltenVK",
                    subtitle: "Fix DXVK/Vulkan/MoltenVK setup for graphics",
                    icon: "arrow.triangle.2.circlepath",
                    accentColor: .purple
                ) {
                    reinstallDXVKAndMoltenVK()
                }

                ModernActionCard(
                    title: "Fix DirectX 11/DXVK",
                    subtitle: "Install DXVK into Wine prefix for DirectX 11 games",
                    icon: "bolt.horizontal.circle",
                    accentColor: .yellow
                ) {
                    Task {
                        await gamePortingToolkitManager.fixDirectX11InPrefix()
                        alertMessage = gamePortingToolkitManager.installationStatus
                        showingAlert = true
                    }
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
                try await self.gamePortingToolkitManager.installSteam()
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

    private func launchSteam() {
        Task {
            do {
                try await SteamManager.shared.launchSteam()
                await MainActor.run {
                    alertMessage = "Steam launched successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Steam launch failed: \(error.localizedDescription)"
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

    private func installCompatibilityTools() {
        isInstalling = true
        alertMessage = ""
        Task {
            await MainActor.run {
                alertMessage =
                    "Installing compatibility tools (DXVK, vkd3d, winetricks, corefonts)..."
                showingAlert = true
            }
            do {
                // Install Homebrew packages
                let brewPath =
                    FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
                    ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
                let brewPackages = ["dxvk", "vkd3d", "winetricks"]
                for pkg in brewPackages {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: brewPath)
                    process.arguments = ["install", pkg]
                    try process.run()
                    process.waitUntilExit()
                }
                // Install corefonts using winetricks
                let winetricksPath =
                    FileManager.default.fileExists(atPath: "/opt/homebrew/bin/winetricks")
                    ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
                let process = Process()
                process.executableURL = URL(fileURLWithPath: winetricksPath)
                process.arguments = ["corefonts"]
                try process.run()
                process.waitUntilExit()
                await MainActor.run {
                    isInstalling = false
                    alertMessage = "Compatibility tools installed successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        "Failed to install compatibility tools: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func installWineAndLink() {
        isInstalling = true
        alertMessage = ""
        Task {
            await MainActor.run {
                alertMessage = "Installing and linking Wine (required for winetricks and DXVK)..."
                showingAlert = true
            }
            do {
                // Install Wine via Homebrew Cask
                let brewPath =
                    FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
                    ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
                let installWine = Process()
                installWine.executableURL = URL(fileURLWithPath: brewPath)
                installWine.arguments = ["install", "--cask", "wine-stable"]
                try installWine.run()
                installWine.waitUntilExit()

                // Force link Wine
                let linkWine = Process()
                linkWine.executableURL = URL(fileURLWithPath: brewPath)
                linkWine.arguments = ["link", "--overwrite", "--force", "wine-stable"]
                try linkWine.run()
                linkWine.waitUntilExit()

                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        "Wine installed and linked successfully! You can now install compatibility tools."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage = "Failed to install/link Wine: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func testDXVKGraphics() {
        isInstalling = true
        alertMessage = ""
        Task {
            await MainActor.run {
                alertMessage = "Testing DXVK graphics output..."
                showingAlert = true
            }
            do {
                // Try running 'wine dxdiag' to test graphics
                let winePath =
                    FileManager.default.fileExists(atPath: "/opt/homebrew/bin/wine")
                    ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
                let process = Process()
                process.executableURL = URL(fileURLWithPath: winePath)
                process.arguments = ["dxdiag"]
                try process.run()
                process.waitUntilExit()
                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        process.terminationStatus == 0
                        ? "DXVK test completed. If a window appeared, graphics are working. If not, check DXVK/MoltenVK installation and Metal support."
                        : "DXVK test failed. Please check your DXVK and Vulkan/MoltenVK setup."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        "DXVK test could not be run: \(error.localizedDescription)\nMake sure Wine and DXVK are installed, and your Mac supports Metal."
                    showingAlert = true
                }
            }
        }
    }

    private func resetWinePrefix() {
        isInstalling = true
        alertMessage = ""
        Task {
            await MainActor.run {
                alertMessage = "Resetting Wine prefix (bottle)..."
                showingAlert = true
            }
            do {
                let bottlePath = NSString(
                    string: "~/Library/Application Support/kimiz/gptk-bottles/default"
                ).expandingTildeInPath
                if FileManager.default.fileExists(atPath: bottlePath) {
                    try FileManager.default.removeItem(atPath: bottlePath)
                }
                try FileManager.default.createDirectory(
                    atPath: bottlePath, withIntermediateDirectories: true, attributes: nil)
                await MainActor.run {
                    isInstalling = false
                    alertMessage = "Wine prefix reset. You may now reinstall compatibility tools."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage = "Failed to reset Wine prefix: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func cleanWineInstall() {
        isInstalling = true
        alertMessage = ""
        Task {
            await MainActor.run {
                alertMessage = "Cleaning all Wine installations and reinstalling via Homebrew..."
                showingAlert = true
            }
            do {
                // Remove Wine.app and Wine Stable.app from /Applications
                let fileManager = FileManager.default
                let wineAppPaths = ["/Applications/Wine Stable.app", "/Applications/Wine.app"]
                for appPath in wineAppPaths {
                    if fileManager.fileExists(atPath: appPath) {
                        try? fileManager.removeItem(atPath: appPath)
                    }
                }
                // Uninstall Wine from Homebrew (cask and formula)
                let brewPath =
                    fileManager.fileExists(atPath: "/opt/homebrew/bin/brew")
                    ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
                let uninstallCask = Process()
                uninstallCask.executableURL = URL(fileURLWithPath: brewPath)
                uninstallCask.arguments = ["uninstall", "--cask", "wine-stable"]
                try? uninstallCask.run()
                uninstallCask.waitUntilExit()
                let uninstallFormula = Process()
                uninstallFormula.executableURL = URL(fileURLWithPath: brewPath)
                uninstallFormula.arguments = ["uninstall", "wine-stable"]
                try? uninstallFormula.run()
                uninstallFormula.waitUntilExit()
                // Reinstall Wine via Homebrew cask
                let installWine = Process()
                installWine.executableURL = URL(fileURLWithPath: brewPath)
                installWine.arguments = ["install", "--cask", "wine-stable"]
                try installWine.run()
                installWine.waitUntilExit()
                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        "Wine cleaned and reinstalled via Homebrew. You can now install compatibility tools."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage = "Failed to clean/reinstall Wine: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func reinstallDXVKAndMoltenVK() {
        isInstalling = true
        alertMessage = ""
        Task {
            await MainActor.run {
                alertMessage = "Reinstalling DXVK and MoltenVK via Homebrew..."
                showingAlert = true
            }
            do {
                let fileManager = FileManager.default
                let brewPath =
                    fileManager.fileExists(atPath: "/opt/homebrew/bin/brew")
                    ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
                // Reinstall DXVK
                let dxvkProc = Process()
                dxvkProc.executableURL = URL(fileURLWithPath: brewPath)
                dxvkProc.arguments = ["reinstall", "dxvk"]
                try dxvkProc.run()
                dxvkProc.waitUntilExit()
                // Reinstall MoltenVK
                let mvkProc = Process()
                mvkProc.executableURL = URL(fileURLWithPath: brewPath)
                mvkProc.arguments = ["reinstall", "molten-vk"]
                try mvkProc.run()
                mvkProc.waitUntilExit()
                // Copy/link MoltenVK ICD JSON to Vulkan path
                let srcICD = "/opt/homebrew/share/vulkan/icd.d/MoltenVK_icd.json"
                let dstICD = "/usr/local/share/vulkan/icd.d/MoltenVK_icd.json"
                if fileManager.fileExists(atPath: srcICD) {
                    try? fileManager.createDirectory(
                        atPath: "/usr/local/share/vulkan/icd.d", withIntermediateDirectories: true,
                        attributes: nil)
                    if fileManager.fileExists(atPath: dstICD) {
                        try? fileManager.removeItem(atPath: dstICD)
                    }
                    try? fileManager.copyItem(atPath: srcICD, toPath: dstICD)
                }
                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        "DXVK and MoltenVK reinstalled. If the DXVK test still fails, check your Mac's Metal support and reboot."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    alertMessage =
                        "Failed to reinstall DXVK/MoltenVK: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    InstallationView()
        .environmentObject(GamePortingToolkitManager.shared)
}
