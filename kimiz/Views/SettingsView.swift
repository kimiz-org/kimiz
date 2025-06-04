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
    @AppStorage("useDXVKAsync") private var useDXVKAsync = true

    @State private var animateHeader = false
    @State private var animateCards = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.1),
                    Color.red.opacity(0.1),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // Header Section
                headerSection

                // Content Section
                contentSection
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Configure kimiz for optimal performance")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status indicator
                StatusIndicator()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .opacity(animateHeader ? 1 : 0)
        .offset(y: animateHeader ? 0 : -20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateHeader)
    }

    // MARK: - Content Section
    private var contentSection: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Wine Configuration
                SettingsCard(
                    title: "Wine Configuration",
                    icon: "gear",
                    color: .blue
                ) {
                    VStack(spacing: 16) {
                        SettingsRow(
                            title: "Wine Backend",
                            subtitle: "Currently using embedded Wine for compatibility",
                            icon: "gear.circle.fill",
                            color: .blue
                        ) {
                            Text("Embedded Wine")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        SettingsToggleRow(
                            title: "Debug Mode",
                            subtitle: "Shows Wine debug output in console",
                            icon: "ladybug.circle.fill",
                            color: .purple,
                            isOn: $enableDebugMode
                        )

                        SettingsToggleRow(
                            title: "Auto-detect Games",
                            subtitle: "Automatically scan for installed games",
                            icon: "magnifyingglass.circle.fill",
                            color: .green,
                            isOn: $autoDetectGames
                        )
                    }
                }

                // Performance Settings
                SettingsCard(
                    title: "Performance",
                    icon: "speedometer",
                    color: .green
                ) {
                    VStack(spacing: 16) {
                        SettingsToggleRow(
                            title: "Metal HUD",
                            subtitle: "Shows Metal performance HUD during gameplay",
                            icon: "chart.bar.circle.fill",
                            color: .orange,
                            isOn: $enableHUD
                        )

                        SettingsToggleRow(
                            title: "Esync",
                            subtitle: "Improves performance with synchronization primitives",
                            icon: "arrow.triangle.2.circlepath.circle.fill",
                            color: .blue,
                            isOn: $useEsync
                        )

                        SettingsToggleRow(
                            title: "DXVK Async",
                            subtitle: "Enables asynchronous shader compilation",
                            icon: "bolt.circle.fill",
                            color: .yellow,
                            isOn: $useDXVKAsync
                        )
                    }
                }

                // System Information
                SettingsCard(
                    title: "System Information",
                    icon: "info.circle",
                    color: .indigo
                ) {
                    ModernSystemInfoView()
                }

                // About Section
                SettingsCard(
                    title: "About",
                    icon: "heart.circle",
                    color: .pink
                ) {
                    AboutSection()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateCards)
    }

    // MARK: - Helper Methods
    private func startAnimations() {
        withAnimation {
            animateHeader = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animateCards = true
            }
        }
    }
}

// MARK: - Components

struct StatusIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .scaleEffect(1.5)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: true
                        )
                )

            Text("System Ready")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
            }

            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            content()
        }
        .padding(.vertical, 4)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color
        ) {
            Toggle("", isOn: $isOn)
                .toggleStyle(ModernToggleStyle())
        }
    }
}

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

struct ModernSystemInfoView: View {
    var body: some View {
        VStack(spacing: 12) {
            SystemInfoRow(
                label: "Operating System",
                value: ProcessInfo.processInfo.operatingSystemVersionString)
            SystemInfoRow(label: "Architecture", value: getSystemArchitecture())
            SystemInfoRow(label: "Memory", value: getFormattedMemory())
            SystemInfoRow(label: "Wine Version", value: "Embedded Wine 8.0+")
            SystemInfoRow(
                label: "kimiz Version",
                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                    ?? "Unknown")
        }
    }

    private func getSystemArchitecture() -> String {
        #if arch(arm64)
            return "Apple Silicon (ARM64)"
        #else
            return "Intel (x86_64)"
        #endif
    }

    private func getFormattedMemory() -> String {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryInGB = Double(totalMemory) / 1_073_741_824
        return String(format: "%.1f GB", memoryInGB)
    }
}

struct SystemInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("kimiz")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Wine Gaming Made Simple")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text(
                "kimiz provides a seamless Wine gaming experience with embedded Wine, eliminating the need for complex setup. Just connect your Steam account and start playing!"
            )
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
            .lineSpacing(2)

            HStack(spacing: 16) {
                Button(action: { openURL(URL(string: "https://github.com/temidaradev/kimiz")!) }) {
                    Label("GitHub", systemImage: "link.circle.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .buttonStyle(ModernLinkButtonStyle(color: .blue))

                Button(action: {
                    openURL(URL(string: "https://github.com/temidaradev/kimiz/issues")!)
                }) {
                    Label("Support", systemImage: "questionmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .buttonStyle(ModernLinkButtonStyle(color: .green))
            }
        }
    }

    private func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

struct ModernLinkButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
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
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @State private var showingResetAlert = false
    @State private var showingClearCacheAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Refresh Game Library") {
                Task {
                    await embeddedWineManager.scanForInstalledGames()
                }
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
                "This will reset all settings to their defaults. Games will not be affected."
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
        UserDefaults.standard.removeObject(forKey: "enableDebugMode")
        UserDefaults.standard.removeObject(forKey: "autoDetectGames")
        UserDefaults.standard.removeObject(forKey: "enableHUD")
        UserDefaults.standard.removeObject(forKey: "useEsync")
        UserDefaults.standard.removeObject(forKey: "useDXVKAsync")
    }

    private func clearGameCache() {
        Task {
            await embeddedWineManager.scanForInstalledGames()
        }
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
        .environmentObject(EmbeddedWineManager())
}
