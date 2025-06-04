//
//  GamesLibraryView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct GamesLibraryView: View {
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @State private var searchText = ""
    @State private var selectedGame: GameInstallation?
    @State private var isRefreshing = false

    var filteredGames: [GameInstallation] {
        if searchText.isEmpty {
            return embeddedWineManager.installedGames
        }
        return embeddedWineManager.installedGames.filter { game in
            game.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Games list
                if filteredGames.isEmpty {
                    emptyStateView
                } else {
                    gamesList
                }
            }
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        refreshGames()
                    }
                    .disabled(isRefreshing)
                }
            }
        }
        .task {
            await embeddedWineManager.scanForInstalledGames()
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search games...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Games List
    private var gamesList: some View {
        List(filteredGames) { game in
            GameRowView(game: game) {
                launchGame(game)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .refreshable {
            await embeddedWineManager.scanForInstalledGames()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Games Found")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Install Steam or add games to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Install Steam") {
                installSteam()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Actions
    private func refreshGames() {
        isRefreshing = true
        Task {
            await embeddedWineManager.scanForInstalledGames()
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func launchGame(_ game: GameInstallation) {
        Task {
            do {
                try await embeddedWineManager.launchGame(game)
            } catch {
                print("Failed to launch game: \(error)")
            }
        }
    }
    
    private func installSteam() {
        Task {
            do {
                try await embeddedWineManager.installSteam()
                await embeddedWineManager.scanForInstalledGames()
            } catch {
                print("Failed to install Steam: \(error)")
            }
        }
    }
}

// MARK: - Game Row View
struct GameRowView: View {
    let game: GameInstallation
    let onLaunch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Game icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.accentColor)
                )
            
            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let lastPlayed = game.lastPlayed {
                    Text("Last played: \(lastPlayed, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never played")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Launch button
            Button("Play") {
                onLaunch()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    GamesLibraryView()
        .environmentObject(EmbeddedWineManager())
}
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("\(filteredGames.count) games available")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { Task { await openSteam() } }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Steam")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: { Task { await refreshGameLibrary() } }) {
                        HStack(spacing: 8) {
                            Image(
                                systemName: isRefreshing
                                    ? "arrow.trianglehead.2.clockwise" : "arrow.clockwise"
                            )
                            .font(.system(size: 14, weight: .semibold))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                .linear(duration: 1).repeatForever(autoreverses: false),
                                value: isRefreshing)
                            Text("Refresh")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(isRefreshing)
                }
            }

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search your games...", text: $searchText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .opacity(animateHeader ? 1 : 0)
        .offset(y: animateHeader ? 0 : -20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateHeader)
    }

    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            if filteredGames.isEmpty {
                ModernEmptyGamesView()
            } else {
                ModernGameGridView(games: filteredGames, selectedGame: $selectedGame)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateCards)
    }

    // MARK: - Helper Methods
    private func startAnimations() {
        withAnimation {
            animateHeader = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animateCards = true
            }
        }
    }

    private func refreshGameLibrary() async {
        isRefreshing = true
        await embeddedWineManager.scanForInstalledGames()
        isRefreshing = false
    }

    private func openSteam() async {
        do {
            try await embeddedWineManager.launchSteam()
        } catch {
            print("Failed to launch Steam: \(error)")
        }
    }
}

// MARK: - Modern Components

struct ModernEmptyGamesView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("No Games Found")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Install Steam to access your game library, or add games manually")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ModernGameGridView: View {
    let games: [GameInstallation]
    @Binding var selectedGame: GameInstallation?

    let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(games, id: \.id) { game in
                    ModernGameCard(game: game)
                        .onTapGesture {
                            selectedGame = game
                        }
                }
            }
            .padding(24)
        }
    }
}

struct ModernGameCard: View {
    let game: GameInstallation
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @State private var isLaunching = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 16) {
            // Game Icon/Image
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.8),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                if let iconData = game.icon, let uiImage = NSImage(data: iconData) {
                    Image(nsImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                }

                // Play overlay on hover
                if isHovered {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Button(action: { launchGame() }) {
                                HStack(spacing: 8) {
                                    if isLaunching {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                    }
                                    Text(isLaunching ? "Launching..." : "Play")
                                        .font(
                                            .system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(isLaunching || !game.isInstalled)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            // Game Info
            VStack(alignment: .leading, spacing: 8) {
                Text(game.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    Label("Embedded Wine", systemImage: "gear")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Spacer()

                    if game.isInstalled {
                        Label("Ready", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.green)
                    } else {
                        Label("Not Installed", systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }

                if let lastPlayed = game.lastPlayed {
                    Text("Last played \(lastPlayed, style: .relative) ago")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 15 : 5, x: 0,
            y: isHovered ? 8 : 2
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func launchGame() {
        isLaunching = true
        Task {
            do {
                try await embeddedWineManager.launchGame(game)
            } catch {
                print("Failed to launch game: \(error)")
            }
            await MainActor.run {
                isLaunching = false
            }
        }
    }
}

struct GameDetailsView: View {
    let game: GameInstallation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.clear,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)

                VStack(alignment: .leading, spacing: 24) {
                    // Game header
                    HStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.8), Color.purple.opacity(0.8),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                            if let iconData = game.icon, let uiImage = NSImage(data: iconData) {
                                Image(nsImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(game.name)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Label("Embedded Wine Environment", systemImage: "gear")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            Label("Ready to Play", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.green)
                        }

                        Spacer()
                    }

                    // Game info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Game Information")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: 12) {
                            InfoRow(label: "Installation Path", value: game.installPath)
                            InfoRow(label: "Executable", value: game.executablePath)
                            if let lastPlayed = game.lastPlayed {
                                InfoRow(
                                    label: "Last Played",
                                    value: DateFormatter.localizedString(
                                        from: lastPlayed, dateStyle: .medium, timeStyle: .short))
                            }
                            InfoRow(label: "Play Time", value: formatPlayTime(game.playTime))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Game Details")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func formatPlayTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    GamesLibraryView()
        .environmentObject(EmbeddedWineManager())
}
