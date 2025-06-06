//
//  LibraryView.swift
//  kimiz
//
//  Created by temidaradev on 5.06.2025.
//

import AppKit
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @State private var isRefreshing = false
    @State private var showingFilePicker = false
    @State private var selectedGame: Game?
    @State private var hoveredGame: Game?
    @State private var searchText = ""

    // Modern grid layout with larger cards
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 24)
    ]

    var filteredGames: [Game] {
        if searchText.isEmpty {
            return gamePortingToolkitManager.installedGames
        } else {
            return gamePortingToolkitManager.installedGames.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack {
            // Modern background with subtle gradient
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern header with search
                modernHeaderView

                // Games content with better spacing
                if filteredGames.isEmpty && !searchText.isEmpty {
                    searchEmptyStateView
                } else if gamePortingToolkitManager.installedGames.isEmpty {
                    modernEmptyStateView
                } else {
                    modernGamesGridView
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.exe],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernHeaderView: some View {
        VStack(spacing: 20) {
            // Title and stats section
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Library")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    HStack(spacing: 16) {
                        Label(
                            "\(gamePortingToolkitManager.installedGames.count)",
                            systemImage: "gamecontroller.fill"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        if isRefreshing {
                            Label("Refreshing...", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                // Action buttons with modern styling
                HStack(spacing: 12) {
                    Button {
                        Task { await refreshGames() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                    .disabled(isRefreshing)

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Add Game", systemImage: "plus")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(ModernPrimaryButtonStyle())
                    .disabled(isRefreshing)
                }
            }

            // Search bar with modern design
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search games...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 1)
            )
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    private var modernEmptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                // Beautiful icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 12) {
                    Text("Your Game Library Awaits")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("Add Windows games and run them with Game Porting Toolkit on Mac")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                VStack(spacing: 16) {
                    Button {
                        showingFilePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add Your First Game")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: 280)
                    }
                    .buttonStyle(ModernPrimaryButtonStyle())
                    .controlSize(.large)

                    Button {
                        Task { await refreshGames() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                            Text("Scan for Games")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                    .disabled(isRefreshing)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    private var searchEmptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No games found")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Try adjusting your search terms")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Button {
                searchText = ""
            } label: {
                Text("Clear Search")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(ModernSecondaryButtonStyle())

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernGamesGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(filteredGames) { game in
                    ModernGameCard(
                        game: game,
                        isHovered: hoveredGame?.id == game.id,
                        onLaunch: { launchGame(game) },
                        onDelete: { deleteGame(game) },
                        onHover: { isHovered in
                            hoveredGame = isHovered ? game : nil
                        }
                    )
                    .contextMenu {
                        Button("Play", action: { launchGame(game) })
                        if game.name != "Steam" {
                            Divider()
                            Button("Remove from Library", role: .destructive) {
                                deleteGame(game)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .background(.clear)
        .refreshable {
            await refreshGames()
        }
    }

    // MARK: - Actions

    private func refreshGames() async {
        isRefreshing = true
        await gamePortingToolkitManager.scanForGames()
        isRefreshing = false
    }

    private func launchGame(_ game: Game) {
        Task {
            do {
                try await gamePortingToolkitManager.launchGame(game)
            } catch {
                print("Error launching game: \(error)")
                // Could add error alert here
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                installGame(at: url)
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }

    private func installGame(at url: URL) {
        Task {
            let game = Game(
                name: url.deletingPathExtension().lastPathComponent,
                executablePath: url.path,
                installPath: url.deletingLastPathComponent().path
            )
            await gamePortingToolkitManager.addUserGame(game)
            await refreshGames()
        }
    }

    private func deleteGame(_ game: Game) {
        Task {
            // Don't allow deleting Steam
            guard game.name != "Steam" else { return }

            await gamePortingToolkitManager.removeUserGame(game)
            await refreshGames()
        }
    }
}

// MARK: - Game Card Component

struct GameCard: View {
    let game: Game
    let isHovered: Bool
    let onLaunch: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var gameIcon: NSImage?

    var body: some View {
        VStack(spacing: 12) {
            // Game Icon/Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 150, height: 150)

                if let icon = gameIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                }

                // Play overlay on hover
                if isHovered {
                    HStack {
                        // Delete button (only for non-Steam games)
                        if game.name != "Steam" {
                            ZStack {
                                Circle()
                                    .fill(.red.opacity(0.8))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .onTapGesture {
                                onDelete()
                            }
                        }

                        Spacer()

                        // Play button
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.7))
                                .frame(width: 60, height: 60)

                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            onLaunch()
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }
            .onHover { hovering in
                onHover(hovering)
            }
            .onTapGesture {
                // Launch game when tapping the card (if not hovering over buttons)
                if !isHovered {
                    onLaunch()
                }
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)

            // Game Info
            VStack(spacing: 4) {
                Text(game.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let lastPlayed = game.lastPlayed {
                    Text("Last played: \(lastPlayed, formatter: relativeDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Never played")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 150)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: isHovered ? 8 : 4, x: 0, y: 2)
        )
        .onAppear {
            loadGameIcon()
        }
    }

    private func loadGameIcon() {
        // Try to extract icon from executable
        Task {
            if let icon = extractIconFromExecutable(path: game.executablePath) {
                await MainActor.run {
                    self.gameIcon = icon
                }
            }
        }
    }

    private func extractIconFromExecutable(path: String) -> NSImage? {
        // Try to get icon from the executable
        let workspace = NSWorkspace.shared
        let icon = workspace.icon(forFile: path)

        // If it's just a generic executable icon, try to find a better one
        if icon.representations.count == 1 && icon.size == NSSize(width: 32, height: 32) {
            // Look for icon files in the same directory
            let directory = (path as NSString).deletingLastPathComponent
            let iconExtensions = ["ico", "png", "jpg", "jpeg", "bmp"]

            for ext in iconExtensions {
                let iconPath = (directory as NSString).appendingPathComponent("icon.\(ext)")
                if FileManager.default.fileExists(atPath: iconPath) {
                    if let foundIcon = NSImage(contentsOfFile: iconPath) {
                        return foundIcon
                    }
                }
            }
        }

        return icon
    }
}

// MARK: - Modern Game Card Component

struct ModernGameCard: View {
    let game: Game
    let isHovered: Bool
    let onLaunch: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var gameIcon: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            // Game artwork/icon section
            ZStack {
                // Background with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(NSColor.controlBackgroundColor),
                                Color(NSColor.separatorColor),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)

                // Game icon or placeholder
                if let icon = gameIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(game.name.prefix(1).uppercased())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                // Hover overlay with actions
                if isHovered {
                    VStack {
                        HStack {
                            // Delete button (only for non-Steam games)
                            if game.name != "Steam" {
                                Button {
                                    onDelete()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(ModernDestructiveButtonStyle())
                                .controlSize(.small)
                            }

                            Spacer()
                        }

                        Spacer()

                        // Play button
                        Button {
                            onLaunch()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Play")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())
                        .controlSize(.large)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial.opacity(0.9))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .clipped()

            // Game info section
            VStack(spacing: 8) {
                Text(game.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let lastPlayed = game.lastPlayed {
                    Text("Last played \(lastPlayed, formatter: relativeDateFormatter)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Never played")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(isHovered ? 0.15 : 0.08),
                    radius: isHovered ? 20 : 10,
                    x: 0,
                    y: isHovered ? 8 : 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.quaternary.opacity(0.5), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            onHover(hovering)
        }
        .onTapGesture {
            if !isHovered {
                onLaunch()
            }
        }
        .onAppear {
            loadGameIcon()
        }
    }

    private func loadGameIcon() {
        Task {
            if let icon = extractIconFromExecutable(path: game.executablePath) {
                await MainActor.run {
                    self.gameIcon = icon
                }
            }
        }
    }

    private func extractIconFromExecutable(path: String) -> NSImage? {
        let workspace = NSWorkspace.shared
        let icon = workspace.icon(forFile: path)

        // Look for better icons in the game directory
        if icon.representations.count == 1 && icon.size == NSSize(width: 32, height: 32) {
            let directory = (path as NSString).deletingLastPathComponent
            let iconExtensions = ["ico", "png", "jpg", "jpeg", "bmp"]

            for ext in iconExtensions {
                let iconPath = (directory as NSString).appendingPathComponent("icon.\(ext)")
                if FileManager.default.fileExists(atPath: iconPath) {
                    if let foundIcon = NSImage(contentsOfFile: iconPath) {
                        return foundIcon
                    }
                }
            }
        }

        return icon
    }
}

// MARK: - Formatters

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

#Preview {
    LibraryView()
        .environmentObject(GamePortingToolkitManager.shared)
}
