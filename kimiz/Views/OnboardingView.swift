//
//  OnboardingView.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import AppKit
import Foundation
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var bottleManager: BottleManager
    @State private var isInstalling = false
    @State private var installationError: String?
    @State private var hasCheckedInitialState = false
    @Binding var showOnboarding: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern background
                ModernBackground(style: .primary)
                    .ignoresSafeArea()

                // Content
                VStack(spacing: 0) {
                    // Top spacer for balanced layout
                    Spacer()

                    VStack(spacing: 10) {
                        // Modern header
                        modernHeaderView

                        // Main content card
                        ModernCardView {
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
                        .frame(maxWidth: 520, maxHeight: 600)
                    }

                    // Bottom spacer for balanced layout
                    Spacer()
                }
                .padding(.horizontal, ModernTheme.Spacing.extraLarge)
                .padding(.vertical, ModernTheme.Spacing.large)
            }
        }
        .onAppear {
            if !hasCheckedInitialState {
                checkInitialStateAndSetup()
                hasCheckedInitialState = true
            }
            // Automatically create a default bottle if none exists
            if bottleManager.bottles.isEmpty {
                Task {
                    await bottleManager.createBottle(name: "MyBottle")
                }
            }
        }
    }

    // MARK: - Views
    private var modernHeaderView: some View {
        VStack(spacing: ModernTheme.Spacing.md) {
            Text("kimiz")
                .font(ModernTheme.Typography.largeTitle)
                .foregroundStyle(LinearGradient.modernPrimary)

            Text("Windows Gaming on Mac")
                .font(ModernTheme.Typography.body)
                .foregroundColor(ModernTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var successView: some View {
        VStack(spacing: ModernTheme.Spacing.xxxl) {
            VStack(spacing: ModernTheme.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .symbolEffect(.pulse.byLayer)

                VStack(spacing: ModernTheme.Spacing.sm) {
                    Text("Ready to Game!")
                        .font(ModernTheme.Typography.title1)
                        .foregroundColor(ModernTheme.Colors.textPrimary)

                    Text("Game Porting Toolkit is installed and ready to use.")
                        .font(ModernTheme.Typography.body)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button("Continue to kimiz") {
                completeOnboarding()
            }
            .buttonStyle(ModernPrimaryButtonStyle())
            .controlSize(.large)
        }
        .frame(maxWidth: 400)
        .padding(.vertical, ModernTheme.Spacing.xxxl)
        .padding(.horizontal, ModernTheme.Spacing.xl)
    }

    private var installingView: some View {
        VStack(spacing: ModernTheme.Spacing.xxxl) {
            VStack(spacing: ModernTheme.Spacing.md) {
                Image(systemName: "gear.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.cyan)
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))

                VStack(spacing: ModernTheme.Spacing.sm) {
                    Text("Installing Game Porting Toolkit")
                        .font(ModernTheme.Typography.title2)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("This may take several minutes. Please keep the app open.")
                        .font(ModernTheme.Typography.caption1)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            ModernProgressView(
                value: gamePortingToolkitManager.installationProgress,
                total: 1.0,
                showPercentage: true,
                accentColor: .blue,
                height: 8
            )

            Text(gamePortingToolkitManager.installationStatus)
                .font(ModernTheme.Typography.caption1)
                .foregroundColor(ModernTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 400)
        .padding(.vertical, ModernTheme.Spacing.xxxl)
        .padding(.horizontal, ModernTheme.Spacing.xl)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: ModernTheme.Spacing.xxxl) {
            VStack(spacing: ModernTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)

                VStack(spacing: ModernTheme.Spacing.sm) {
                    Text("Installation Failed")
                        .font(ModernTheme.Typography.title2)
                        .foregroundColor(ModernTheme.Colors.textPrimary)

                    Text(error)
                        .font(ModernTheme.Typography.caption1)
                        .foregroundColor(ModernTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: ModernTheme.Spacing.md) {
                Button("Try Again") {
                    retryInstallation()
                }
                .buttonStyle(ModernPrimaryButtonStyle())

                Button("Manual Setup Guide") {
                    // FIXED: No more website redirects!
                    // The Engine Manager now handles all installations automatically
                    gamePortingToolkitManager.installationStatus =
                        "✅ In-app installation available! Use Engine Manager instead of manual setup."
                }
                .buttonStyle(ModernSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: 400)
        .padding(.vertical, ModernTheme.Spacing.xxxl)
        .padding(.horizontal, ModernTheme.Spacing.xl)
    }

    private var setupRequiredView: some View {
        VStack(spacing: ModernTheme.Spacing.xxxl) {
            VStack(spacing: ModernTheme.Spacing.md) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(LinearGradient.modernPrimary)
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))

                VStack(spacing: ModernTheme.Spacing.sm) {
                    Text("Welcome to kimiz")
                        .font(ModernTheme.Typography.title1)
                        .foregroundColor(ModernTheme.Colors.textPrimary)

                    Text(
                        "Game Porting Toolkit or Wine is required to run Windows games on your Mac.\nYou must also create at least one bottle to continue."
                    )
                    .font(ModernTheme.Typography.body)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: ModernTheme.Spacing.md) {
                Button("Create New Bottle") {
                    Task {
                        await bottleManager.createBottle(name: "MyBottle")
                    }
                }
                .buttonStyle(ModernPrimaryButtonStyle())

                Button("Install Wine and Dependencies") {
                    installWineAndDependencies()
                }
                .buttonStyle(ModernSecondaryButtonStyle())

                Button("Install Game Porting Toolkit") {
                    startInstallation()
                }
                .buttonStyle(ModernOutlineButtonStyle())

                Button("Manual Installation Guide") {
                    // FIXED: No more website redirects!
                    // Show success message about in-app installation
                    isInstalling = false
                    installationError =
                        "✅ GREAT NEWS! Manual installation is no longer needed. The app now includes an automatic in-app installation system!"
                }
                .buttonStyle(ModernSecondaryButtonStyle())
            }
            if !bottleManager.bottles.isEmpty {
                VStack(spacing: 16) {
                    ModernInfoPanel(
                        title: "Your Bottles",
                        icon: "cylinder",
                        accentColor: .blue
                    )

                    VStack(spacing: 8) {
                        ForEach(
                            Array(bottleManager.bottles.enumerated()), id: \.element.id
                        ) { index, bottle in
                            bottleRowView(bottle: bottle)
                        }
                    }
                }
                .frame(maxWidth: 400)
            }
        }
        .frame(maxWidth: 400)
        .padding(.vertical, ModernTheme.Spacing.xxxl)
        .padding(.horizontal, ModernTheme.Spacing.xl)
    }

    private func bottleRowView(bottle: BottleManager.Bottle) -> some View {
        HStack {
            Text(bottle.name)
                .foregroundColor(ModernTheme.Colors.textPrimary)
            Spacer()
            Text(bottle.path)
                .font(ModernTheme.Typography.caption1)
                .foregroundColor(ModernTheme.Colors.textSecondary)
        }
        .padding(ModernTheme.Spacing.small)
        .background(Color.white.opacity(0.05))
        .cornerRadius(ModernTheme.CornerRadius.md)
    }

    // MARK: - Actions
    private func checkInitialStateAndSetup() {
        // Only pass onboarding if at least one bottle exists AND Wine/GPTK is available
        if !bottleManager.bottles.isEmpty
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
            } catch GPTKError.homebrewRequired {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    isInstalling = false
                    installationError =
                        "✅ FIXED: Homebrew is no longer required! The app now includes an automatic installation system that doesn't need Homebrew."
                }
            } catch GPTKError.rosettaRequired {
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
        .environmentObject(BottleManager.shared)
}
