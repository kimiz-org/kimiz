//
//  WineStatusView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct WineStatusView: View {
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @State private var showingInstallationOptions = false

    var body: some View {
        VStack(spacing: 16) {
            headerView

            statusView

            if !embeddedWineManager.isWineReady && !embeddedWineManager.isInitializing
                && !embeddedWineManager.isInstallingComponents
            {
                actionButtons
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    private var headerView: some View {
        HStack {
            Text("Wine Runtime Status")
                .font(.headline)

            Spacer()

            Button {
                Task {
                    await embeddedWineManager.checkWineInstallation()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Refresh Wine status")
            .disabled(
                embeddedWineManager.isInstallingComponents || embeddedWineManager.isInitializing)
        }
    }

    private var statusView: some View {
        Group {
            if embeddedWineManager.isInitializing {
                statusIndicator(
                    icon: "hourglass",
                    color: .orange,
                    title: "Checking Wine Installation",
                    description: embeddedWineManager.initializationStatus
                )
            } else if embeddedWineManager.isInstallingComponents {
                VStack(spacing: 12) {
                    statusIndicator(
                        icon: "arrow.down.circle",
                        color: .blue,
                        title: "Installing Components",
                        description:
                            "Installing \(embeddedWineManager.installationComponentName)..."
                    )

                    ProgressView(value: embeddedWineManager.initializationProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                }
            } else if embeddedWineManager.isWineReady {
                VStack(spacing: 4) {
                    statusIndicator(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Wine is Ready",
                        description: "All required components are installed and configured"
                    )

                    Text("You can now play Windows games on your Mac")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                statusIndicator(
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    title: "Wine Not Installed",
                    description: "Wine is required to run Windows games"
                )
            }
        }
    }

    private func statusIndicator(icon: String, color: Color, title: String, description: String)
        -> some View
    {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Install Wine Automatically") {
                Task {
                    try? await embeddedWineManager.installRequiredComponents()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text("Wine components will only be installed if not already present")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("This includes: Homebrew, Game Porting Toolkit, and Winetricks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 4)

            Button("Manual Installation Instructions") {
                if let url = URL(
                    string: "https://developer.apple.com/documentation/gameportingtoolkit")
                {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }
}

struct WineStatusView_Previews: PreviewProvider {
    static var previews: some View {
        WineStatusView()
            .environmentObject(EmbeddedWineManager())
            .frame(width: 400)
            .padding()
    }
}
