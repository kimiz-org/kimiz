//
//  InstallationWizardView.swift
//  kimiz
//
//  Created by GitHub Copilot on 6.06.2025.
//

import Foundation
import SwiftUI

struct InstallationWizardView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
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

    struct GameTemplate {
        let id = UUID()
        let name: String
        let description: String
        let icon: String
        let recommendedSettings: RecommendedSettings
        let requiredComponents: [String]

        struct RecommendedSettings {
            let dxvk: Bool
            let esync: Bool
            let windowMode: String
            let additionalDLLs: [String]
        }
    }

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
        VStack(spacing: 0) {
            // Header with Progress
            headerView

            Divider()

            // Step Content
            stepContentView

            Divider()

            // Navigation Footer
            footerView
        }
        .frame(width: 700, height: 600)
        .background(.regularMaterial)
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Installation Wizard")
                    .font(.headline)

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
            }

            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(index <= currentStep ? .blue : .gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(index == currentStep ? .blue : .clear, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            )

                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? .blue : .gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            Text("Step \(currentStep + 1): \(steps[currentStep])")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    @ViewBuilder
    private var stepContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch currentStep {
                case 0:
                    templateSelectionStep
                case 1:
                    executableSelectionStep
                case 2:
                    configurationStep
                case 3:
                    installationStep
                default:
                    EmptyView()
                }
            }
            .padding(24)
        }
    }

    private var templateSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose a Template")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Select a template that best matches your application type for optimal configuration"
            )
            .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ForEach(gameTemplates, id: \.id) { template in
                    GameTemplateCard(
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

    private var executableSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Executable")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose the Windows executable you want to install")
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                if let executable = selectedExecutable {
                    HStack {
                        Image(systemName: "doc.badge.gearshape")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(executable.lastPathComponent)
                                .font(.headline)
                            Text(executable.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button("Change") {
                            // Show file picker
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)

                    // Auto-fill game name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Application Name")
                            .font(.headline)

                        TextField("Enter application name", text: $gameName)
                            .textFieldStyle(.roundedBorder)
                            .onAppear {
                                if gameName.isEmpty {
                                    gameName = executable.deletingPathExtension().lastPathComponent
                                }
                            }
                    }
                } else {
                    Button("Choose Executable File") {
                        // Show file picker
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }

    private var configurationStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configure Settings")
                .font(.title2)
                .fontWeight(.semibold)

            if let template = selectedGameTemplate {
                HStack {
                    Image(systemName: template.icon)
                        .foregroundColor(.blue)
                    Text("Template: \(template.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }

            VStack(spacing: 16) {
                GroupBox("GPTK Bottle") {
                    Picker("Bottle", selection: $selectedBottle) {
                        Text("Default GPTK").tag("Default")
                        Text("Gaming GPTK").tag("Gaming")
                        Text("Create New...").tag("New")
                    }
                    .pickerStyle(.menu)
                }

                GroupBox("Graphics & Performance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable DXVK (DirectX to Vulkan for GPTK)", isOn: $enableDXVK)
                        Toggle("Enable Esync (GPTK Event Synchronization)", isOn: $enableEsync)
                    }
                }

                if let template = selectedGameTemplate {
                    GroupBox("Required Components") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                            ForEach(template.requiredComponents, id: \.self) { component in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(component)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var installationStep: some View {
        VStack(spacing: 20) {
            if isInstalling {
                VStack(spacing: 16) {
                    Text("Installing \(gameName)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    ProgressView(value: installationProgress)
                        .progressViewStyle(LinearProgressViewStyle())

                    Text("\(Int(installationProgress * 100))% Complete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("Ready to Install")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("All settings have been configured. Click Install to proceed.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var footerView: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    currentStep -= 1
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep < steps.count - 1 {
                Button("Next") {
                    currentStep += 1
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceedToNextStep)
            } else {
                Button(isInstalling ? "Installing..." : "Install") {
                    performInstallation()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstalling || !canProceedToNextStep)
            }
        }
        .padding()
    }

    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0:
            return selectedGameTemplate != nil
        case 1:
            return selectedExecutable != nil && !gameName.isEmpty
        case 2:
            return true
        case 3:
            return selectedExecutable != nil
        default:
            return false
        }
    }

    private func performInstallation() {
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
                    try await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds
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
                        gamePortingToolkitManager.bottles.first {
                            $0.path == gamePortingToolkitManager.getDefaultBottlePath()
                        }
                        ?? GamePortingToolkitManager.Bottle(
                            name: "Default", path: gamePortingToolkitManager.getDefaultBottlePath())

                    for component in template.requiredComponents {
                        try await gamePortingToolkitManager.installDependency(
                            component,
                            for: bottle
                        )
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

struct GameTemplateCard: View {
    let template: InstallationWizardView.GameTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: template.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .blue)

                Text(template.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(template.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InstallationWizardView(isPresented: Binding.constant(true))
        .environmentObject(GamePortingToolkitManager.shared)
}
