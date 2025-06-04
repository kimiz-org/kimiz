//
//  OnboardingView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @State private var currentStep = 0
    @State private var isSettingUpWine = false
    @Binding var showOnboarding: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Spacer()

            // Main content
            if currentStep == 0 {
                welcomeView
            } else if currentStep == 1 {
                wineSetupView
            } else {
                steamSetupView
            }

            Spacer()

            // Footer with navigation
            footerView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("kimiz")
                .font(.system(size: 36, weight: .thin, design: .rounded))
                .foregroundColor(.primary)

            Text("Windows Gaming on Mac")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }

    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Welcome to kimiz")
                    .font(.system(size: 24, weight: .medium))

                Text(
                    "Play Windows games on your Mac with ease.\nLet's get you set up in just a few steps."
                )
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            }
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Wine Setup View
    private var wineSetupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "gear.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Setting up Wine")
                    .font(.system(size: 24, weight: .medium))

                if embeddedWineManager.isInitializing {
                    VStack(spacing: 16) {
                        ProgressView(value: embeddedWineManager.initializationProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(maxWidth: 300)

                        Text(embeddedWineManager.initializationStatus)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else if embeddedWineManager.isInstallingComponents {
                    VStack(spacing: 16) {
                        ProgressView(value: embeddedWineManager.initializationProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(maxWidth: 300)

                        Text("Installing \(embeddedWineManager.installationComponentName)...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text("This may take several minutes. Do not close the application.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                } else if embeddedWineManager.isWineReady {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Wine is ready!")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                } else if embeddedWineManager.lastError != nil {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Setup Required")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }

                        Text(
                            "Wine is not installed. Would you like to automatically install Game Porting Toolkit?"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                        VStack(spacing: 12) {
                            Button("Install Automatically") {
                                Task {
                                    try? await embeddedWineManager.installRequiredComponents()
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            Text(
                                "This will check for and install only the components that aren't already present"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                            .padding(.bottom, 4)

                            Button("Manual Installation Instructions") {
                                if let url = URL(
                                    string:
                                        "https://developer.apple.com/documentation/gameportingtoolkit"
                                ) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 4)
                    }
                } else {
                    Button("Check Wine Installation") {
                        Task {
                            await embeddedWineManager.checkWineInstallation()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Steam Setup View
    private var steamSetupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "cloud.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Install Steam for Windows")
                    .font(.system(size: 24, weight: .medium))

                Text(
                    "Would you like to install Steam for Windows?\nThis will give you access to your Windows game library on Mac."
                )
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

                if isSettingUpWine {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.bottom, 4)

                        Text("Downloading and installing Steam...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text("This may take a few minutes")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))

                            Text("Steam will allow you to:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text("Access your existing Windows game library")
                            }

                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text("Install and play Windows-only games")
                            }

                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text("Purchase new Windows games")
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 2)
                    }
                    .padding(.top, 6)

                    HStack(spacing: 16) {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .buttonStyle(.bordered)

                        Button("Install Steam") {
                            installSteam()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSettingUpWine)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3)
                        )
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            if currentStep < 2 && (currentStep == 0 || embeddedWineManager.isWineReady) {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
    }

    // MARK: - Actions
    private func installSteam() {
        isSettingUpWine = true
        Task {
            do {
                try await embeddedWineManager.installSteam()
                await MainActor.run {
                    completeOnboarding()
                }
            } catch {
                await MainActor.run {
                    isSettingUpWine = false
                    // Show error - could add error state here
                }
            }
        }
    }

    private func completeOnboarding() {
        showOnboarding = false
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(EmbeddedWineManager())
}
