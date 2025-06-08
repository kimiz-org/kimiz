//
//  InstallationWizardView.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
//

import AppKit
import Foundation
import SwiftUI

struct InstallationWizardView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var bottleManager: BottleManager
    @Binding var isPresented: Bool

    @State private var currentStep = 0
    @State private var selectedGameTemplate: GameTemplate?
    @State private var selectedExecutable: URL?
    @State private var installationPath = ""
    @State private var gameName = ""
    @State private var enableDXVK = true
    @State private var enableEsync = true
    @State private var selectedBottle = "Default"
    @State private var isInstalling = false
    @State private var installationProgress = 0.0

    let gameTemplates: [GameTemplate] = [
        GameTemplate(
            name: "Modern AAA Game",
            description: "Optimized for GPTK with games like Cyberpunk 2077, Witcher 3, etc.",
            icon: "gamecontroller.fill",
            recommendedSettings: GameTemplate.RecommendedSettings(
                dxvk: true,
                esync: true,
                windowMode: "fullscreen",
                additionalDLLs: ["d3d11", "dxgi"]
            ),
            requiredComponents: ["dxvk", "vcrun2019", "d3d11"]
        ),
        GameTemplate(
            name: "Indie/2D Game",
            description: "GPTK-optimized for smaller games and 2D titles",
            icon: "star.fill",
            recommendedSettings: GameTemplate.RecommendedSettings(
                dxvk: false,
                esync: true,
                windowMode: "windowed",
                additionalDLLs: []
            ),
            requiredComponents: ["vcrun2019"]
        ),
        GameTemplate(
            name: "Retro Game",
            description: "GPTK settings for older games and classics",
            icon: "tv.fill",
            recommendedSettings: GameTemplate.RecommendedSettings(
                dxvk: false,
                esync: false,
                windowMode: "windowed",
                additionalDLLs: ["ddraw", "dsound"]
            ),
            requiredComponents: ["vcrun2019", "d3dx9"]
        ),
        GameTemplate(
            name: "Office Application",
            description: "GPTK configuration for productivity software",
            icon: "doc.text.fill",
            recommendedSettings: GameTemplate.RecommendedSettings(
                dxvk: false,
                esync: false,
                windowMode: "windowed",
                additionalDLLs: ["riched20", "riched32"]
            ),
            requiredComponents: ["vcrun2019", "dotnet48"]
        ),
        GameTemplate(
            name: "Custom Configuration",
            description: "Configure GPTK settings manually",
            icon: "slider.horizontal.3",
            recommendedSettings: GameTemplate.RecommendedSettings(
                dxvk: false,
                esync: false,
                windowMode: "windowed",
                additionalDLLs: []
            ),
            requiredComponents: []
        ),
    ]

    let steps = [
        "Choose Template",
        "Select Executable",
        "Configure Settings",
        "Install & Setup",
    ]

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

            VStack(spacing: 0) {
                // Modern header
                modernHeaderView

                // Step content with glass morphism
                VStack(spacing: 0) {
                    modernStepContentView

                    // Modern footer
                    modernFooterView
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 800, height: 700)
    }

    private var modernHeaderView: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Installation Wizard")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(.borderless)
            }

            // Modern progress indicator
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        HStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(
                                        index <= currentStep ? Color.blue : Color.white.opacity(0.3)
                                    )
                                    .frame(width: 16, height: 16)

                                if index < currentStep {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                } else if index == currentStep {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 8, height: 8)
                                }
                            }

                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(
                                        index < currentStep ? Color.blue : Color.white.opacity(0.3)
                                    )
                                    .frame(height: 2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Text(steps[index])
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(index <= currentStep ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var modernStepContentView: some View {
        ScrollView {
            VStack(spacing: 32) {
                switch currentStep {
                case 0:
                    modernTemplateSelectionStep
                case 1:
                    modernExecutableSelectionStep
                case 2:
                    modernConfigurationStep
                case 3:
                    modernInstallationStep
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
        }
        .frame(maxHeight: 400)
    }

    private var modernTemplateSelectionStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Application Template")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(
                    "Select a template that best matches your application type for optimal GPTK configuration"
                )
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 16) {
                ForEach(gameTemplates, id: \.id) { template in
                    ModernGameTemplateCard(
                        template: template,
                        isSelected: selectedGameTemplate?.id == template.id
                    ) {
                        selectedGameTemplate = template
                        if let settings = selectedGameTemplate?.recommendedSettings {
                            enableDXVK = settings.dxvk
                            enableEsync = settings.esync
                        }
                    }
                }
            }
        }
    }

    private var modernExecutableSelectionStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Windows Executable")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Choose the Windows .exe file you want to install and run with GPTK")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }

            if let executable = selectedExecutable {
                // Selected executable display
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "doc.badge.gearshape.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(executable.lastPathComponent)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text(executable.path)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                            )
                    )

                    Button {
                        selectExecutable()
                    } label: {
                        Text("Choose Different File")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.borderless)
                }
            } else {
                // File selection area
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        VStack(spacing: 8) {
                            Text("No executable selected")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Click below to browse for a Windows .exe file")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Button {
                        selectExecutable()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.system(size: 16, weight: .medium))
                            Text("Browse for Executable")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var modernConfigurationStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Configure Installation")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Customize settings for optimal performance with your application")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }

            VStack(spacing: 20) {
                // Game name input
                ModernSectionView(title: "Application Details") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Application Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Enter application name", text: $gameName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
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
                }

                // Performance settings
                ModernSectionView(title: "Performance Settings") {
                    VStack(spacing: 16) {
                        ModernToggleRow(
                            title: "Enable DXVK",
                            subtitle: "DirectX to Vulkan translation layer for better performance",
                            isOn: $enableDXVK
                        )

                        ModernToggleRow(
                            title: "Enable Esync",
                            subtitle: "Event synchronization for improved compatibility",
                            isOn: $enableEsync
                        )
                    }
                }

                // Bottle selection
                ModernSectionView(title: "Bottle Configuration") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Bottle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        Menu {
                            Button("Default") { selectedBottle = "Default" }
                            Button("Gaming") { selectedBottle = "Gaming" }
                            Button("Create New...") { selectedBottle = "New" }
                        } label: {
                            HStack {
                                Text(selectedBottle)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
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
                    }
                }
            }
        }
    }

    private var modernInstallationStep: some View {
        VStack(spacing: 32) {
            if isInstalling {
                // Installation in progress
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)

                        Text("Installing Application...")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Setting up GPTK environment and configuring application")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        ProgressView(value: installationProgress)
                            .tint(.blue)
                            .scaleEffect(y: 2)

                        Text("\(Int(installationProgress * 100))% Complete")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(40)
            } else {
                // Installation summary
                VStack(alignment: .leading, spacing: 24) {
                    Text("Ready to Install")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    VStack(spacing: 16) {
                        InstallationSummaryRow(
                            label: "Application",
                            value: gameName.isEmpty
                                ? selectedExecutable?.lastPathComponent ?? "Unknown" : gameName
                        )
                        InstallationSummaryRow(
                            label: "Template",
                            value: selectedGameTemplate?.name ?? "None"
                        )
                        InstallationSummaryRow(
                            label: "Bottle",
                            value: selectedBottle
                        )
                        InstallationSummaryRow(
                            label: "DXVK",
                            value: enableDXVK ? "Enabled" : "Disabled"
                        )
                        InstallationSummaryRow(
                            label: "Esync",
                            value: enableEsync ? "Enabled" : "Disabled"
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    private var modernFooterView: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            if currentStep < steps.count - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.borderless)
                .disabled(!canContinue)
            } else {
                Button {
                    startInstallation()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Install")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.borderless)
                .disabled(isInstalling || !canInstall)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        switch currentStep {
        case 0:
            return selectedGameTemplate != nil
        case 1:
            return selectedExecutable != nil
        case 2:
            return !gameName.isEmpty
        default:
            return false
        }
    }

    private var canInstall: Bool {
        return selectedExecutable != nil && !gameName.isEmpty && selectedGameTemplate != nil
    }

    // MARK: - Helper Methods

    private func selectExecutable() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.executable]
        panel.allowsOtherFileTypes = true
        panel.title = "Select Windows Executable"
        panel.message = "Choose a Windows .exe file to install"

        if panel.runModal() == .OK {
            selectedExecutable = panel.url
            if gameName.isEmpty, let url = panel.url {
                gameName = url.deletingPathExtension().lastPathComponent
            }
        }
    }

    private func startInstallation() {
        guard let executable = selectedExecutable else { return }

        isInstalling = true
        installationProgress = 0.0

        Task {
            do {
                // Simulate installation steps
                for i in 1...10 {
                    await MainActor.run {
                        installationProgress = Double(i) / 10.0
                    }
                    try await Task.sleep(nanoseconds: 300_000_000)
                }

                // Create the game
                let game = Game(
                    name: gameName,
                    executablePath: executable.path,
                    installPath: executable.deletingLastPathComponent().path
                )

                await gamePortingToolkitManager.addUserGame(game)

                // Install required components
                if let template = selectedGameTemplate {
                    let bottle =
                        bottleManager.bottles.first {
                            $0.path == bottleManager.getDefaultBottlePath()
                        }
                        ?? BottleManager.Bottle(
                            name: "Default",
                            path: bottleManager.getDefaultBottlePath()
                        )

                    for component in template.requiredComponents {
                        try await bottleManager.installDependency(
                            component, for: bottle)
                    }
                }

                await MainActor.run {
                    isInstalling = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    print("Installation failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    InstallationWizardView(isPresented: Binding.constant(true))
        .environmentObject(GamePortingToolkitManager.shared)
        .environmentObject(BottleManager.shared)
}
