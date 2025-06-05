//
//  InstallationView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI
import UniformTypeIdentifiers
@_spi(SPI) import kimiz

enum InstallationError: LocalizedError {
    case homebrewRequired
    case gptkInstallationFailed(String)
    case manualInstallationRequired

    var errorDescription: String? {
        switch self {
        case .homebrewRequired:
            return "Homebrew is required to install Game Porting Toolkit"
        case .gptkInstallationFailed(let message):
            return message
        case .manualInstallationRequired:
            return "Manual installation of Game Porting Toolkit is required"
        }
    }
}

struct InstallationView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var selectedInstallationType: InstallationType = .steam
    @State private var isInstalling = false
    @State private var showingFilePicker = false
    @State private var installationStep = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    enum InstallationType: String, CaseIterable {
        case steam = "Steam"
        case executable = "Windows Executable"

        var description: String {
            switch self {
            case .steam:
                return "Install Steam client to access your game library using Game Porting Toolkit"
            case .executable:
                return "Install a Windows .exe application or game using Game Porting Toolkit"
            }
        }

        var icon: String {
            switch self {
            case .steam:
                return "cloud.fill"
            case .executable:
                return "app.badge"
            }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("Install Applications")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Install Windows games and applications using Apple's Game Porting Toolkit")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)

            // Installation type cards
            VStack(spacing: 16) {
                ForEach(InstallationType.allCases, id: \.self) { type in
                    InstallationCard(
                        type: type,
                        isSelected: selectedInstallationType == type,
                        onSelect: { selectedInstallationType = type },
                        isInstalling: isInstalling,
                        onInstall: performInstallation,
                        installationStep: installationStep
                    )
                }
            }
            .padding(.horizontal)

            // Show dependencies status info (non-blocking)
            if !gamePortingToolkitManager.isGPTKInstalled && !isInstalling {
                VStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Required dependencies")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(
                        "Required dependencies will be installed automatically before running applications"
                    )
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            Spacer()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.exe],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Installation Status", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    private func performInstallation() {
        guard !isInstalling else { return }

        switch selectedInstallationType {
        case .steam:
            installSteam()
        case .executable:
            showingFilePicker = true
        }
    }

    private func ensureGPTKInstalled() async throws {
        // Check if GPTK is already installed
        if gamePortingToolkitManager.isGPTKInstalled {
            return
        }

        await MainActor.run {
            installationStep = "Checking dependencies..."
        }

        // First check if Homebrew is available
        if !isHomebrewInstalled() {
            throw InstallationError.homebrewRequired
        }

        // Install only dependencies without full GPTK
        do {
            await MainActor.run {
                installationStep = "Installing required dependencies..."
            }

            try await gamePortingToolkitManager.installDependenciesOnly()

            // The installDependenciesOnly method should have set isGPTKInstalled to true
            if !gamePortingToolkitManager.isGPTKInstalled {
                throw InstallationError.gptkInstallationFailed(
                    "Dependencies installation verification failed")
            }
        } catch {
            // If installation fails, provide helpful guidance
            let errorMessage = error.localizedDescription
            if errorMessage.contains("Homebrew") {
                throw InstallationError.homebrewRequired
            } else {
                throw InstallationError.gptkInstallationFailed(
                    "Failed to install dependencies: \(errorMessage)")
            }
        }
    }

    private func isHomebrewInstalled() -> Bool {
        let homebrewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew",  // Intel
        ]

        return homebrewPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }
    }

    private func installSteam() {
        isInstalling = true
        installationStep = "Preparing installation..."

        Task {
            do {
                // First ensure GPTK is installed
                try await ensureGPTKInstalled()

                await MainActor.run {
                    installationStep = "Installing Steam..."
                }

                try await gamePortingToolkitManager.installSteam()

                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage = "Steam has been installed successfully!"
                    showingAlert = true
                }
            } catch InstallationError.homebrewRequired {
                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage =
                        "Homebrew is required to install Game Porting Toolkit.\n\nPlease install Homebrew from https://brew.sh and try again.\n\nAlternatively, you can install GPTK manually from Apple's Developer portal at https://developer.apple.com/games/"
                    showingAlert = true
                }
            } catch InstallationError.manualInstallationRequired {
                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage =
                        "Automatic installation failed. Please install Game Porting Toolkit manually from Apple's Developer portal at https://developer.apple.com/games/"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage =
                        "Installation failed: \(error.localizedDescription)\n\nYou can try installing GPTK manually from https://developer.apple.com/games/"
                    showingAlert = true
                }
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                installExecutable(at: url)
            }
        case .failure(let error):
            alertMessage = "File selection failed: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func installExecutable(at url: URL) {
        isInstalling = true
        installationStep = "Preparing installation..."

        Task {
            do {
                // First ensure GPTK is installed
                try await ensureGPTKInstalled()

                await MainActor.run {
                    installationStep = "Installing executable..."
                }

                // Copy file to a temporary location and run it
                let fileName = url.lastPathComponent
                let tempDir = FileManager.default.temporaryDirectory
                let destination = tempDir.appendingPathComponent(fileName)

                // Set proper permissions for the temp directory
                try FileManager.default.createDirectory(
                    at: tempDir, withIntermediateDirectories: true)

                // Copy with proper permissions
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: url, to: destination)

                // Set executable permissions
                var attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
                let currentPermissions =
                    attributes[.posixPermissions] as? NSNumber ?? NSNumber(value: 0o644)
                let newPermissions = currentPermissions.uint16Value | 0o755
                try FileManager.default.setAttributes(
                    [.posixPermissions: NSNumber(value: newPermissions)],
                    ofItemAtPath: destination.path)

                // Run the installer using GPTK
                try await gamePortingToolkitManager.runGame(executablePath: destination.path)

                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage = "Executable has been launched successfully!"
                    showingAlert = true
                }

                // Clean up after a delay to allow the process to start
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    try? FileManager.default.removeItem(at: destination)
                }
            } catch InstallationError.homebrewRequired {
                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage =
                        "Homebrew is required to install Game Porting Toolkit.\n\nPlease install Homebrew from https://brew.sh and try again.\n\nAlternatively, you can install GPTK manually from Apple's Developer portal at https://developer.apple.com/games/"
                    showingAlert = true
                }
            } catch InstallationError.manualInstallationRequired {
                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage =
                        "Automatic installation failed. Please install Game Porting Toolkit manually from Apple's Developer portal at https://developer.apple.com/games/"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    installationStep = ""
                    alertMessage =
                        "Installation failed: \(error.localizedDescription)\n\nYou can try installing GPTK manually from https://developer.apple.com/games/"
                    showingAlert = true
                }
            }
        }
    }
}

struct InstallationCard: View {
    let type: InstallationView.InstallationType
    let isSelected: Bool
    let onSelect: () -> Void
    let isInstalling: Bool
    let onInstall: () -> Void
    let installationStep: String

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(type.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    if isInstalling && !installationStep.isEmpty {
                        Text(installationStep)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }

                Spacer()

                if isSelected {
                    Button(action: onInstall) {
                        HStack {
                            if isInstalling {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Installing...")
                            } else {
                                Text("Install")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// Extension to support .exe files
extension UTType {
    static var exe: UTType {
        UTType(filenameExtension: "exe") ?? UTType.data
    }
}

#Preview {
    InstallationView()
        .environmentObject(GamePortingToolkitManager.shared)
}
