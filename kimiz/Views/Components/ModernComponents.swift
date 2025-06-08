//
//  ModernComponents.swift
//  kimiz
//
//  Created by temidaradev on 7.06.2025.
//

import SwiftUI

// MARK: - Modern Section View

struct ModernSectionView<Content: View>: View {
    let title: String
    let icon: String?
    let content: Content

    init(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            content
        }
        .padding(20)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Modern Toggle Row

struct ModernToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String?
    @Binding var isOn: Bool

    init(title: String, subtitle: String? = nil, icon: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
}

// MARK: - Installation Summary Row

struct InstallationSummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Modern Game Template Card

struct ModernGameTemplateCard: View {
    let template: GameTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: template.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(isSelected ? .white : .blue)
                }

                VStack(spacing: 8) {
                    Text(template.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(template.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                            ? Color.blue.opacity(0.3) : Color.white.opacity(isHovered ? 0.15 : 0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.borderless)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Game Template Model

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

// MARK: - Modern Card View

struct ModernCardView<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let shadowEnabled: Bool

    init(
        cornerRadius: CGFloat = 16,
        padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        shadowEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowEnabled = shadowEnabled
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(
                color: shadowEnabled ? .black.opacity(0.1) : .clear,
                radius: shadowEnabled ? 8 : 0,
                x: 0,
                y: shadowEnabled ? 4 : 0
            )
    }
}

// MARK: - Modern Progress View

struct ModernProgressView: View {
    let value: Double
    let total: Double
    let showPercentage: Bool
    let accentColor: Color
    let height: CGFloat

    init(
        value: Double,
        total: Double = 1.0,
        showPercentage: Bool = true,
        accentColor: Color = .blue,
        height: CGFloat = 8
    ) {
        self.value = value
        self.total = total
        self.showPercentage = showPercentage
        self.accentColor = accentColor
        self.height = height
    }

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Spacer()
                if showPercentage {
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * percentage, height: height)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: - Modern Status Badge

struct ModernStatusBadge: View {
    let text: String
    let status: StatusType
    let size: BadgeSize

    enum StatusType {
        case success, warning, error, info, neutral

        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            case .neutral: return .gray
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .neutral: return "circle.fill"
            }
        }
    }

    enum BadgeSize {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            case .large: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(status.color)

            Text(text)
                .font(.system(size: size.fontSize, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(size.padding)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(status.color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Modern Info Panel

struct ModernInfoPanel: View {
    let title: String
    let subtitle: String?
    let icon: String
    let accentColor: Color
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        accentColor: Color = .blue,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    // Try SF Symbol first, fallback to asset if not available
                    if NSImage(systemSymbolName: icon, accessibilityDescription: nil) != nil {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(accentColor)
                    } else {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Modern Alert Card

struct ModernAlertCard: View {
    let title: String
    let message: String
    let type: AlertType
    let dismissAction: (() -> Void)?

    enum AlertType {
        case info, warning, error, success

        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .success: return .green
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(type.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Modern Statistics Card

struct ModernStatisticsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let trend: TrendDirection?
    let accentColor: Color

    enum TrendDirection {
        case up, down, neutral

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        trend: TrendDirection? = nil,
        accentColor: Color = .blue
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)

                Spacer()

                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(trend.color)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Modern Action Card

struct ModernActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(accentColor)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Modern System Tool Card

struct ModernSystemToolCard: View {
    let title: String
    let description: String
    let icon: String
    let status: ToolStatus
    let action: () -> Void

    enum ToolStatus {
        case available, disabled, busy

        var color: Color {
            switch self {
            case .available: return .green
            case .disabled: return .gray
            case .busy: return .orange
            }
        }

        var statusText: String {
            switch self {
            case .available: return "Available"
            case .disabled: return "Disabled"
            case .busy: return "Busy"
            }
        }
    }

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(status.color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(status.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Text(status.statusText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(status.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(status.color.opacity(0.2))
                            )
                    }

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .disabled(status == .disabled)
        .opacity(status == .disabled ? 0.6 : 1.0)
    }
}
