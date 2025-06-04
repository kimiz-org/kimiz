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
            VStack(spacing: 24) {
                // Installation type selector
                Picker("Installation Type", selection: $selectedInstallationType) {
                    ForEach(InstallationType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Description and install button
                VStack(spacing: 16) {
                    Image(systemName: selectedInstallationType.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text(selectedInstallationType.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: performInstallation) {
                        HStack {
                            if isInstalling {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Installing...")
                            } else {
                                Text("Install \(selectedInstallationType.rawValue)")
                            }
                        }
                        .frame(minWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling || !embeddedWineManager.isWineReady)

                    if !embeddedWineManager.isWineReady {
                        Text("Wine is not ready. Please set it up in Settings first.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: 400)

                Spacer()
            }
            .padding()
            .navigationTitle("Install")
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
                try await embeddedWineManager.installSteam()
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
                // Copy file to a temporary location and run it with Wine
                let fileName = url.lastPathComponent
                let tempDir = NSTemporaryDirectory()
                let destination = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)

                try FileManager.default.copyItem(at: url, to: destination)

                // Run the installer with Wine
                _ = try await embeddedWineManager.runWineCommand([destination.path])

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

// Extension to support .exe files
extension UTType {
    static var exe: UTType {
        UTType(filenameExtension: "exe") ?? UTType.data
    }
}

#Preview {
    InstallationView()
        .environmentObject(EmbeddedWineManager())
}
