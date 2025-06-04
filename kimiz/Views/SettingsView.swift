//
//  SettingsView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var wineManager: WineManager
    @AppStorage("defaultWineBackend") private var defaultBackend = "wine"
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    @AppStorage("autoDetectGames") private var autoDetectGames = true
    @AppStorage("enableHUD") private var enableHUD = false
    @AppStorage("useEsync") private var useEsync = true
    @AppStorage("useDXVKAsync") private var useDXVKAsync = true

    var body: some View {
        NavigationView {
            Form {
                Section("Wine Configuration") {
                    Picker("Default Wine Backend", selection: $defaultBackend) {
                        ForEach(wineManager.availableBackends, id: \.rawValue) { backend in
                            Text(backend.displayName).tag(backend.rawValue)
                        }
                    }

                    Toggle("Enable Debug Mode", isOn: $enableDebugMode)
                        .help("Shows Wine debug output in console")

                    Toggle("Auto-detect Games", isOn: $autoDetectGames)
                        .help("Automatically scan Wine prefixes for installed games")
                }

                Section("Game Porting Toolkit") {
                    Toggle("Enable Metal HUD", isOn: $enableHUD)
                        .help("Shows Metal performance HUD during gameplay")

                    Toggle("Enable Esync", isOn: $useEsync)
                        .help("Improves performance with synchronization primitives")

                    Toggle("Enable DXVK Async", isOn: $useDXVKAsync)
                        .help("Enables asynchronous shader compilation")
                }

                Section("System Information") {
                    SystemInfoView()
                }

                Section("About") {
                    AboutView()
                }

                Section("Advanced") {
                    AdvancedSettingsView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SystemInfoView: View {
    @State private var systemInfo = SystemInfo()

    struct SystemInfo {
        var macOSVersion = ""
        var chipArchitecture = ""
        var memorySize = ""
        var gpuInfo = ""

        init() {
            self.macOSVersion = ProcessInfo.processInfo.operatingSystemVersionString

            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            self.chipArchitecture = identifier

            let memory = ProcessInfo.processInfo.physicalMemory
            self.memorySize = ByteCountFormatter.string(
                fromByteCount: Int64(memory), countStyle: .memory)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InfoRow(label: "macOS Version", value: systemInfo.macOSVersion)
            InfoRow(label: "Architecture", value: systemInfo.chipArchitecture)
            InfoRow(label: "Memory", value: systemInfo.memorySize)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gamecontroller")
                    .font(.title)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading) {
                    Text("Kimiz")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                }
            }

            Text("A Wine and Game Porting Toolkit manager for macOS")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Features:")
                    .fontWeight(.semibold)

                Text("• Wine prefix management")
                Text("• Steam integration")
                Text("• Game Porting Toolkit support")
                Text("• CrossOver compatibility")
                Text("• Game library management")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

struct AdvancedSettingsView: View {
    @EnvironmentObject var wineManager: WineManager
    @State private var showingResetAlert = false
    @State private var showingClearCacheAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Refresh Wine Backends") {
                wineManager.detectAvailableBackends()
            }
            .buttonStyle(.bordered)

            Button("Clear Game Cache") {
                showingClearCacheAlert = true
            }
            .buttonStyle(.bordered)

            Button("Reset All Settings", role: .destructive) {
                showingResetAlert = true
            }
            .buttonStyle(.bordered)
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text(
                "This will reset all settings to their defaults. Wine prefixes and games will not be affected."
            )
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearGameCache()
            }
        } message: {
            Text("This will clear the game library cache and rescan for installed games.")
        }
    }

    private func resetAllSettings() {
        UserDefaults.standard.removeObject(forKey: "defaultWineBackend")
        UserDefaults.standard.removeObject(forKey: "enableDebugMode")
        UserDefaults.standard.removeObject(forKey: "autoDetectGames")
        UserDefaults.standard.removeObject(forKey: "enableHUD")
        UserDefaults.standard.removeObject(forKey: "useEsync")
        UserDefaults.standard.removeObject(forKey: "useDXVKAsync")
    }

    private func clearGameCache() {
        // Clear game installations cache
        wineManager.gameInstallations.removeAll()
    }
}

struct LogsView: View {
    @State private var logs: [String] = []

    var body: some View {
        NavigationView {
            VStack {
                if logs.isEmpty {
                    Text("No logs available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(logs.indices, id: \.self) { index in
                                Text(logs[index])
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        logs.removeAll()
                    }
                    .disabled(logs.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WineManager())
}
