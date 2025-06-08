//
//  LibraryView.swift
//  kimiz
//
//  Created by temidaradev on 5.06.2025.
//

import AppKit
import Foundation
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @StateObject private var libraryManager = LibraryManager.shared
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
        // Use games from the dedicated LibraryManager
        let allGames = libraryManager.discoveredGames

        if searchText.isEmpty {
            return allGames
        } else {
            return allGames.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack {
            // Modern background
            ModernBackground(style: .primary)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern header with search
                modernHeaderView

                // Remove any "temporarily disabled" message and always show the library UI
                if filteredGames.isEmpty && !searchText.isEmpty {
                    searchEmptyStateView
                } else if filteredGames.isEmpty {
                    modernEmptyStateView
                } else {
                    modernGamesGridView
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            // .exe is not a valid UTType on macOS, so use .data to allow any file
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernHeaderView: some View {
        ModernSectionView(title: "Game Library", icon: "gamecontroller.fill") {
            VStack(spacing: 16) {
                // Stats and action buttons
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 16) {
                            Label(
                                "\(libraryManager.discoveredGames.count) games",
                                systemImage: "gamecontroller.fill"
                            )
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                            if isRefreshing || libraryManager.isScanning {
                                Label("Refreshing...", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }

                            if let lastScan = libraryManager.lastScanDate {
                                Label(
                                    "Last scan: \(lastScan, formatter: relativeDateFormatter)",
                                    systemImage: "clock"
                                )
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
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
                        .disabled(isRefreshing || libraryManager.isScanning)

                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("Add Game", systemImage: "plus")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())
                        .disabled(isRefreshing || libraryManager.isScanning)
                    }
                }

                // Search bar with modern design
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16, weight: .medium))

                    TextField("Search games...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.white)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
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
                        .foregroundColor(.white)

                    Text("Add Windows games and run them with Game Porting Toolkit on Mac")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
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
                    .disabled(isRefreshing || libraryManager.isScanning)
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
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 8) {
                Text("No games found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Try adjusting your search terms")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
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
                        if ![
                            "Steam", "Epic Games Launcher", "Battle.net", "Origin",
                            "Ubisoft Connect", "GOG Galaxy",
                        ].contains(game.name) {
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
        await libraryManager.scanForImportantExecutables()
        isRefreshing = false
    }

    private func launchGame(_ game: Game) {
        Task {
            do {
                // Use the GPTK manager to launch the game
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
            await libraryManager.addUserGame(game)
        }
    }

    private func deleteGame(_ game: Game) {
        print("[LibraryView] Delete button pressed for game: \(game.name)")
        Task {
            // Don't allow deleting Steam or other important launchers
            guard
                ![
                    "Steam", "Epic Games Launcher", "Battle.net", "Origin", "Ubisoft Connect",
                    "GOG Galaxy",
                ].contains(game.name)
            else {
                print("[LibraryView] Cannot delete important launcher: \(game.name)")
                return
            }

            print("[LibraryView] Proceeding to delete game: \(game.name)")
            await libraryManager.removeUserGame(game)
            print("[LibraryView] Delete completed for game: \(game.name)")
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

    private var isImportantLauncher: Bool {
        ["Steam", "Epic Games Launcher", "Battle.net", "Origin", "Ubisoft Connect", "GOG Galaxy"]
            .contains(game.name)
    }

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

                // Launcher badge for important launchers
                if isImportantLauncher {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 16)

                                Text("LAUNCHER")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }

                // Play overlay on hover
                if isHovered {
                    HStack {
                        // Delete button (only for user-added games, not important launchers)
                        if !isImportantLauncher {
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
                // Modern glassmorphism background with gradient and blur
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.purple.opacity(0.10),
                                Color.blue.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .blur(radius: 0.5)
                    .frame(height: 220)
                    .shadow(
                        color: .black.opacity(isHovered ? 0.22 : 0.10), radius: isHovered ? 28 : 12,
                        x: 0, y: isHovered ? 16 : 6)

                // Game icon or placeholder
                if let icon = gameIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.9), .purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                Color.primary  // fallback style
                            )
                        Text(game.name.prefix(1).uppercased())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                // Hover overlay with glass panel and modern actions
                if isHovered {
                    VStack {
                        HStack {
                            // Delete button (only for non-Steam games)
                            if game.name != "Steam" {
                                Button {
                                    onDelete()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(ModernDestructiveButtonStyle())
                                .controlSize(.small)
                                .padding(8)
                                .background(.ultraThinMaterial.opacity(0.7))
                                .clipShape(Circle())
                                .shadow(color: .red.opacity(0.18), radius: 6, x: 0, y: 2)
                            }
                            Spacer()
                        }
                        Spacer()
                        // Play button
                        Button {
                            onLaunch()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Play")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())
                        .controlSize(.large)
                        .background(.ultraThinMaterial.opacity(0.85))
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.18), radius: 10, x: 0, y: 4)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial.opacity(0.92))
                            .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .clipped()

            // Game info section
            VStack(spacing: 10) {
                Text(game.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let lastPlayed = game.lastPlayed {
                    Text("Last played \(lastPlayed, formatter: relativeDateFormatter)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Never played")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(isHovered ? 0.18 : 0.08),
                    radius: isHovered ? 28 : 12,
                    x: 0,
                    y: isHovered ? 12 : 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
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
