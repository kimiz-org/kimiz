//
//  ModernButtonStyle.swift
//  kimiz
//
//  Created by GitHub Copilot
//

import SwiftUI

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
            .buttonStyle(ModernButtonStyle(color: .cyan))

        Button("Secondary Button") {}
            .buttonStyle(ModernButtonStyle(color: .gray, style: .secondary))
    }
    .padding()
    .background(Color.black)
}
