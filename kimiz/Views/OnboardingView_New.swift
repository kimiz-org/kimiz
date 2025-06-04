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
    @State private var isSteamInstalled = false
    @Binding var showOnboarding: Bool

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section with Gradient Background
                        VStack(spacing: 0) {
                            // Animated background particles
                            ZStack {
                                // Main gradient background
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.1),
                                        Color.accentColor.opacity(0.05),
                                        Color.clear,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(height: 350)

                                // Floating particles effect
                                ForEach(0..<15, id: \.self) { index in
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: CGFloat.random(in: 4...12))
                                        .position(
                                            x: CGFloat.random(in: 0...geometry.size.width),
                                            y: CGFloat.random(in: 0...350)
                                        )
                                        .animation(
                                            .easeInOut(duration: Double.random(in: 3...6))
                                                .repeatForever(autoreverses: true)
                                                .delay(Double.random(in: 0...2)),
                                            value: currentStep
                                        )
                                }

                                // Main hero content
                                VStack(spacing: 32) {
                                    Spacer()

                                    // Icon with multiple layers and animations
                                    ZStack {
                                        // Outer glow
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        .accentColor.opacity(0.3),
                                                        .accentColor.opacity(0.1),
                                                        .clear,
                                                    ],
                                                    center: .center,
                                                    startRadius: 30,
                                                    endRadius: 80
                                                )
                                            )
                                            .frame(width: 160, height: 160)
                                            .scaleEffect(currentStep == 0 ? 1.2 : 1.0)
                                            .animation(
                                                .easeInOut(duration: 2).repeatForever(
                                                    autoreverses: true), value: currentStep)

                                        // Middle ring
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        .accentColor.opacity(0.4),
                                                        .accentColor.opacity(0.2),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                            .frame(width: 100, height: 100)
                                            .rotationEffect(.degrees(currentStep == 0 ? 360 : 0))
                                            .animation(
                                                .linear(duration: 8).repeatForever(
                                                    autoreverses: false), value: currentStep)

                                        // Inner icon
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.system(size: 42, weight: .medium))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [
                                                        .accentColor, .accentColor.opacity(0.7),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .scaleEffect(currentStep == 0 ? 1.1 : 1.0)
                                            .animation(
                                                .spring(response: 0.6, dampingFraction: 0.8),
                                                value: currentStep)
                                    }

                                    // Title and subtitle
                                    VStack(spacing: 16) {
                                        Text("kimiz")
                                            .font(
                                                .system(size: 48, weight: .black, design: .rounded)
                                            )
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.primary, .primary.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .textCase(.lowercase)

                                        Text(
                                            "Transform your Mac into the ultimate Windows gaming machine"
                                        )
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .padding(.horizontal, 40)
                                    }

                                    Spacer()
                                }
                            }
                        }

                        // Step Indicator with Modern Design
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { step in
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .fill(
                                            step <= currentStep
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.secondary.opacity(0.1)
                                        )
                                        .frame(width: 40, height: 40)

                                    // Progress circle
                                    Circle()
                                        .stroke(
                                            step <= currentStep
                                                ? Color.accentColor : Color.secondary.opacity(0.3),
                                            lineWidth: step == currentStep ? 3 : 2
                                        )
                                        .frame(width: 40, height: 40)

                                    // Step number or checkmark
                                    if step < currentStep {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Text("\(step + 1)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(
                                                step == currentStep ? .accentColor : .secondary)
                                    }
                                }
                                .scaleEffect(step == currentStep ? 1.1 : 1.0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8), value: currentStep
                                )

                                // Connector line
                                if step < 3 {
                                    Rectangle()
                                        .fill(
                                            step < currentStep
                                                ? Color.accentColor : Color.secondary.opacity(0.3)
                                        )
                                        .frame(width: 40, height: 3)
                                        .clipShape(Capsule())
                                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                                }
                            }
                        }
                        .padding(.vertical, 40)

                        // Main Content Area with Cards
                        VStack(spacing: 40) {
                            Group {
                                if currentStep == 0 {
                                    welcomeStep
                                } else if currentStep == 1 {
                                    wineSetupStep
                                } else if currentStep == 2 {
                                    steamSetupStep
                                } else {
                                    completionStep
                                }
                            }
                            .padding(.horizontal, 40)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                        }
                        .frame(minHeight: 400)

                        Spacer(minLength: 60)

                        // Enhanced Action Buttons
                        VStack(spacing: 24) {
                            HStack(spacing: 20) {
                                // Back button
                                if currentStep > 0 {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8))
                                        {
                                            currentStep -= 1
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Back")
                                                .fontWeight(.medium)
                                        }
                                        .frame(width: 120, height: 50)
                                        .background(
                                            .quaternary, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }

                                Spacer()

                                // Next/Action button
                                Button(action: nextAction) {
                                    HStack(spacing: 8) {
                                        if nextButtonDisabled {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(
                                                    CircularProgressViewStyle(tint: .white))
                                        }

                                        Text(nextButtonTitle)
                                            .fontWeight(.semibold)

                                        if !nextButtonDisabled {
                                            Image(
                                                systemName: currentStep == 3
                                                    ? "checkmark.circle.fill" : "arrow.right"
                                            )
                                            .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .frame(width: 180, height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: nextButtonDisabled
                                                ? [
                                                    Color.secondary.opacity(0.5),
                                                    Color.secondary.opacity(0.3),
                                                ]
                                                : [
                                                    Color.accentColor,
                                                    Color.accentColor.opacity(0.8),
                                                ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .disabled(nextButtonDisabled)
                            }

                            // Progress bar for Wine setup
                            if currentStep == 1 && embeddedWineManager.isInitializing {
                                VStack(spacing: 12) {
                                    ProgressView(value: embeddedWineManager.initializationProgress)
                                        .progressViewStyle(GradientProgressViewStyle())
                                        .frame(height: 8)

                                    Text(embeddedWineManager.initializationStatus)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .animation(
                                            .easeInOut,
                                            value: embeddedWineManager.initializationStatus)
                                }
                                .frame(maxWidth: 400)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - Enhanced Step Views

    @ViewBuilder
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Text("What makes kimiz special?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 24
            ) {
                FeatureCard(
                    icon: "checkmark.circle.fill",
                    title: "Built-in Wine",
                    description:
                        "No need to install Wine separately - everything is included and optimized",
                    color: .green
                )

                FeatureCard(
                    icon: "gamecontroller.fill",
                    title: "Steam Integration",
                    description: "Connect your Steam account and install games with one click",
                    color: .blue
                )

                FeatureCard(
                    icon: "bolt.fill",
                    title: "Optimized Performance",
                    description: "Pre-configured settings for the best gaming experience on macOS",
                    color: .orange
                )

                FeatureCard(
                    icon: "shield.checkered",
                    title: "Secure & Sandboxed",
                    description: "Isolated Windows environment that doesn't affect your Mac",
                    color: .purple
                )
            }
        }
    }

    @ViewBuilder
    private var wineSetupStep: some View {
        VStack(spacing: 32) {
            Text("Setting up Wine Environment")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            if embeddedWineManager.isInitializing {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: embeddedWineManager.initializationProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.accentColor, .accentColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(
                                .easeInOut, value: embeddedWineManager.initializationProgress)

                        Text("\(Int(embeddedWineManager.initializationProgress * 100))%")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }

                    StatusCard(
                        title: "Please wait...",
                        description: embeddedWineManager.initializationStatus,
                        icon: "gear",
                        color: .blue
                    )
                }
            } else if embeddedWineManager.isWineReady {
                StatusCard(
                    title: "Wine is Ready!",
                    description:
                        "The Windows compatibility layer has been successfully configured.",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            } else {
                StatusCard(
                    title: "Ready to Setup",
                    description:
                        "We'll configure the Windows compatibility layer for you. This process takes a few moments and sets up everything needed to run Windows games.",
                    icon: "play.circle",
                    color: .blue
                )
            }

            if let error = embeddedWineManager.lastError {
                StatusCard(
                    title: "Setup Error",
                    description: error,
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
    }

    @ViewBuilder
    private var steamSetupStep: some View {
        VStack(spacing: 32) {
            Text("Install Steam")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            if isSettingUpWine {
                VStack(spacing: 24) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

                    StatusCard(
                        title: "Installing Steam...",
                        description: "Downloading and configuring Steam for Windows games.",
                        icon: "arrow.down.circle",
                        color: .blue
                    )
                }
            } else if isSteamInstalled {
                StatusCard(
                    title: "Steam Installed!",
                    description:
                        "Steam has been successfully installed. You can now log in with your Steam account and access your game library.",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    StatusCard(
                        title: "Ready to Install Steam",
                        description:
                            "We'll download and install Steam for you. After installation, you can log in with your Steam account and install games from your library.",
                        icon: "play.circle",
                        color: .blue
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var completionStep: some View {
        VStack(spacing: 32) {
            // Celebration animation
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .offset(
                            x: cos(Double(index) * .pi / 4) * 60,
                            y: sin(Double(index) * .pi / 4) * 60
                        )
                        .scaleEffect(currentStep == 3 ? 1.0 : 0.1)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                            value: currentStep
                        )
                }

                Image(systemName: "party.popper.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("kimiz is ready to transform your gaming experience")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                QuickActionCard(
                    icon: "gamecontroller.fill",
                    title: "Launch Steam",
                    description: "Log in and access your game library"
                )

                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Install Games",
                    description: "Add games from Steam or other sources"
                )

                QuickActionCard(
                    icon: "gearshape.fill",
                    title: "Customize Settings",
                    description: "Fine-tune your gaming experience"
                )
            }
        }
    }

    // MARK: - Helper Properties

    private var nextButtonTitle: String {
        switch currentStep {
        case 0: return "Get Started"
        case 1: return embeddedWineManager.isWineReady ? "Continue" : "Setup Wine"
        case 2: return isSteamInstalled ? "Continue" : "Install Steam"
        default: return "Launch kimiz"
        }
    }

    private var nextButtonDisabled: Bool {
        switch currentStep {
        case 1: return embeddedWineManager.isInitializing
        case 2: return isSettingUpWine
        default: return false
        }
    }

    // MARK: - Actions

    private func nextAction() {
        switch currentStep {
        case 0:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentStep = 1
            }
        case 1:
            if embeddedWineManager.isWineReady {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentStep = 2
                }
            } else {
                Task {
                    try? await embeddedWineManager.initializeWine()
                }
            }
        case 2:
            if isSteamInstalled {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentStep = 3
                }
            } else {
                installSteam()
            }
        default:
            showOnboarding = false
        }
    }

    private func installSteam() {
        Task {
            isSettingUpWine = true

            do {
                try await embeddedWineManager.installSteam()
                await MainActor.run {
                    isSteamInstalled = true
                    isSettingUpWine = false
                }
            } catch {
                await MainActor.run {
                    isSettingUpWine = false
                    // Handle error - could show alert
                }
            }
        }
    }
}

// MARK: - Custom Components

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatusCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(color)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 2)
        )
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Custom Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GradientProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0)
                    )
                    .clipShape(Capsule())
                    .animation(.easeInOut, value: configuration.fractionCompleted)
            }
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(EmbeddedWineManager())
}
