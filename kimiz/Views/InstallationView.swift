//
//  InstallationView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct InstallationView: View {
    @EnvironmentObject var wineManager: WineManager
    @State private var selectedInstallationType: InstallationType = .steam
    @State private var selectedPrefix: WinePrefix?
    @State private var isInstalling = false
    @State private var installationProgress: Double = 0.0
    @State private var installationStatus = ""
    @State private var showingFilePicker = false

    enum InstallationType: String, CaseIterable {
        case steam = "Steam"
        case executable = "Windows Executable"
        case msi = "MSI Installer"
        case gamePortingToolkit = "Game Porting Toolkit Setup"

        var description: String {
            switch self {
            case .steam:
                return "Install Steam client to access your game library"
            case .executable:
                return "Install a Windows .exe application or game"
            case .msi:
                return "Install a Windows .msi package"
            case .gamePortingToolkit:
                return "Set up Apple's Game Porting Toolkit for better compatibility"
            }
        }

        var icon: String {
            switch self {
            case .steam:
                return "cloud.fill"
            case .executable:
                return "app.badge"
            case .msi:
                return "archivebox"
            case .gamePortingToolkit:
                return "apple.logo"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if wineManager.winePrefixes.isEmpty {
                    EmptyPrefixesView()
                } else {
                    installationContent
                }
            }
            .padding()
            .navigationTitle("Install Games")
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    var installationContent: some View {
        VStack(spacing: 20) {
            // Wine Backend Status
            StatusView()

            // Installation Type Selection
            GroupBox("Installation Type") {
                VStack(spacing: 12) {
                    ForEach(InstallationType.allCases, id: \.self) { type in
                        InstallationTypeCard(
                            type: type,
                            isSelected: selectedInstallationType == type
                        ) {
                            selectedInstallationType = type
                        }
                    }
                }
            }

            // Wine Prefix Selection
            if !wineManager.winePrefixes.isEmpty {
                GroupBox("Target Wine Prefix") {
                    Picker("Select Wine Prefix", selection: $selectedPrefix) {
                        Text("Select a prefix").tag(nil as WinePrefix?)
                        ForEach(wineManager.winePrefixes, id: \.id) { prefix in
                            HStack {
                                Text(prefix.name)
                                Spacer()
                                Text(prefix.backend.displayName)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .tag(prefix as WinePrefix?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Installation Progress
            if isInstalling {
                InstallationProgressView(
                    progress: installationProgress,
                    status: installationStatus
                )
            }

            // Install Button
            Button(action: {
                startInstallation()
            }) {
                HStack {
                    if isInstalling {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: selectedInstallationType.icon)
                    }
                    Text(
                        isInstalling
                            ? "Installing..." : "Install \(selectedInstallationType.rawValue)")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedPrefix == nil || isInstalling)

            Spacer()
        }
    }

    private func startInstallation() {
        guard let prefix = selectedPrefix else { return }

        isInstalling = true
        installationProgress = 0.0

        Task {
            do {
                switch selectedInstallationType {
                case .steam:
                    installationStatus = "Downloading Steam installer..."
                    try await wineManager.installSteam(in: prefix)

                case .executable, .msi:
                    await MainActor.run {
                        showingFilePicker = true
                    }

                case .gamePortingToolkit:
                    installationStatus = "Setting up Game Porting Toolkit..."
                    try await setupGamePortingToolkit(in: prefix)
                }

                await MainActor.run {
                    installationStatus = "Installation completed successfully!"
                    installationProgress = 1.0
                }

                // Reset after delay
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    isInstalling = false
                    installationStatus = ""
                    installationProgress = 0.0
                }

            } catch {
                await MainActor.run {
                    installationStatus = "Installation failed: \(error.localizedDescription)"
                    isInstalling = false
                }
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first, let prefix = selectedPrefix else { return }

            Task {
                do {
                    installationStatus = "Installing \(url.lastPathComponent)..."

                    try await wineManager.runWindowsExecutable(
                        path: url.path,
                        in: prefix,
                        arguments: selectedInstallationType == .msi ? ["/quiet"] : [],
                        waitForCompletion: true
                    )

                    await MainActor.run {
                        installationStatus = "Installation completed!"
                        installationProgress = 1.0
                    }

                } catch {
                    await MainActor.run {
                        installationStatus = "Installation failed: \(error.localizedDescription)"
                    }
                }
            }

        case .failure(let error):
            installationStatus = "File selection failed: \(error.localizedDescription)"
        }
    }

    private func setupGamePortingToolkit(in prefix: WinePrefix) async throws {
        // This would involve setting up GPTK-specific configurations
        // For now, we'll just create the prefix with GPTK optimizations
        installationStatus = "Configuring Game Porting Toolkit optimizations..."

        // Set up GPTK environment variables and configurations
        let configPath = "\(prefix.path)/gptk_config.sh"
        let config = """
            #!/bin/bash
            export MTL_HUD_ENABLED=1
            export WINEESYNC=1
            export DXVK_ASYNC=1
            export WINE_LARGE_ADDRESS_AWARE=1
            export MTL_SHADER_VALIDATION=0
            """

        try config.write(toFile: configPath, atomically: true, encoding: .utf8)
    }
}

struct StatusView: View {
    @EnvironmentObject var wineManager: WineManager

    var body: some View {
        GroupBox("Wine Backend Status") {
            VStack(alignment: .leading, spacing: 8) {
                if wineManager.availableBackends.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("No Wine backends detected")
                        Spacer()
                    }
                } else {
                    ForEach(wineManager.availableBackends, id: \.self) { backend in
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text(backend.displayName)
                            Spacer()
                            Text("Available")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

struct InstallationTypeCard: View {
    let type: InstallationView.InstallationType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 24)

                VStack(alignment: .leading) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct InstallationProgressView: View {
    let progress: Double
    let status: String

    var body: some View {
        GroupBox("Installation Progress") {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())

                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct EmptyPrefixesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Wine Prefixes")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a Wine prefix first in the Wine Prefixes tab to install games")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NavigationLink(destination: WinePrefixesView()) {
                Text("Create Wine Prefix")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    InstallationView()
        .environmentObject(WineManager())
}
