//
//  EpicGamesConnectionView.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
//

import SwiftUI

struct EpicGamesConnectionView: View {
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    if epicGamesManager.isConnected {
                        connectedView
                    } else {
                        connectionView
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 500, height: 600)
        .background(.regularMaterial)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Epic Games Connection")
                    .font(.headline)

                Text("Connect your Epic Games account to access your library")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var connectionView: some View {
        VStack(spacing: 20) {
            // Epic Games Logo placeholder
            VStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Connect to Epic Games")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Connect your Epic Games account to access and manage your game library")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Authentication Info Banner
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Epic Games Authentication")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                Text(
                    "This will open Epic Games' secure authentication page in your web browser. Sign in with your Epic Games account to connect your library."
                )
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            // Web Authentication Button
            VStack(spacing: 16) {
                Button {
                    connectToEpicGames()
                } label: {
                    HStack {
                        if epicGamesManager.isConnecting {
                            ProgressView()
                                .controlSize(.small)
                            Text("Connecting to Epic Games...")
                        } else {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Connect Epic Games Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(epicGamesManager.isConnecting)
                .controlSize(.large)
            }
            .padding(.horizontal)

            // Status/Error Message
            if let error = epicGamesManager.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            if epicGamesManager.isConnecting {
                VStack(spacing: 8) {
                    Text(epicGamesManager.connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Security Note
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                    Text("Secure Web Authentication")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                Text(
                    "Your Epic Games authentication is handled securely through Epic's official web interface. Your credentials are never stored locally."
                )
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var connectedView: some View {
        VStack(spacing: 20) {
            // Connected Status
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("Connected to Epic Games")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let displayName = epicGamesManager.userDisplayName {
                    Text("Welcome, \(displayName)!")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                if let email = epicGamesManager.userEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Epic Games Library
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Epic Games Library")
                        .font(.headline)

                    Spacer()

                    Button("Refresh") {
                        Task {
                            await epicGamesManager.scanForEpicGames()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if epicGamesManager.epicGames.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)

                        Text("No Epic Games found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Install games through the Epic Games Launcher")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(epicGamesManager.epicGames) { game in
                            HStack {
                                Image(systemName: "gamecontroller")
                                    .foregroundColor(.accentColor)

                                VStack(alignment: .leading) {
                                    Text(game.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text(game.installPath)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button("Launch") {
                                    // Launch game logic would go here
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }

            // Disconnect Button
            Button("Disconnect Account") {
                epicGamesManager.disconnect()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
    }

    private var footerView: some View {
        HStack {
            if !epicGamesManager.isConnected {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Don't have an Epic Games account?")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Create Account") {
                        if let url = URL(string: "https://www.epicgames.com/id/register") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            }

            Spacer()

            Button("Close") {
                isPresented = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func connectToEpicGames() {
        Task {
            await epicGamesManager.startWebAuthentication()
        }
    }
}

#Preview {
    EpicGamesConnectionView(isPresented: .constant(true))
        .environmentObject(EpicGamesManager.shared)
}
