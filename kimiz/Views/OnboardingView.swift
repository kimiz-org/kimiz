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

    // Animation states
    @State private var animateBackground = false
    @State private var animateIcon = false
    @State private var animateCards = false
    @State private var particleOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Background
                backgroundView

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        heroSection
                            .frame(height: geometry.size.height * 0.45)

                        // Content Section
                        contentSection
                            .padding(.top, 20)
                    }
                }
                .scrollIndicators(.hidden)

                // Navigation Overlay
                navigationOverlay
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.4),
                    Color.cyan.opacity(0.2),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated particles
            ForEach(0..<15, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 20...80))
                    .position(
                        x: CGFloat.random(in: 0...800),
                        y: CGFloat.random(in: 0...600) + particleOffset
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 15...25))
                            .repeatForever(autoreverses: false),
                        value: particleOffset
                    )
            }
        }
        .onAppear {
            withAnimation {
                particleOffset = -1200
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon with layered animation
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateIcon ? 1.2 : 1.0)
                    .opacity(animateIcon ? 0.8 : 0.4)

                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.white)
                }
                .rotationEffect(.degrees(animateIcon ? 5 : -5))
                .scaleEffect(animateIcon ? 1.05 : 0.95)
            }
            .animation(
                Animation.easeInOut(duration: 3).repeatForever(autoreverses: true),
                value: animateIcon
            )

            // Title and subtitle
            VStack(spacing: 12) {
                Text("kimiz")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

                Text("Play Windows games on your Mac with zero hassle")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 32) {
            // Step Indicator
            stepIndicator

            // Main Content Card
            mainContentCard
                .scaleEffect(animateCards ? 1.0 : 0.95)
                .opacity(animateCards ? 1.0 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateCards)
                .animation(.easeInOut(duration: 0.5), value: currentStep)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 120)  // Space for navigation
    }

    private var stepIndicator: some View {
        HStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { step in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .shadow(
                                color: step <= currentStep ? .blue.opacity(0.3) : .clear, radius: 4)

                        if step < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(step <= currentStep ? .white : .gray)
                        }
                    }

                    if step < 3 {
                        Rectangle()
                            .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 2)
                            .cornerRadius(1)
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private var mainContentCard: some View {
        VStack(spacing: 24) {
            if currentStep == 0 {
                welcomeStepModern
            } else if currentStep == 1 {
                wineSetupStepModern
            } else if currentStep == 2 {
                steamSetupStepModern
            } else {
                completionStepModern
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }

    // MARK: - Step Views

    private var welcomeStepModern: some View {
        VStack(spacing: 24) {
            // Welcome icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            }

            VStack(spacing: 16) {
                Text("Welcome to the future of gaming")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(
                    "kimiz comes with Wine already built-in. No complex setup, no external downloads - just connect your Steam account and start playing!"
                )
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            }

            // Features grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16
            ) {
                FeatureCard(
                    icon: "checkmark.circle.fill",
                    title: "Zero Setup",
                    subtitle: "Wine included",
                    color: .green
                )

                FeatureCard(
                    icon: "gamecontroller.fill",
                    title: "Steam Ready",
                    subtitle: "Auto-install",
                    color: .blue
                )

                FeatureCard(
                    icon: "bolt.fill",
                    title: "Fast Launch",
                    subtitle: "Optimized",
                    color: .orange
                )

                FeatureCard(
                    icon: "shield.fill",
                    title: "Secure",
                    subtitle: "Sandboxed",
                    color: .purple
                )
            }
        }
    }

    private var wineSetupStepModern: some View {
        VStack(spacing: 24) {
            // Wine setup animation
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: isSettingUpWine ? "gearshape.fill" : "cube.box.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                    .rotationEffect(.degrees(isSettingUpWine ? 360 : 0))
                    .animation(
                        isSettingUpWine
                            ? Animation.linear(duration: 2).repeatForever(autoreverses: false)
                            : .default,
                        value: isSettingUpWine
                    )
            }

            VStack(spacing: 16) {
                Text(isSettingUpWine ? "Setting up Wine..." : "Initialize Wine Environment")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(
                    isSettingUpWine
                        ? "Creating your gaming environment with embedded Wine. This will only take a moment..."
                        : "We'll create a fresh Wine environment optimized for gaming."
                )
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            }

            if isSettingUpWine {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.purple)
            }

            // Status cards
            VStack(spacing: 12) {
                StatusCard(
                    title: "Wine Runtime",
                    status: isSettingUpWine ? .inProgress : .pending,
                    icon: "cube.box.fill"
                )

                StatusCard(
                    title: "Gaming Optimizations",
                    status: isSettingUpWine ? .pending : .pending,
                    icon: "speedometer"
                )

                StatusCard(
                    title: "DirectX Components",
                    status: .pending,
                    icon: "display"
                )
            }
        }
    }

    private var steamSetupStepModern: some View {
        VStack(spacing: 24) {
            // Steam icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "cloud.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 16) {
                Text(isSteamInstalled ? "Steam is ready!" : "Install Steam")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(
                    isSteamInstalled
                        ? "Steam has been successfully installed. You can now log in with your Steam account and access your game library."
                        : "We'll automatically download and install Steam in your Wine environment."
                )
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            }

            if !isSteamInstalled {
                Button(action: installSteam) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20))

                        Text("Install Steam")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(animateCards ? 1.0 : 0.95)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateCards)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)

                    Text("Steam Successfully Installed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }

    private var completionStepModern: some View {
        VStack(spacing: 24) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            }

            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(
                    "Your gaming environment is ready. kimiz has successfully set up Wine and Steam. You can now browse and install your favorite Windows games!"
                )
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            }

            // Quick stats
            HStack(spacing: 20) {
                StatCard(number: "1", label: "Wine Environment", color: .purple)
                StatCard(number: "✓", label: "Steam Ready", color: .blue)
                StatCard(number: "∞", label: "Games Available", color: .green)
            }
        }
    }

    // MARK: - Navigation Overlay

    private var navigationOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 16) {
                // Back button
                if currentStep > 0 {
                    Button(action: previousStep) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .frame(height: 48)
                        .frame(minWidth: 80)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }

                Spacer()

                // Next/Done button
                Button(action: nextStep) {
                    HStack(spacing: 8) {
                        Text(nextButtonText)
                            .font(.system(size: 16, weight: .semibold))

                        if currentStep < 3 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(height: 48)
                    .frame(minWidth: 120)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(currentStep == 1 && !embeddedWineManager.isWineReady)
                .disabled(currentStep == 2 && !isSteamInstalled)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Helper Views

    struct FeatureCard: View {
        let icon: String
        let title: String
        let subtitle: String
        let color: Color

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }

    struct StatusCard: View {
        let title: String
        let status: Status
        let icon: String

        enum Status {
            case pending, inProgress, completed

            var color: Color {
                switch self {
                case .pending: return .gray
                case .inProgress: return .blue
                case .completed: return .green
                }
            }

            var systemImage: String {
                switch self {
                case .pending: return "circle"
                case .inProgress: return "circle.fill"
                case .completed: return "checkmark.circle.fill"
                }
            }
        }

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(status.color)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: status.systemImage)
                    .font(.system(size: 14))
                    .foregroundColor(status.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }

    struct StatCard: View {
        let number: String
        let label: String
        let color: Color

        var body: some View {
            VStack(spacing: 8) {
                Text(number)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Actions & Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2)) {
            animateBackground = true
        }

        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            animateIcon = true
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6)) {
            animateCards = true
        }
    }

    private func nextStep() {
        if currentStep == 0 {
            // Start Wine setup
            currentStep = 1
            setupWine()
        } else if currentStep == 1 && embeddedWineManager.isWineReady {
            currentStep = 2
        } else if currentStep == 2 && isSteamInstalled {
            currentStep = 3
        } else if currentStep == 3 {
            // Complete onboarding
            showOnboarding = false
        }
    }

    private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    private var nextButtonText: String {
        switch currentStep {
        case 0: return "Get Started"
        case 1: return embeddedWineManager.isWineReady ? "Continue" : "Setting up..."
        case 2: return isSteamInstalled ? "Continue" : "Next"
        case 3: return "Start Gaming"
        default: return "Next"
        }
    }

    private func setupWine() {
        isSettingUpWine = true

        Task {
            do {
                try await embeddedWineManager.initializeWine()
                await MainActor.run {
                    isSettingUpWine = false
                }
            } catch {
                await MainActor.run {
                    isSettingUpWine = false
                    // Handle error - could show an alert
                    print("Wine setup failed: \(error)")
                }
            }
        }
    }

    private func installSteam() {
        Task {
            do {
                try await embeddedWineManager.installSteam()
                await MainActor.run {
                    isSteamInstalled = true
                }
            } catch {
                await MainActor.run {
                    // Handle error
                    print("Steam installation failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(EmbeddedWineManager())
}
