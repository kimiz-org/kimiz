//
//  InstallationView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct InstallationView: View {
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @State private var selectedInstallationType: InstallationType = .steam
    @State private var isInstalling = false
    @State private var installationProgress: Double = 0.0
    @State private var installationStatus = ""
    @State private var showingFilePicker = false

    enum InstallationType: String, CaseIterable {
        case steam = "Steam"
        case executable = "Windows Executable"

        var description: String {
            switch self {
            case .steam:
                return "Install Steam client to access your game library"
            case .executable:
                return "Install a Windows .exe application or game"
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
        NavigationView {
            VStack(spacing: 20) {
                installationContent
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
            // Wine Status
            EmbeddedWineStatusView()

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
            .disabled(isInstalling || !embeddedWineManager.isWineReady)

            Spacer()
        }
    }

    private func startInstallation() {
        isInstalling = true
        installationProgress = 0.0

        Task {
            do {
                switch selectedInstallationType {
                case .steam:
                    installationStatus = "Installing Steam..."
                    try await embeddedWineManager.installSteam()

                case .executable:
                    await MainActor.run {
                        showingFilePicker = true
                    }
                    return
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
            guard let url = urls.first else { return }

            Task {
                do {
                    installationStatus = "Installing \(url.lastPathComponent)..."
                    isInstalling = true

                    try await embeddedWineManager.launchGame(executablePath: url.path)

                    await MainActor.run {
                        installationStatus = "Installation completed!"
                        installationProgress = 1.0
                        isInstalling = false
                    }

                } catch {
                    await MainActor.run {
                        installationStatus = "Installation failed: \(error.localizedDescription)"
                        isInstalling = false
                    }
                }
            }

        case .failure(let error):
            installationStatus = "File selection failed: \(error.localizedDescription)"
        }
    }
}

struct EmbeddedWineStatusView: View {
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager

    var body: some View {
        GroupBox("Wine Status") {
            HStack {
                if embeddedWineManager.isWineReady {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Embedded Wine Ready")
                    Spacer()
                    Text("Ready")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else if embeddedWineManager.isInitializing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Initializing Wine...")
                    Spacer()
                    Text("Please wait")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Wine Not Ready")
                    Spacer()
                    Text("Initializing")
                        .foregroundColor(.secondary)
                        .font(.caption)
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

#Preview {
    InstallationView()
        .environmentObject(EmbeddedWineManager())
}
