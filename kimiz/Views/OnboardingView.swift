//
//  OnboardingView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI
import Foundation

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
                VStack(spacing: 40) {
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
                            .frame(maxWidth: 560, maxHeight: 480)

                        if gamePortingToolkitManager.isGPTKInstalled {
                            successView
                        } else if isInstalling || gamePortingToolkitManager.isInstallingComponents {
                            installingView
                        } else if let error = installationError {
                            errorView(error)
                        } else {
                            setupRequiredView
                        }
                    }

                    Spacer()
                }
                .padding(40)
            }
        }
        .onAppear {
            if !hasCheckedInitialState {
                checkInitialStateAndSetup()
                hasCheckedInitialState = true
            }
        }
    }

    // MARK: - Views
    private var modernHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("kimiz")
                    .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()
            }

            HStack {
                Text("Windows Gaming on Mac")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }
        }
        .padding(.top, 20)
    }

    private var successView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.green)
                    .symbolEffect(.pulse.byLayer)

                VStack(spacing: 12) {
                    Text("Ready to Game!")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Game Porting Toolkit is installed and ready to use.")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            Button("Continue to kimiz") {
                completeOnboarding()
            }
            .buttonStyle(ModernButtonStyle(color: .green))
        }
        .frame(maxWidth: 440)
        .padding(.vertical, 32)
    }

    private var installingView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "gear.badge")
                    .font(.system(size: 72))
                    .foregroundColor(.cyan)
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))

                VStack(spacing: 12) {
                    Text("Installing Game Porting Toolkit")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("This may take several minutes. Please keep the app open.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 20) {
                ProgressView(value: gamePortingToolkitManager.installationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                    .frame(maxWidth: 300)

                Text(gamePortingToolkitManager.installationStatus)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 440)
        .padding(.vertical, 32)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.orange)

                VStack(spacing: 12) {
                    Text("Installation Failed")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(error)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 16) {
                Button("Try Again") {
                    retryInstallation()
                }
                .buttonStyle(ModernButtonStyle(color: .cyan))

                Button("Manual Setup Guide") {
                    if let url = URL(string: "https://developer.apple.com/documentation/gameportingtoolkit") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(ModernButtonStyle(color: .gray, style: .secondary))
            }
        }
        .frame(maxWidth: 440)
        .padding(.vertical, 32)
    }

    private var setupRequiredView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))

                VStack(spacing: 12) {
                    Text("Welcome to kimiz")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Game Porting Toolkit is required to run Windows games on your Mac.")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 16) {
                Button("Install Game Porting Toolkit") {
                    startInstallation()
                }
                .buttonStyle(ModernButtonStyle(color: .cyan))

                Button("Manual Installation Guide") {
                    if let url = URL(string: "https://developer.apple.com/documentation/gameportingtoolkit") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(ModernButtonStyle(color: .gray, style: .secondary))
            }
        }
        .frame(maxWidth: 440)
        .padding(.vertical, 32)
    }

    // MARK: - Actions
    private func checkInitialStateAndSetup() {
        if gamePortingToolkitManager.isGPTKInstalled {
            // GPTK is already installed, close onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completeOnboarding()
            }
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
                    installationError = "Homebrew is required. Please install Homebrew first from https://brew.sh"
                    if let url = URL(string: "https://brew.sh") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } catch GPTKError.rosettaRequired {
                await MainActor.run {
                    gamePortingToolkitManager.isInstallingComponents = false
                    isInstalling = false
                    installationError = "Rosetta 2 is required on Apple Silicon Macs. Please run: softwareupdate --install-rosetta"
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
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(GamePortingToolkitManager.shared)
}
