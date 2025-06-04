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
                    WineStatusView()
                        .environmentObject(embeddedWineManager)
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets())
                }

                // Game Settings Section
                Section("Game Settings") {
                    Toggle("Auto-detect installed games", isOn: $autoDetectGames)
                    Toggle("Show performance overlay", isOn: $enableHUD)

                    Button("Scan for Installed Games") {
                        Task {
                            await embeddedWineManager.scanForInstalledGames()
                        }
                    }
                    .disabled(!embeddedWineManager.isWineReady)
                }

                // Performance Settings Section
                Section("Performance") {
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
