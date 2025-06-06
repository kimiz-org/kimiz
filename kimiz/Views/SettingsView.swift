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
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    @AppStorage("autoDetectGames") private var autoDetectGames = true
    @AppStorage("enableHUD") private var enableHUD = false
    @AppStorage("useEsync") private var useEsync = true
    @AppStorage("useDXVKAsync") private var useDXVKAsync = false

    var body: some View {
        Form {
            // Game Porting Toolkit Status Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(gamePortingToolkitManager.isGPTKInstalled ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text(
                            gamePortingToolkitManager.isGPTKInstalled
                                ? "GPTK Installed" : "GPTK Not Installed"
                        )
                        .font(.headline)
                    }

                    if gamePortingToolkitManager.isInitializing {
                        ProgressView(gamePortingToolkitManager.initializationStatus)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets())
            } header: {
                Text("Game Porting Toolkit")
            }

            // Game Settings Section
            Section {
                Toggle("Auto-detect installed games", isOn: $autoDetectGames)
                Toggle("Show performance overlay", isOn: $enableHUD)

                Button("Scan for Installed Games") {
                    Task {
                        await gamePortingToolkitManager.scanForGames()
                    }
                }
                .disabled(!gamePortingToolkitManager.isGPTKInstalled)
            } header: {
                Text("Game Settings")
            }

            // Performance Settings Section
            Section {
                Toggle("Enable Esync", isOn: $useEsync)
                    .help("Improves Wine performance by using eventfd-based synchronization")

                Toggle("DXVK Async", isOn: $useDXVKAsync)
                    .help("Enables asynchronous shader compilation for smoother gameplay")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Performance Tips:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• Enable Esync for better CPU utilization")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• DXVK Async can reduce stuttering but may cause graphical issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            } header: {
                Text("Performance")
            }

            // Advanced Settings Section
            Section {
                Toggle("Debug mode", isOn: $enableDebugMode)

                Button("Reinstall Game Porting Toolkit") {
                    Task {
                        do {
                            await MainActor.run {
                                gamePortingToolkitManager.isInstallingComponents = true
                                gamePortingToolkitManager.installationProgress = 0.1
                                gamePortingToolkitManager.installationStatus =
                                    "Starting installation..."
                            }

                            try await gamePortingToolkitManager.installGamePortingToolkit()

                            await MainActor.run {
                                gamePortingToolkitManager.installationProgress = 0.9
                                gamePortingToolkitManager.installationStatus =
                                    "Verifying installation..."
                            }

                            await gamePortingToolkitManager.checkGPTKInstallation()

                            await MainActor.run {
                                gamePortingToolkitManager.isInstallingComponents = false
                                gamePortingToolkitManager.installationProgress = 1.0
                                gamePortingToolkitManager.installationStatus =
                                    "Installation complete"
                            }
                        } catch GamePortingToolkitManager.GPTKError.homebrewRequired {
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
                .foregroundColor(.orange)

                Button("Reset All Settings") {
                    resetSettings()
                }
                .foregroundColor(.red)
            } header: {
                Text("Advanced")
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/your-repo/kimiz") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resetSettings() {
        enableDebugMode = false
        autoDetectGames = true
        enableHUD = false
        useEsync = true
        useDXVKAsync = false
    }
}

#Preview {
    SettingsView()
        .environmentObject(GamePortingToolkitManager.shared)
}
