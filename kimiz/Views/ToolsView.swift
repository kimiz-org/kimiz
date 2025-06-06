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
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView

                // Quick Actions Section
                quickActionsSection

                // Bottle Management Section
                bottleManagementSection

                // Gaming Tools Section
                gamingToolsSection

                // System Integration Section
                systemIntegrationSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
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

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gaming Tools & Utilities")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Manage GPTK environments, compatibility tools, and gaming utilities")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // GPTK Status indicator
                HStack(spacing: 12) {
                    Circle()
                        .fill(gamePortingToolkitManager.isGPTKInstalled ? .green : .orange)
                        .frame(width: 12, height: 12)

                    Text(
                        gamePortingToolkitManager.isGPTKInstalled ? "GPTK Ready" : "GPTK Not Ready"
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(Capsule())
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                // Add Game Card
                ToolCard(
                    title: "Add Windows Game",
                    description: "Install a Windows executable with guided GPTK setup",
                    icon: "plus.app",
                    color: .blue
                ) {
                    showingInstallationWizard = true
                }

                // Add from File Card
                ToolCard(
                    title: "Quick Add Game",
                    description: "Add an executable directly to your library",
                    icon: "doc.badge.plus",
                    color: .green
                ) {
                    showingFilePicker = true
                }

                // Epic Games Connection Card
                ToolCard(
                    title: "Connect Epic Games",
                    description: "Link your Epic Games account and library",
                    icon: "link.circle",
                    color: .purple
                ) {
                    showingEpicConnection = true
                }

                // Install Steam Card
                ToolCard(
                    title: "Install Steam",
                    description: "Set up Steam client for Windows games",
                    icon: "cloud",
                    color: .cyan
                ) {
                    installSteam()
                }
            }
        }
    }

    private var bottleManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("GPTK Bottle Management")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Manage All Bottles") {
                    showingBottleManager = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GPTK Bottles")
                            .font(.headline)
                        Text("Isolated environments for different applications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(gamePortingToolkitManager.bottles.count) bottles")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    Button {
                        createQuickBottle("Gaming")
                    } label: {
                        Label("Create GPTK Gaming Bottle", systemImage: "gamecontroller")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        createQuickBottle("Office")
                    } label: {
                        Label("Create GPTK Office Bottle", systemImage: "doc.text")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()
                }
            }
        }
    }

    private var gamingToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Gaming Enhancement Tools for GPTK")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("View All Tools") {
                    showingCompatibilityTools = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                // DXVK Tool
                CompactToolCard(
                    title: "DXVK for GPTK",
                    description: "DirectX to Vulkan translation",
                    icon: "cpu",
                    isInstalled: true
                ) {
                    installDXVK()
                }

                // VCRedist Tool
                CompactToolCard(
                    title: "Visual C++ Runtime",
                    description: "Microsoft Visual C++ libraries",
                    icon: "gear",
                    isInstalled: false
                ) {
                    installVCRedist()
                }

                // .NET Framework Tool
                CompactToolCard(
                    title: ".NET Framework",
                    description: "Microsoft .NET Framework 4.8",
                    icon: "square.grid.3x3",
                    isInstalled: false
                ) {
                    installDotNet()
                }

                // DirectX Tool
                CompactToolCard(
                    title: "DirectX 11",
                    description: "Microsoft DirectX libraries",
                    icon: "display",
                    isInstalled: true
                ) {
                    installDirectX()
                }
            }
        }
    }

    private var systemIntegrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GPTK System Integration")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                SystemIntegrationCard(
                    title: "CrossOver Integration",
                    description: "Import games and bottles from CrossOver to GPTK",
                    icon: "arrow.triangle.2.circlepath",
                    action: "Import"
                ) {
                    importCrossOverBottles()
                }

                SystemIntegrationCard(
                    title: "System Cleanup",
                    description: "Clean temporary files and reset Wine prefixes",
                    icon: "trash",
                    action: "Clean"
                ) {
                    performSystemCleanup()
                }

                SystemIntegrationCard(
                    title: "Backup & Restore",
                    description: "Backup your bottles and game configurations",
                    icon: "externaldrive",
                    action: "Backup"
                ) {
                    backupBottles()
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
            addGameDirectly(from: selectedFile)
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }

    private func addGameDirectly(from url: URL) {
        let gameName = url.deletingPathExtension().lastPathComponent
        let game = Game(
            name: gameName,
            executablePath: url.path,
            installPath: url.deletingLastPathComponent().path
        )

        Task {
            await gamePortingToolkitManager.addUserGame(game)
        }
    }

    private func createQuickBottle(_ type: String) {
        let bottleName = "\(type)-\(Date().timeIntervalSince1970)"
        Task {
            await gamePortingToolkitManager.createBottle(name: bottleName)
            loadAvailableBottles()
        }
    }

    private func installSteam() {
        Task {
            do {
                try await gamePortingToolkitManager.installSteam()
            } catch {
                print("Steam installation failed: \(error)")
            }
        }
    }

    private func installDXVK() {
        installComponent("dxvk")
    }

    private func installVCRedist() {
        installComponent("vcrun2019")
    }

    private func installDotNet() {
        installComponent("dotnet48")
    }

    private func installDirectX() {
        installComponent("d3d11")
    }

    private func installComponent(_ component: String) {
        guard let bottle = gamePortingToolkitManager.selectedBottle else { return }
        Task {
            do {
                try await gamePortingToolkitManager.installDependency(component, for: bottle)
            } catch {
                print("Component installation failed: \(error)")
            }
        }
    }

    private func importCrossOverBottles() {
        Task {
            let bottles = await gamePortingToolkitManager.detectCrossOverBottles()
            for bottleName in bottles {
                try? await gamePortingToolkitManager.importCrossOverSteamBottle(
                    bottleName: bottleName)
            }
            loadAvailableBottles()
        }
    }

    private func performSystemCleanup() {
        // Implement system cleanup functionality
        print("Performing system cleanup...")
    }

    private func backupBottles() {
        // Implement backup functionality
        print("Starting backup process...")
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
