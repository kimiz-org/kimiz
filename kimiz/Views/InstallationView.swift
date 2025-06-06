//
//  InstallationView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI
import UniformTypeIdentifiers

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
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @State private var selectedInstallationType: InstallationType = .steam
    @State private var isInstalling = false
    @State private var showingFilePicker = false
    @State private var showingEpicConnection = false
    @State private var installationStep = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    enum InstallationType: String, CaseIterable {
        case steam = "Steam"
        case epicGames = "Epic Games"
        case executable = "Windows Executable"

        var description: String {
            switch self {
            case .steam:
                return "Install Steam client to access your game library using Game Porting Toolkit"
            case .epicGames:
                return
                    "Connect your Epic Games account to access and install your Epic games library"
            case .executable:
                return "Install a Windows .exe application or game using Game Porting Toolkit"
            }
        }

        var icon: String {
            switch self {
            case .steam:
                return "cloud.fill"
            case .epicGames:
                return "gamecontroller.fill"
            case .executable:
                return "app.badge"
            }
        }
    }

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.12, blue: 0.16),
                    Color(red: 0.16, green: 0.12, blue: 0.20),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Modern Header
                    modernHeaderView

                    // Installation Cards
                    LazyVStack(spacing: 20) {
                        ForEach(InstallationType.allCases, id: \.self) { type in
                            ModernInstallationCard(
                                type: type,
                                isSelected: selectedInstallationType == type,
                                onSelect: { selectedInstallationType = type },
                                isInstalling: isInstalling,
                                onInstall: performInstallation,
                                installationStep: installationStep,
                                epicGamesManager: epicGamesManager
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Dependencies Info
                    if !gamePortingToolkitManager.isGPTKInstalled && !isInstalling {
                        dependenciesInfoView
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.exe],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingEpicConnection) {
            EpicGamesConnectionView(isPresented: $showingEpicConnection)
                .environmentObject(epicGamesManager)
        }
        .alert("Installation Status", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    private var modernHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Install Applications")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Add Windows games and applications to your library")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    private var dependenciesInfoView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dependencies Required")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Required dependencies will be installed automatically when needed")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private func performInstallation() {
        guard !isInstalling else { return }

        switch selectedInstallationType {
        case .steam:
            installSteam()
        case .epicGames:
            showingEpicConnection = true
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

struct ModernInstallationCard: View {
    let type: InstallationView.InstallationType
    let isSelected: Bool
    let onSelect: () -> Void
    let isInstalling: Bool
    let onInstall: () -> Void
    let installationStep: String
    let epicGamesManager: EpicGamesManager

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Card Content
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                isSelected
                                    ? LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [.gray.opacity(0.3), .gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: type.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(type.rawValue)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            if type == .epicGames && epicGamesManager.isConnected {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }

                        Text(type.description)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if isSelected && isInstalling && !installationStep.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.cyan)
                                Text(installationStep)
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                            }
                            .padding(.top, 4)
                        }
                    }

                    Spacer()
                }
                .padding(20)

                // Action Button
                if isSelected {
                    Divider()
                        .background(.white.opacity(0.1))

                    HStack {
                        Spacer()

                        Button(action: onInstall) {
                            HStack(spacing: 8) {
                                if isInstalling {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                    Text("Installing...")
                                } else {
                                    Image(systemName: getActionIcon())
                                    Text(getActionText())
                                }
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                        .disabled(isInstalling)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected
                                ? LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [.white.opacity(0.1), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: 2
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(
            color: isSelected ? .cyan.opacity(0.3) : .black.opacity(0.1),
            radius: isSelected ? 12 : 4,
            x: 0,
            y: isSelected ? 6 : 2
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func getActionIcon() -> String {
        switch type {
        case .steam:
            return "cloud.fill"
        case .epicGames:
            return epicGamesManager.isConnected ? "gamecontroller.fill" : "link"
        case .executable:
            return "folder"
        }
    }

    private func getActionText() -> String {
        switch type {
        case .steam:
            return "Install Steam"
        case .epicGames:
            return epicGamesManager.isConnected ? "View Library" : "Connect Account"
        case .executable:
            return "Choose File"
        }
    }
}

// Keep the old InstallationCard for compatibility but mark it as deprecated
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
        .environmentObject(EpicGamesManager.shared)
}
