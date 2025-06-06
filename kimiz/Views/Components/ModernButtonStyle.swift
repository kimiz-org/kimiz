//
//  ModernButtonStyle.swift
//  kimiz
//
//  Created by GitHub Copilot
//

import SwiftUI

struct ModernPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(
                color: .blue.opacity(0.3),
                radius: configuration.isPressed ? 2 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
    }
}

struct ModernSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.red)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(
                color: .red.opacity(0.3),
                radius: configuration.isPressed ? 2 : 6,
                x: 0,
                y: configuration.isPressed ? 1 : 3
            )
    }
}

// Legacy support
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let style: Style

    enum Style {
        case primary
        case secondary
    }

    init(color: Color, style: Style = .primary) {
        self.color = color
        self.style = style
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(style == .primary ? .white : color)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style == .primary ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: style == .secondary ? 1.5 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(
                color: style == .primary ? color.opacity(0.3) : .clear,
                radius: configuration.isPressed ? 2 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("Primary Button") {}
            .buttonStyle(ModernPrimaryButtonStyle())

        Button("Secondary Button") {}
            .buttonStyle(ModernSecondaryButtonStyle())

        Button("Destructive Button") {}
            .buttonStyle(ModernDestructiveButtonStyle())

        Button("Legacy Primary") {}
            .buttonStyle(ModernButtonStyle(color: .cyan))

        Button("Legacy Secondary") {}
            .buttonStyle(ModernButtonStyle(color: .gray, style: .secondary))
    }
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
}
