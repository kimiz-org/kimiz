//
//  EngineView.swift
//  kimiz
//
//  Created by System on June 10, 2025.
//
//  Comprehensive GPTK Engine management interface
//

import SwiftUI

struct EngineView: View {
    @EnvironmentObject var engineManager: EngineManager
    @State private var showingAdvancedSettings = false
    @State private var showingInstallConfirmation = false
    @State private var showingRemoveConfirmation = false

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.1, blue: 0.2),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView

                    // Engine Status Card
                    engineStatusCard

                    // Performance Settings Card
                    if engineManager.isEngineInstalled {
                        performanceSettingsCard
                    }

                    // Advanced Settings Card
                    if engineManager.isEngineInstalled && showingAdvancedSettings {
                        advancedSettingsCard
                    }

                    // Action Buttons
                    actionButtonsView
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .alert("Install Engine", isPresented: $showingInstallConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Install") {
                Task {
                    try await engineManager.installEngine()
                }
            }
        } message: {
            Text(
                "This will install the Game Porting Toolkit engine. The process may take 15-30 minutes."
            )
        }
        .alert("Remove Engine", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    try await engineManager.removeEngine()
                }
            }
        } message: {
            Text(
                "This will completely remove the engine and all its components. This action cannot be undone."
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .font(.title)
                    .foregroundColor(.orange)

                Text("GPTK Engine")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()
            }

            HStack {
                Text("Manage your Game Porting Toolkit installation and performance settings")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }
        }
    }

    // MARK: - Engine Status Card

    private var engineStatusCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Engine Status")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                StatusIndicator(isInstalled: engineManager.isEngineInstalled)
            }

            VStack(spacing: 16) {
                EngineStatusRow(
                    title: "Installation Status",
                    value: engineManager.isEngineInstalled ? "Installed" : "Not Installed",
                    valueColor: engineManager.isEngineInstalled ? .green : .red
                )

                if let version = engineManager.engineVersion {
                    EngineStatusRow(
                        title: "Engine Version",
                        value: version,
                        valueColor: .blue
                    )
                }

                EngineStatusRow(
                    title: "Binary Path",
                    value: engineManager.getGPTKPath() ?? "Not Found",
                    valueColor: engineManager.getGPTKPath() != nil ? .green : .red
                )

                if engineManager.isInstalling {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Installation Progress")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)

                            Spacer()

                            Text("\(Int(engineManager.installationProgress * 100))%")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        }

                        ProgressView(value: engineManager.installationProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))

                        Text(engineManager.installationStatus)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let error = engineManager.lastError {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Error")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }

                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.leading, 24)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Performance Settings Card

    private var performanceSettingsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Performance Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }

            VStack(spacing: 16) {
                SettingToggle(
                    title: "Enable DXVK",
                    description: "DirectX to Vulkan translation layer",
                    isOn: $engineManager.enableDXVK
                )

                SettingToggle(
                    title: "Enable ESync",
                    description: "Event synchronization for better performance",
                    isOn: $engineManager.enableESync
                )

                SettingToggle(
                    title: "Metal HUD",
                    description: "Show Metal performance overlay",
                    isOn: $engineManager.metalHUD
                )

                SettingToggle(
                    title: "Use RAM Disk",
                    description: "Use RAM disk for temporary files",
                    isOn: $engineManager.useRAMDisk
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CPU Threads")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(engineManager.cpuThreads)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(engineManager.cpuThreads) },
                            set: { engineManager.cpuThreads = Int($0) }
                        ),
                        in: 1...Double(ProcessInfo.processInfo.activeProcessorCount),
                        step: 1
                    )
                    .accentColor(.orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Memory Limit")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(engineManager.memoryLimit) MB")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(engineManager.memoryLimit) },
                            set: { engineManager.memoryLimit = Int($0) }
                        ),
                        in: 1024...16384,
                        step: 512
                    )
                    .accentColor(.orange)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Advanced Settings Card

    private var advancedSettingsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Advanced Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }

            VStack(spacing: 16) {
                SettingToggle(
                    title: "Enable FSync",
                    description: "Fast user synchronization (experimental)",
                    isOn: $engineManager.enableFSync
                )

                SettingToggle(
                    title: "Enable ACO",
                    description: "AMD Compiler Optimizations",
                    isOn: $engineManager.enableACO
                )

                SettingToggle(
                    title: "Debug Logging",
                    description: "Enable detailed debug output",
                    isOn: $engineManager.debugLogging
                )

                SettingToggle(
                    title: "Rosetta Optimization",
                    description: "Enable Rosetta 2 specific optimizations",
                    isOn: $engineManager.enableRosettaOptimization
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            if !engineManager.isEngineInstalled && !engineManager.isInstalling {
                Button(action: {
                    showingInstallConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Install Engine")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.borderless)
            }

            if engineManager.isEngineInstalled {
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            showingAdvancedSettings.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(showingAdvancedSettings ? "Hide Advanced" : "Advanced Settings")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        showingRemoveConfirmation = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Remove Engine")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let isInstalled: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isInstalled ? Color.green : Color.red)
                .frame(width: 12, height: 12)

            Text(isInstalled ? "Installed" : "Not Installed")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isInstalled ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((isInstalled ? Color.green : Color.red).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((isInstalled ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct EngineStatusRow: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(valueColor)
        }
    }
}

struct SettingToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
        }
    }
}

// MARK: - Preview

struct EngineView_Previews: PreviewProvider {
    static var previews: some View {
        EngineView()
            .environmentObject(EngineManager.shared)
            .frame(width: 800, height: 600)
    }
}
