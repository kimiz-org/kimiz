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
    @State private var showGameLibrary = false

    var body: some View {
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

            VStack(spacing: 0) {
                // Modern header
                modernHeaderView

                // Content with glass morphism effect
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(maxWidth: 600, maxHeight: 500)

                    if !epicGamesManager.isConnected {
                        modernConnectAccountView
                    } else {
                        modernConnectedAccountView
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(width: 700, height: 600)
        .sheet(isPresented: $showGameLibrary) {
            EpicGamesLibraryView()
                .environmentObject(epicGamesManager)
        }
    }

    private var modernHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Epic Games")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Connect your Epic Games account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
    }

    private var modernConnectAccountView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                // Epic Games Logo and Info
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text("Connect Epic Games Account")
                            .font(.system(size: 24, weight: .bold, design: .rounded))

                        Text(
                            "Access your Epic Games library and install games directly on macOS with Game Porting Toolkit"
                        )
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    }
                }

                // Features grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ModernFeatureCard(
                        icon: "folder.badge.gearshape",
                        title: "Access Library",
                        description: "View all Epic Store purchases"
                    )

                    ModernFeatureCard(
                        icon: "arrow.down.circle.fill",
                        title: "Install Games",
                        description: "Download to Wine bottles"
                    )

                    ModernFeatureCard(
                        icon: "play.circle.fill",
                        title: "Launch Games",
                        description: "Run with optimized settings"
                    )

                    ModernFeatureCard(
                        icon: "clock.arrow.circlepath",
                        title: "Sync Progress",
                        description: "Track games and playtime"
                    )
                }
            }

            Spacer()

            // Connect section
            VStack(spacing: 16) {
                if epicGamesManager.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.small)
                        Text(epicGamesManager.loadingMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                } else {
                    Button {
                        Task {
                            await epicGamesManager.connectAccount()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Connect Epic Games Account")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: 320)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    VStack(spacing: 4) {
                        Text("Demo Mode")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("In production, this would use Epic's official OAuth flow")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                if let error = epicGamesManager.lastError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding(32)
    }

    private var modernConnectedAccountView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                // Success state
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.2), .mint.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text("Epic Games Connected")
                            .font(.system(size: 24, weight: .bold, design: .rounded))

                        Text("Your Epic Games account is successfully connected and ready to use")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Account info
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Demo User")
                                .font(.system(size: 16, weight: .semibold))
                            Text("demo@epicgames.com")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    showGameLibrary = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("View Game Library")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: 280)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    epicGamesManager.disconnectAccount()
                } label: {
                    Text("Disconnect Account")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(32)
    }

    private var connectedAccountView: some View {
        VStack(spacing: 20) {
            // Account info
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("Account Connected")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let account = epicGamesManager.userAccount {
                    VStack(spacing: 4) {
                        Text(account.displayName)
                            .font(.headline)

                        if let email = account.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Library stats
            VStack(spacing: 12) {
                HStack {
                    statCard(
                        title: "Games Owned",
                        value: "\(epicGamesManager.epicGames.filter { $0.isOwned }.count)")
                    statCard(
                        title: "Installed",
                        value: "\(epicGamesManager.epicGames.filter { $0.isInstalled }.count)")
                }

                if epicGamesManager.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(epicGamesManager.loadingMessage)
                            .font(.subheadline)
                    }
                    .padding()
                }
            }

            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    showGameLibrary = true
                }) {
                    HStack {
                        Image(systemName: "gamecontroller")
                        Text("View Game Library")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    Task {
                        await epicGamesManager.refreshGameLibrary()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Library")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(epicGamesManager.isLoading)

                Button(action: {
                    epicGamesManager.disconnectAccount()
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                        Text("Disconnect Account")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            if let error = epicGamesManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private var footerView: some View {
        HStack {
            if epicGamesManager.isConnected {
                Text("✓ Connected to Epic Games")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Not connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    EpicGamesConnectionView(isPresented: .constant(true))
        .environmentObject(EpicGamesManager.shared)
}

// MARK: - Modern Feature Card Component

struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))

                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }
}
