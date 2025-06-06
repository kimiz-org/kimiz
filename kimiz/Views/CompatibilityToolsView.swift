//
//  CompatibilityToolsView.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
//

import Foundation
import SwiftUI

struct CompatibilityToolsView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @Binding var isPresented: Bool

    @State private var installedTools: [CompatibilityTool] = []
    @State private var isInstalling = false
    @State private var installationProgress: Double = 0.0
    @State private var currentInstallation = ""

    struct CompatibilityTool {
        let id = UUID()
        let name: String
        let description: String
        let category: ToolCategory
        var isInstalled: Bool
        let downloadSize: String
        let benefits: [String]

        enum ToolCategory: String, CaseIterable {
            case directx = "DirectX Translation"
            case vulkan = "Vulkan Drivers"
            case runtime = "Runtime Libraries"
            case codecs = "Media Codecs"
            case fonts = "Windows Fonts"
        }
    }

    let availableTools: [CompatibilityTool] = [
        CompatibilityTool(
            name: "DXVK",
            description: "DirectX 9/10/11 to Vulkan translation layer",
            category: .directx,
            isInstalled: false,
            downloadSize: "15 MB",
            benefits: ["Better performance", "Reduced CPU usage", "Modern graphics API"]
        ),
        CompatibilityTool(
            name: "VKD3D-Proton",
            description: "DirectX 12 to Vulkan translation",
            category: .directx,
            isInstalled: false,
            downloadSize: "25 MB",
            benefits: ["DirectX 12 support", "Latest games compatibility", "Ray tracing support"]
        ),
        CompatibilityTool(
            name: "Visual C++ Redistributables",
            description: "Microsoft Visual C++ runtime libraries",
            category: .runtime,
            isInstalled: true,
            downloadSize: "45 MB",
            benefits: ["Essential for most games", "Required dependencies", "Multiple versions"]
        ),
        CompatibilityTool(
            name: ".NET Framework",
            description: "Microsoft .NET runtime environment",
            category: .runtime,
            isInstalled: false,
            downloadSize: "65 MB",
            benefits: ["Managed code support", "Framework dependencies", "C# applications"]
        ),
        CompatibilityTool(
            name: "Windows Media Codecs",
            description: "Audio and video codec pack",
            category: .codecs,
            isInstalled: false,
            downloadSize: "12 MB",
            benefits: ["Video playback", "Audio support", "Cutscene compatibility"]
        ),
        CompatibilityTool(
            name: "Windows Fonts",
            description: "Core Windows font collection",
            category: .fonts,
            isInstalled: false,
            downloadSize: "35 MB",
            benefits: ["Text rendering", "UI compatibility", "Better readability"]
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Installation Progress
                    if isInstalling {
                        installationProgressView
                    }

                    // Tool Categories
                    ForEach(CompatibilityTool.ToolCategory.allCases, id: \.self) { category in
                        toolCategorySection(category)
                    }

                    // Quick Actions
                    quickActionsSection
                }
                .padding(24)
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 800, height: 700)
        .background(.regularMaterial)
        .onAppear {
            loadInstalledTools()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Compatibility Tools")
                    .font(.headline)

                Text("Install and configure tools for better Windows software compatibility")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Close") {
                isPresented = false
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var installationProgressView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Installing: \(currentInstallation)")
                    .font(.headline)
                Spacer()
                Text("\(Int(installationProgress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: installationProgress)
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func toolCategorySection(_ category: CompatibilityTool.ToolCategory) -> some View {
        let categoryTools = availableTools.filter { $0.category == category }

        return VStack(alignment: .leading, spacing: 16) {
            Text(category.rawValue)
                .font(.title2)
                .fontWeight(.semibold)

            LazyVStack(spacing: 12) {
                ForEach(categoryTools, id: \.id) { tool in
                    CompatibilityToolCard(tool: tool, isInstalling: isInstalling) {
                        installTool(tool)
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gaming Essentials for GPTK")
                            .font(.headline)
                        Text("DXVK, VKD3D, Visual C++, and Windows Fonts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Install Bundle") {
                        installGamingEssentials()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Cleanup")
                            .font(.headline)
                        Text("Clean temporary files and reset Wine prefixes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Clean System") {
                        performSystemCleanup()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isInstalling)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }

    private var footerView: some View {
        HStack {
            Text("Tools will be installed to the default Wine prefix")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func loadInstalledTools() {
        // Mock checking for installed tools
        // In a real implementation, this would check the actual Wine prefix
    }

    private func installTool(_ tool: CompatibilityTool) {
        guard !isInstalling else { return }

        isInstalling = true
        currentInstallation = tool.name
        installationProgress = 0.0

        Task {
            do {
                // Simulate installation progress
                for i in 1...10 {
                    await MainActor.run {
                        installationProgress = Double(i) / 10.0
                    }
                    try await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds
                }

                // Actually install the component
                if let bottle = gamePortingToolkitManager.selectedBottle {
                    try await gamePortingToolkitManager.installDependency(
                        tool.name.lowercased().replacingOccurrences(of: " ", with: ""),
                        for: bottle
                    )
                } else {
                    print("No bottle selected, cannot install \(tool.name)")
                }

                await MainActor.run {
                    isInstalling = false
                    installationProgress = 0.0
                    currentInstallation = ""
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    installationProgress = 0.0
                    currentInstallation = ""
                    print("Failed to install \(tool.name): \(error)")
                }
            }
        }
    }

    private func installGamingEssentials() {
        guard !isInstalling else { return }

        let essentialTools = ["dxvk", "vkd3d", "vcrun2019", "corefonts"]

        isInstalling = true
        currentInstallation = "Gaming Essentials"

        Task {
            for (index, tool) in essentialTools.enumerated() {
                await MainActor.run {
                    installationProgress = Double(index) / Double(essentialTools.count)
                    currentInstallation = "Installing \(tool)..."
                }

                do {
                    if let bottle = gamePortingToolkitManager.selectedBottle {
                        try await gamePortingToolkitManager.installDependency(
                            tool,
                            for: bottle
                        )
                    } else {
                        print("No bottle selected, cannot install \(tool)")
                    }
                } catch {
                    print("Failed to install \(tool): \(error)")
                }

                try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            }

            await MainActor.run {
                isInstalling = false
                installationProgress = 0.0
                currentInstallation = ""
            }
        }
    }

    private func performSystemCleanup() {
        // Implement system cleanup
        print("System cleanup would be performed here")
    }
}

struct CompatibilityToolCard: View {
    let tool: CompatibilityToolsView.CompatibilityTool
    let isInstalling: Bool
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Tool Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tool.isInstalled ? .green.opacity(0.2) : .blue.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: tool.isInstalled ? "checkmark.circle.fill" : toolIcon)
                    .font(.system(size: 24))
                    .foregroundColor(tool.isInstalled ? .green : .blue)
            }

            // Tool Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.headline)

                Text(tool.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text(tool.downloadSize)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(tool.benefits.prefix(2), id: \.self) { benefit in
                            Text(benefit)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            // Action Button
            if tool.isInstalled {
                Button("Installed") {
                    // Could show reinstall options
                }
                .buttonStyle(.bordered)
                .disabled(true)
            } else {
                Button("Install") {
                    onInstall()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstalling)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var toolIcon: String {
        switch tool.category {
        case .directx:
            return "display"
        case .vulkan:
            return "cpu"
        case .runtime:
            return "gear"
        case .codecs:
            return "play.rectangle"
        case .fonts:
            return "textformat"
        }
    }
}

#Preview {
    CompatibilityToolsView(isPresented: Binding.constant(true))
        .environmentObject(GamePortingToolkitManager.shared)
}
