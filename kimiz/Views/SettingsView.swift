//
//  SettingsView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    @AppStorage("autoDetectGames") private var autoDetectGames = true
    @AppStorage("enableHUD") private var enableHUD = false
    @AppStorage("useEsync") private var useEsync = true
    @AppStorage("useDXVKAsync") private var useDXVKAsync = false

    var body: some View {
        NavigationView {
            Form {
                // Wine Status Section
                Section("Wine Environment") {
                    HStack {
                        Image(
                            systemName: embeddedWineManager.isWineReady
                                ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(embeddedWineManager.isWineReady ? .green : .red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wine Status")
                                .font(.headline)
                            Text(embeddedWineManager.isWineReady ? "Ready" : "Not Available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !embeddedWineManager.isWineReady {
                            Button("Setup") {
                                Task {
                                    await embeddedWineManager.checkWineInstallation()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    if let error = embeddedWineManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Game Settings Section
                Section("Game Settings") {
                    Toggle("Auto-detect installed games", isOn: $autoDetectGames)
                    Toggle("Show performance overlay", isOn: $enableHUD)
                }

                // Performance Settings Section
                Section("Performance") {
                    Toggle("Enable Esync", isOn: $useEsync)
                    Toggle("DXVK Async", isOn: $useDXVKAsync)
                }

                // Advanced Settings Section
                Section("Advanced") {
                    Toggle("Debug mode", isOn: $enableDebugMode)

                    Button("Reinstall Wine Environment") {
                        Task {
                            try? await embeddedWineManager.initializeWine()
                        }
                    }
                    .foregroundColor(.orange)

                    Button("Reset All Settings") {
                        resetSettings()
                    }
                    .foregroundColor(.red)
                }

                // About Section
                Section("About") {
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
                }
            }
            .navigationTitle("Settings")
            .formStyle(.grouped)
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

#Preview {
    SettingsView()
        .environmentObject(EmbeddedWineManager())
}
