//
//  OnboardingView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var isInstalling = false
    @State private var installationError: String?
    @State private var hasCheckedInitialState = false
    @Binding var showOnboarding: Bool

    var body: some View {
        GeometryReader { geometry in
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

                // Content
                VStack(spacing: 0) {
                    // Top spacer for balanced layout
                    Spacer()

                    VStack(spacing: 10) {
                        // Modern header
                        modernHeaderView

                        // Main content card
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .frame(maxWidth: 520, maxHeight: 600)

                            if gamePortingToolkitManager.isGPTKInstalled {
                                successView
                            } else if isInstalling
                                || gamePortingToolkitManager.isInstallingComponents
                            {
                                installingView
                            } else if let error = installationError {
                                errorView(error)
                            } else {
                                setupRequiredView
                            }
                        }
                    }

                    // Bottom spacer for balanced layout
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            if !hasCheckedInitialState {
                checkInitialStateAndSetup()
                hasCheckedInitialState = true
            }
            // Automatically create a default bottle if none exists
            if gamePortingToolkitManager.bottles.isEmpty {
                Task {
                    await gamePortingToolkitManager.createBottle(name: "MyBottle")
                }
            }
        }
    }

    // MARK: - Views
    private var modernHeaderView: some View {
        VStack(spacing: 12) {
            Text("kimiz")
                .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Windows Gaming on Mac")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var successView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .symbolEffect(.pulse.byLayer)

                VStack(spacing: 10) {
                    Text("Ready to Game!")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Game Porting Toolkit is installed and ready to use.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            Button("Continue to kimiz") {
                completeOnboarding()
            }
            .buttonStyle(ModernButtonStyle(color: .green))
        }
        .frame(maxWidth: 400)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }

    private var installingView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 18) {
                Image(systemName: "gear.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.cyan)
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))

                VStack(spacing: 10) {
                    Text("Installing Game Porting Toolkit")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("This may take several minutes. Please keep the app open.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 16) {
                ProgressView(value: gamePortingToolkitManager.installationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.cyan))
                    .frame(maxWidth: 280)

                Text(gamePortingToolkitManager.installationStatus)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 400)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 28) {
            VStack(spacing: 18) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)

                VStack(spacing: 10) {
                    Text("Installation Failed")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 12) {
                Button("Try Again") {
                    retryInstallation()
                }
                .buttonStyle(ModernButtonStyle(color: Color.cyan))

                Button("Manual Setup Guide") {
                    if let url = URL(
                        string: "https://developer.apple.com/documentation/gameportingtoolkit")
                    {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(ModernButtonStyle(color: Color.gray, style: .secondary))
            }
        }
        .frame(maxWidth: 400)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }

    private var setupRequiredView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 18) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))

                VStack(spacing: 10) {
                    Text("Welcome to kimiz")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(
                        "Game Porting Toolkit or Wine is required to run Windows games on your Mac.\nYou must also create at least one bottle to continue."
                    )
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 12) {
                Button("Create New Bottle") {
                    Task {
                        await gamePortingToolkitManager.createBottle(name: "MyBottle")
                    }
                }
                .buttonStyle(ModernButtonStyle(color: Color.purple))

                Button("Install Wine and Dependencies") {
                    installWineAndDependencies()
                }
                .buttonStyle(ModernButtonStyle(color: Color.green))

                Button("Install Game Porting Toolkit") {
                    startInstallation()
                }
                .buttonStyle(ModernButtonStyle(color: Color.cyan))

                Button("Manual Installation Guide") {
                    if let url = URL(
                        string: "https://developer.apple.com/documentation/gameportingtoolkit")
                    {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(ModernButtonStyle(color: Color.gray, style: .secondary))
            }
            if !gamePortingToolkitManager.bottles.isEmpty {
                VStack(spacing: 8) {
                    Text("Your Bottles:")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    ForEach(gamePortingToolkitManager.bottles) { bottle in
                        HStack {
                            Text(bottle.name)
                                .foregroundColor(.white)
                            Spacer()
                            Text(bottle.path)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: 400)
            }
        }
        .frame(maxWidth: 400)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }

    // MARK: - Actions
    private func checkInitialStateAndSetup() {
        // Only pass onboarding if at least one bottle exists AND Wine/GPTK is available
        if !gamePortingToolkitManager.bottles.isEmpty
            && gamePortingToolkitManager.isGPTKInstalled
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completeOnboarding()
            }
        } else {
            // Force onboarding to stay open
            showOnboarding = true
        }
    }

    private func startInstallation() {
        installationError = nil
        isInstalling = true

        Task {
            do {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = true
                    gamePortingToolkitManager.installationProgress = 0.1
                    gamePortingToolkitManager.installationStatus = "Starting installation..."
                }

                try await gamePortingToolkitManager.installGamePortingToolkit()

                await MainActor.run {
                    gamePortingToolkitManager.installationProgress = 0.9
                    gamePortingToolkitManager.installationStatus = "Verifying installation..."
                }

                await gamePortingToolkitManager.checkGPTKInstallation()

                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    gamePortingToolkitManager.installationProgress = 1.0
                    gamePortingToolkitManager.installationStatus = "Installation complete"
                    isInstalling = false
                }
            } catch GamePortingToolkitManager.GPTKError.homebrewRequired {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    isInstalling = false
                    installationError =
                        "Homebrew is required. Please install Homebrew first from https://brew.sh"
                    if let url = URL(string: "https://brew.sh") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } catch GamePortingToolkitManager.GPTKError.rosettaRequired {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    isInstalling = false
                    installationError =
                        "Rosetta 2 is required on Apple Silicon Macs. Please run: softwareupdate --install-rosetta"
                }
            } catch {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    isInstalling = false
                    installationError = error.localizedDescription
                }
            }
        }
    }

    private func installWineAndDependencies() {
        installationError = nil
        isInstalling = true
        Task {
            do {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = true
                    gamePortingToolkitManager.installationProgress = 0.1
                    gamePortingToolkitManager.installationStatus = "Starting Wine installation..."
                }
                try await gamePortingToolkitManager.installDependenciesOnly()
                await gamePortingToolkitManager.checkGPTKInstallation()
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    gamePortingToolkitManager.installationProgress = 1.0
                    gamePortingToolkitManager.installationStatus = "Wine and dependencies installed"
                    isInstalling = false
                }
            } catch {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    isInstalling = false
                    installationError = error.localizedDescription
                }
            }
        }
    }

    private func retryInstallation() {
        installationError = nil
        startInstallation()
    }

    private func completeOnboarding() {
        showOnboarding = false
    }
}

#Preview {
    OnboardingView(showOnboarding: Binding.constant(true))
        .environmentObject(GamePortingToolkitManager.shared)
}
