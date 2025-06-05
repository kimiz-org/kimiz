//
//  InstallationView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct InstallationView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var selectedInstallationType: InstallationType = .steam
    @State private var isInstalling = false
    @State private var showingFilePicker = false

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
                        isEnabled: gamePortingToolkitManager.isGPTKInstalled
                    )
                }
            }
            .padding(.horizontal)

            if !gamePortingToolkitManager.isGPTKInstalled {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Game Porting Toolkit is not installed")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Please install GPTK in Settings before installing applications")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
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
    }

    private func performInstallation() {
        switch selectedInstallationType {
        case .steam:
            installSteam()
        case .executable:
            showingFilePicker = true
        }
    }

    private func installSteam() {
        isInstalling = true
        Task {
            do {
                try await gamePortingToolkitManager.installSteam()
                await MainActor.run {
                    isInstalling = false
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                }
                print("Failed to install Steam: \(error)")
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
            print("File selection failed: \(error)")
        }
    }

    private func installExecutable(at url: URL) {
        isInstalling = true
        Task {
            do {
                // Copy file to a temporary location and run it
                let fileName = url.lastPathComponent
                let tempDir = FileManager.default.temporaryDirectory
                let destination = tempDir.appendingPathComponent(fileName)
                try FileManager.default.copyItem(at: url, to: destination)

                // Run the installer using GPTK
                try await gamePortingToolkitManager.runGame(executablePath: destination.path)

                await MainActor.run {
                    isInstalling = false
                }

                // Clean up
                try? FileManager.default.removeItem(at: destination)
            } catch {
                await MainActor.run {
                    isInstalling = false
                }
                print("Failed to install executable: \(error)")
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
    let isEnabled: Bool

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
                    .disabled(isInstalling || !isEnabled)
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
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
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
