//
//  GamesLibraryView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct GamesLibraryView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var searchText = ""
    @State private var selectedGame: Game?
    @State private var isRefreshing = false
    @State private var showGPTKStatusSheet = false

    var filteredGames: [Game] {
        if searchText.isEmpty {
            return gamePortingToolkitManager.installedGames
        }
        return gamePortingToolkitManager.installedGames.filter { game in
            game.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // GPTK status banner when not ready
                if !gamePortingToolkitManager.isGPTKInstalled {
                    gptkStatusBanner
                }

                // Initialization progress banner
                if gamePortingToolkitManager.isInitializing {
                    initializationProgressBanner
                }

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
                    Menu {
                        Button("Refresh Game List") {
                            refreshGames()
                        }
                        .disabled(isRefreshing)

                        Divider()

                        Button("Install Steam") {
                            installSteam()
                        }
                        .disabled(!gamePortingToolkitManager.isGPTKInstalled)

                        Button("Add Game Executable") {
                            // Open file picker to add a game
                        }
                        .disabled(!gamePortingToolkitManager.isGPTKInstalled)

                        Divider()

                        Button("GPTK Status") {
                            showGPTKStatusSheet = true
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showGPTKStatusSheet) {
                VStack {
                    Text("Game Porting Toolkit Status")
                        .font(.title2)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Installation Status:")
                            Spacer()
                            Text(
                                gamePortingToolkitManager.isGPTKInstalled
                                    ? "Installed" : "Not Installed"
                            )
                            .foregroundColor(
                                gamePortingToolkitManager.isGPTKInstalled ? .green : .red)
                        }

                        if let version = gamePortingToolkitManager.getGamePortingToolkitVersion() {
                            HStack {
                                Text("Version:")
                                Spacer()
                                Text(version)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("Status:")
                            Spacer()
                            Text(gamePortingToolkitManager.initializationStatus)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()

                    Button("Close") {
                        showGPTKStatusSheet = false
                    }
                    .padding(.bottom)
                }
                .frame(width: 500, height: 400)
            }
        }
        .task {
            await gamePortingToolkitManager.scanForGames()
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
            await gamePortingToolkitManager.scanForGames()
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

                if gamePortingToolkitManager.isGPTKInstalled {
                    Text("Game Porting Toolkit is ready! Install Steam or add games to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Please install Game Porting Toolkit first")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if gamePortingToolkitManager.isGPTKInstalled {
                Button("Install Steam") {
                    installSteam()
                }
                .buttonStyle(.borderedProminent)

                Button("Add Windows Game") {
                    // Show file picker to select Windows executable
                }
                .buttonStyle(.bordered)
            } else {
                Button("Setup GPTK") {
                    showGPTKStatusSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Game Actions
    private func refreshGames() {
        isRefreshing = true
        Task {
            await gamePortingToolkitManager.scanForGames()
            isRefreshing = false
        }
    }

    private func launchGame(_ game: Game) {
        Task {
            do {
                try await gamePortingToolkitManager.launchGame(game)
            } catch {
                // Handle error launching game
                print("Error launching game: \(error)")
            }
        }
    }

    private func installSteam() {
        Task {
            do {
                try await gamePortingToolkitManager.installSteam()

                // Refresh games after Steam installation
                await gamePortingToolkitManager.scanForGames()
            } catch {
                // Handle error installing Steam
                print("Error installing Steam: \(error)")
            }
        }
    }

    // MARK: - GPTK Status Banner
    private var gptkStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            Text("Game Porting Toolkit is not installed")
                .foregroundColor(.white)
                .font(.callout)

            Spacer()

            Button("Install Now") {
                showGPTKStatusSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.white.opacity(0.3))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.8))
    }

    // MARK: - Initialization Progress Banner
    private var initializationProgressBanner: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(.white)

            Text(gamePortingToolkitManager.initializationStatus)
                .foregroundColor(.white)
                .font(.callout)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.8))
    }
}

// MARK: - Game Row View
struct GameRowView: View {
    let game: Game
    let onLaunch: () -> Void

    @State private var isHovered = false
    @State private var showingLaunchOptions = false
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager

    var body: some View {
        HStack(spacing: 16) {
            // Game icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)

                if let icon = game.icon, let nsImage = NSImage(data: icon) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                } else {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }

            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let lastPlayed = game.lastPlayed {
                        Text("Last played: \(lastPlayed, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never played")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Game actions
            HStack(spacing: 8) {
                // Launch options button
                Button {
                    showingLaunchOptions = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderless)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                )
                .help("Launch Options")

                // Play button
                Button {
                    onLaunch()
                } label: {
                    Text("Play")
                        .frame(width: 80)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .sheet(isPresented: $showingLaunchOptions) {
            GameLaunchOptionsView(game: game, isPresented: $showingLaunchOptions)
                .environmentObject(gamePortingToolkitManager)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
        )
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private func formatPlayTime(_ time: TimeInterval) -> String {
        let hours = Int(time / 3600)
        if hours > 0 {
            return "\(hours) hours"
        } else {
            let minutes = Int(time / 60)
            return "\(max(minutes, 1)) minutes"
        }
    }
}

#Preview {
    GamesLibraryView()
        .environmentObject(GamePortingToolkitManager.shared)
}
