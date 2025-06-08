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
    @EnvironmentObject var bottleManager: BottleManager
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
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [.black, .gray.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern header
                modernHeaderView

                // Content with glassmorphism
                ScrollView {
                    VStack(spacing: 24) {
                        // Installation Progress
                        if isInstalling {
                            modernInstallationProgressView
                        }

                        // Tool Categories
                        ForEach(CompatibilityTool.ToolCategory.allCases, id: \.self) { category in
                            modernToolCategorySection(category)
                        }

                        // Quick Actions
                        modernQuickActionsSection
                    }
                    .padding(24)
                }

                // Modern footer
                modernFooterView
            }
        }
        .frame(width: 800, height: 700)
        .onAppear {
            loadInstalledTools()
        }
    }

    private var modernHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Compatibility Tools")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Install and configure tools for better Windows software compatibility")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button("Close") {
                isPresented = false
            }
            .buttonStyle(.borderless)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(24)
    }

    private var modernInstallationProgressView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gear.badge")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Installing: \(currentInstallation)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(Int(installationProgress * 100))% complete")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            ProgressView(value: installationProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(20)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func modernToolCategorySection(_ category: CompatibilityTool.ToolCategory) -> some View
    {
        let categoryTools = availableTools.filter { $0.category == category }

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcon(for: category))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)

                Text(category.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            LazyVStack(spacing: 12) {
                ForEach(categoryTools, id: \.id) { tool in
                    ModernCompatibilityToolCard(tool: tool, isInstalling: isInstalling) {
                        installTool(tool)
                    }
                }
            }
        }
        .padding(20)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var modernQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)

                Text("Quick Actions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                // Gaming Essentials Bundle
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gaming Essentials for GPTK")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("DXVK, VKD3D, Visual C++, and Windows Fonts")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button("Install Bundle") {
                        installGamingEssentials()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .disabled(isInstalling)
                    .opacity(isInstalling ? 0.6 : 1.0)
                }
                .padding(16)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

                // System Cleanup
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Cleanup")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Clean temporary files and reset Wine prefixes")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button("Clean System") {
                        performSystemCleanup()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .disabled(isInstalling)
                    .opacity(isInstalling ? 0.6 : 1.0)
                }
                .padding(16)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var modernFooterView: some View {
        HStack {
            Text("Tools will be installed to the default Wine prefix")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderless)
            .foregroundColor(.white)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .padding(24)
    }

    private func categoryIcon(for category: CompatibilityTool.ToolCategory) -> String {
        switch category {
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
                if let bottle = bottleManager.selectedBottle {
                    try await bottleManager.installDependency(
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
                    if let bottle = bottleManager.selectedBottle {
                        try await bottleManager.installDependency(
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

struct ModernCompatibilityToolCard: View {
    let tool: CompatibilityToolsView.CompatibilityTool
    let isInstalling: Bool
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Tool Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tool.isInstalled ? .green.opacity(0.2) : .blue.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: tool.isInstalled ? "checkmark.circle.fill" : toolIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(tool.isInstalled ? .green : .blue)
            }

            // Tool Info
            VStack(alignment: .leading, spacing: 6) {
                Text(tool.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(tool.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)

                HStack {
                    Text(tool.downloadSize)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    HStack(spacing: 6) {
                        ForEach(tool.benefits.prefix(2), id: \.self) { benefit in
                            Text(benefit)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    .white.opacity(0.1), in: RoundedRectangle(cornerRadius: 4)
                                )
                                .foregroundColor(.white.opacity(0.8))
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
                .buttonStyle(.borderless)
                .foregroundColor(.green)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                .disabled(true)
            } else {
                Button("Install") {
                    onInstall()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.white)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .disabled(isInstalling)
                .opacity(isInstalling ? 0.6 : 1.0)
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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
        .environmentObject(BottleManager.shared)
}
