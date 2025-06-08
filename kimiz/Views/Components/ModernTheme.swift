//
//  ModernTheme.swift
//  kimiz
//
//  Created by temidaradev on 7.06.2025.
//

import SwiftUI

// MARK: - Modern Theme System

struct ModernTheme {
    static let shared = ModernTheme()

    // MARK: - Color Palette

    struct Colors {
        // Primary brand colors
        static let primary = Color.blue
        static let secondary = Color.purple
        static let accent = Color.cyan

        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // Background colors
        static let backgroundPrimary = Color(red: 0.05, green: 0.05, blue: 0.1)
        static let backgroundSecondary = Color(red: 0.1, green: 0.1, blue: 0.15)
        static let backgroundTertiary = Color(red: 0.15, green: 0.1, blue: 0.2)

        // Surface colors
        static let surfacePrimary = Color.white.opacity(0.05)
        static let surfaceSecondary = Color.white.opacity(0.1)
        static let surfaceTertiary = Color.white.opacity(0.15)

        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.8)
        static let textTertiary = Color.white.opacity(0.6)
        static let textQuaternary = Color.white.opacity(0.4)
    }

    // MARK: - Typography

    struct Typography {
        // Headlines
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

        // Body text
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption1 = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)

        // Special text styles
        static let buttonLabel = Font.system(size: 17, weight: .semibold)
        static let navigationTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let small: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let medium: CGFloat = 12
        static let lg: CGFloat = 16
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let extraLarge: CGFloat = 32
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 999
    }

    // MARK: - Shadows

    struct Shadow {
        static let small = (
            color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2)
        )
        static let medium = (
            color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4)
        )
        static let large = (
            color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8)
        )
        static let glow = (
            color: Color.blue.opacity(0.3), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(0)
        )
    }

    // MARK: - Animation

    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
}

// MARK: - Modern Gradient Styles

extension LinearGradient {
    static let modernPrimary = LinearGradient(
        colors: [ModernTheme.Colors.primary, ModernTheme.Colors.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let modernBackground = LinearGradient(
        colors: [
            ModernTheme.Colors.backgroundPrimary,
            ModernTheme.Colors.backgroundSecondary,
            ModernTheme.Colors.backgroundTertiary,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let modernSurface = LinearGradient(
        colors: [
            ModernTheme.Colors.surfaceSecondary,
            ModernTheme.Colors.surfacePrimary,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let modernAccent = LinearGradient(
        colors: [ModernTheme.Colors.accent, ModernTheme.Colors.primary],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let modernSuccess = LinearGradient(
        colors: [ModernTheme.Colors.success, ModernTheme.Colors.success.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let modernWarning = LinearGradient(
        colors: [ModernTheme.Colors.warning, ModernTheme.Colors.warning.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let modernError = LinearGradient(
        colors: [ModernTheme.Colors.error, ModernTheme.Colors.error.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Modern View Modifiers

struct ModernCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Bool

    init(cornerRadius: CGFloat = ModernTheme.CornerRadius.lg, shadow: Bool = true) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ModernTheme.Colors.surfaceTertiary, lineWidth: 1)
            )
            .shadow(
                color: shadow ? ModernTheme.Shadow.medium.color : .clear,
                radius: shadow ? ModernTheme.Shadow.medium.radius : 0,
                x: shadow ? ModernTheme.Shadow.medium.x : 0,
                y: shadow ? ModernTheme.Shadow.medium.y : 0
            )
    }
}

struct ModernGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    init(color: Color = ModernTheme.Colors.primary, radius: CGFloat = 12) {
        self.color = color
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
}

struct ModernHoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    let scaleEffect: CGFloat

    init(scaleEffect: CGFloat = 1.02) {
        self.scaleEffect = scaleEffect
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scaleEffect : 1.0)
            .animation(ModernTheme.Animation.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct ModernPressEffectModifier: ViewModifier {
    @State private var isPressed = false
    let scaleEffect: CGFloat

    init(scaleEffect: CGFloat = 0.96) {
        self.scaleEffect = scaleEffect
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleEffect : 1.0)
            .animation(ModernTheme.Animation.quick, value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0, maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                }, perform: {})
    }
}

// MARK: - View Extensions

extension View {
    func modernCard(cornerRadius: CGFloat = ModernTheme.CornerRadius.lg, shadow: Bool = true)
        -> some View
    {
        modifier(ModernCardModifier(cornerRadius: cornerRadius, shadow: shadow))
    }

    func modernGlow(color: Color = ModernTheme.Colors.primary, radius: CGFloat = 12) -> some View {
        modifier(ModernGlowModifier(color: color, radius: radius))
    }

    func modernHoverEffect(scaleEffect: CGFloat = 1.02) -> some View {
        modifier(ModernHoverEffectModifier(scaleEffect: scaleEffect))
    }

    func modernPressEffect(scaleEffect: CGFloat = 0.96) -> some View {
        modifier(ModernPressEffectModifier(scaleEffect: scaleEffect))
    }

    func modernInteractive(hoverScale: CGFloat = 1.02, pressScale: CGFloat = 0.96) -> some View {
        self
            .modernHoverEffect(scaleEffect: hoverScale)
            .modernPressEffect(scaleEffect: pressScale)
    }
}

// MARK: - Modern Background View

struct ModernBackground: View {
    let style: BackgroundStyle

    enum BackgroundStyle {
        case primary, secondary, surface

        var gradient: LinearGradient {
            switch self {
            case .primary:
                return .modernBackground
            case .secondary:
                return LinearGradient(
                    colors: [
                        ModernTheme.Colors.backgroundSecondary,
                        ModernTheme.Colors.backgroundTertiary,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .surface:
                return .modernSurface
            }
        }
    }

    var body: some View {
        style.gradient
            .ignoresSafeArea()
    }
}

// MARK: - Modern Loading View

struct ModernLoadingView: View {
    let message: String
    @State private var rotation: Double = 0

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: ModernTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .stroke(ModernTheme.Colors.surfaceSecondary, lineWidth: 4)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient.modernPrimary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(rotation))
                    .animation(
                        .linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: rotation
                    )
            }

            Text(message)
                .font(ModernTheme.Typography.callout)
                .foregroundColor(ModernTheme.Colors.textSecondary)
        }
        .onAppear {
            rotation = 360
        }
    }
}

// MARK: - Modern Empty State View

struct ModernEmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(
        title: String,
        subtitle: String,
        icon: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: ModernTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(ModernTheme.Colors.surfacePrimary)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(ModernTheme.Colors.textTertiary)
            }

            VStack(spacing: ModernTheme.Spacing.md) {
                Text(title)
                    .font(ModernTheme.Typography.title3)
                    .foregroundColor(ModernTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(ModernTheme.Typography.body)
                    .foregroundColor(ModernTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(ModernTheme.Typography.buttonLabel)
                }
                .buttonStyle(ModernPrimaryButtonStyle())
            }
        }
        .padding(ModernTheme.Spacing.xxxl)
    }
}
