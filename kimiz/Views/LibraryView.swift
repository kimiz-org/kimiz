//
//  LibraryView.swift
//  kimiz
//
//  Created by GitHub Copilot on 5.06.2025.
//

import AppKit
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var isRefreshing = false
    @State private var showingFilePicker = false
    @State private var selectedGame: Game?
    @State private var hoveredGame: Game?

    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Games Grid
                if gamePortingToolkitManager.installedGames.isEmpty {
                    emptyStateView
                } else {
                    gamesGridView
                }
            }
            .refreshable {
                await refreshGames()
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.exe],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game Library")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(gamePortingToolkitManager.installedGames.count) games installed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Add Game") {
                    showingFilePicker = true
                }
                .buttonStyle(.bordered)
                .disabled(isRefreshing)

                Button("Refresh") {
                    Task {
                        await refreshGames()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isRefreshing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "gamecontroller")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Games Installed")
                .font(.title2)
                .fontWeight(.medium)

            Text("Add Windows games to get started")
                .font(.body)
                .foregroundColor(.secondary)

            Button("Add Your First Game") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gamesGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(gamePortingToolkitManager.installedGames) { game in
                    GameCard(
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
                        Divider()
                        Button("Remove from Library", role: .destructive) {
                            deleteGame(game)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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
