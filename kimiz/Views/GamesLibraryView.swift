//
//  GamesLibraryView.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import SwiftUI

struct GamesLibraryView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @State private var searchText = ""
    @State private var selectedGame: Game?
    @State private var isRefreshing = false
    @State private var showGPTKStatusSheet = false
    @State private var showingFilePicker = false
    @State private var showingEpicConnection = false

    var filteredGames: [Game] {
        // For now, return empty array since GamePortingToolkitManager games are handled by EngineManager
        var allGames: [Game] = []

        // Convert Epic Games to regular Game model and add them
        let epicGamesAsGames = epicGamesManager.epicGames.map { epicGame in
            Game(
                id: epicGame.id,
                name: epicGame.displayName,
                executablePath: epicGame.executablePath ?? "",
                installPath: epicGame.installPath ?? "",
                lastPlayed: epicGame.lastPlayed,
                isInstalled: epicGame.isInstalled,
                icon: nil as Data?
            )
        }
        allGames.append(contentsOf: epicGamesAsGames)

        if searchText.isEmpty {
            return allGames
        }
        return allGames.filter { game in
            game.name.localizedCaseInsensitiveContains(searchText)
        }
    }

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

                // Status banners
                if !gamePortingToolkitManager.isGPTKInstalled {
                    modernGPTKStatusBanner
                }

                if gamePortingToolkitManager.isInitializing {
                    modernInitializationBanner
                }

                // Content area
                VStack(spacing: 20) {
                    // Search bar
                    modernSearchBar

                    // Games content
                    if filteredGames.isEmpty {
                        modernEmptyStateView
                    } else {
                        modernGamesList
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .task {
            await gamePortingToolkitManager.scanForGames()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.exe],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingEpicConnection) {
            EpicGamesConnectionView(isPresented: $showingEpicConnection)
                .environmentObject(epicGamesManager)
        }
        .sheet(isPresented: $showGPTKStatusSheet) {
            modernGPTKStatusSheet
        }
    }

    private var modernHeaderView: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Library")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        Label("\(filteredGames.count)", systemImage: "gamecontroller.fill")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        if isRefreshing {
                            Label("Refreshing...", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        refreshGames()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                    .disabled(isRefreshing)

                    // Add game menu
                    Menu {
                        Section("Install Platform") {
                            Button {
                                installSteam()
                            } label: {
                                Label("Steam Client", systemImage: "cloud.fill")
                            }
                            .disabled(!gamePortingToolkitManager.isGPTKInstalled || isRefreshing)

                            Button {
                                showingEpicConnection = true
                            } label: {
                                Label("Epic Games Store", systemImage: "gamecontroller.fill")
                            }
                            .disabled(!gamePortingToolkitManager.isGPTKInstalled)
                        }

                        Section("Add Games") {
                            Button {
                                showingFilePicker = true
                            } label: {
                                Label("Windows Executable", systemImage: "app.badge")
                            }
                            .disabled(!gamePortingToolkitManager.isGPTKInstalled)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("Add Game")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.borderless)
                    .menuStyle(.borderlessButton)
                    .disabled(!gamePortingToolkitManager.isGPTKInstalled)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var modernGPTKStatusBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Game Porting Toolkit Required")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("Install GPTK to run Windows games on your Mac")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Button {
                showGPTKStatusSheet = true
            } label: {
                Text("Install Now")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            .buttonStyle(.borderless)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 28)
        .padding(.bottom, 8)
    }

    private var modernInitializationBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)

                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Initializing Game Porting Toolkit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(gamePortingToolkitManager.initializationStatus)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 28)
        .padding(.bottom, 8)
    }

    private var modernSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            TextField("Search your game library...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var modernEmptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "gamecontroller")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                }

                VStack(spacing: 12) {
                    Text("No Games Found")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if gamePortingToolkitManager.isGPTKInstalled {
                        Text(
                            "Your game library is empty. Install Steam, connect Epic Games, or add Windows games to get started."
                        )
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(
                            "Install Game Porting Toolkit first to start running Windows games on your Mac."
                        )
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Quick action buttons
            if gamePortingToolkitManager.isGPTKInstalled {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Button {
                            installSteam()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 24, weight: .medium))
                                Text("Install Steam")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 140, height: 80)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.borderless)
                        .disabled(isRefreshing)

                        Button {
                            showingEpicConnection = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 24, weight: .medium))
                                Text("Connect Epic")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 140, height: 80)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.borderless)
                    }

                    Button {
                        showingFilePicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                            Text("Add Windows Game")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.borderless)
                    .disabled(isRefreshing)
                }
            } else {
                Button {
                    showGPTKStatusSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "download")
                            .font(.system(size: 18, weight: .medium))
                        Text("Install Game Porting Toolkit")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernGamesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredGames) { game in
                    ModernGameRowView(game: game) {
                        launchGame(game)
                    }
                    .environmentObject(gamePortingToolkitManager)
                    .environmentObject(epicGamesManager)
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await gamePortingToolkitManager.scanForGames()
        }
        .task {
            await gamePortingToolkitManager.scanForGames()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.exe],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingEpicConnection) {
            EpicGamesConnectionView(isPresented: $showingEpicConnection)
                .environmentObject(epicGamesManager)
        }
    }

    // MARK: - Helper Functions
    private func refreshGames() {
        isRefreshing = true
        Task {
            await gamePortingToolkitManager.scanForGames()
            await epicGamesManager.refreshGameLibrary()
            isRefreshing = false
        }
    }

    private func launchGame(_ game: Game) {
        Task {
            do {
                // Check if this is an Epic Game by looking for it in Epic Games Manager
                let isEpicGame = epicGamesManager.epicGames.contains { epicGame in
                    epicGame.id == game.id
                }

                if isEpicGame {
                    // For Epic Games, we might need special handling
                    // For now, try to launch directly through GPTK
                    try await gamePortingToolkitManager.launchGame(game)
                } else {
                    // Regular GPTK game launch
                    try await gamePortingToolkitManager.launchGame(game)
                }
            } catch {
                // Handle error launching game
                print("Error launching game: \(error)")
            }
        }
    }

    private func installSteam() {
        isRefreshing = true
        Task {
            do {
                try await gamePortingToolkitManager.installSteam()
                await gamePortingToolkitManager.scanForGames()
            } catch {
                // Optionally show an alert to the user
                print("Error installing Steam: \(error)")
            }
            isRefreshing = false
        }
    }

    // MARK: - ModernGPTKStatusSheet Component
    private var modernGPTKStatusSheet: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Game Porting Toolkit Status")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        showGPTKStatusSheet = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
            }

            // Content
            VStack(spacing: 24) {
                // Status indicator
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                gamePortingToolkitManager.isGPTKInstalled
                                    ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
                            )
                            .frame(width: 80, height: 80)

                        Image(
                            systemName: gamePortingToolkitManager.isGPTKInstalled
                                ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(gamePortingToolkitManager.isGPTKInstalled ? .green : .red)
                    }

                    Text(
                        gamePortingToolkitManager.isGPTKInstalled
                            ? "GPTK Installed" : "GPTK Not Installed"
                    )
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                }

                // Status details
                VStack(spacing: 16) {
                    StatusRow(
                        label: "Installation Status",
                        value: gamePortingToolkitManager.isGPTKInstalled
                            ? "Installed" : "Not Installed",
                        valueColor: gamePortingToolkitManager.isGPTKInstalled ? .green : .red
                    )

                    if let version = gamePortingToolkitManager.getGamePortingToolkitVersion() {
                        StatusRow(
                            label: "Version",
                            value: version,
                            valueColor: .white.opacity(0.8)
                        )
                    }

                    StatusRow(
                        label: "Status",
                        value: gamePortingToolkitManager.initializationStatus,
                        valueColor: .white.opacity(0.8)
                    )
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )

                if !gamePortingToolkitManager.isGPTKInstalled {
                    Button {
                        // Handle GPTK installation
                        showGPTKStatusSheet = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "download")
                                .font(.system(size: 16, weight: .medium))
                            Text("Install Game Porting Toolkit")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .frame(width: 500, height: 600)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.1, blue: 0.2),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                installGameExecutable(at: url)
            }
        case .failure(let error):
            // Optionally show an alert
            print("File selection failed: \(error.localizedDescription)")
        }
    }

    private func installGameExecutable(at url: URL) {
        Task {
            // Don't copy the executable - use it from its original location
            // This ensures supporting DLL files and game data remain accessible
            let newGame = Game(
                name: url.deletingPathExtension().lastPathComponent,
                executablePath: url.path,
                installPath: url.deletingLastPathComponent().path
            )
            await gamePortingToolkitManager.addUserGame(newGame)
        }
    }
}

#Preview {
    GamesLibraryView()
        .environmentObject(GamePortingToolkitManager.shared)
}

// MARK: - StatusRow Component
struct StatusRow: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - ModernGameRowView Component
struct ModernGameRowView: View {
    let game: Game
    let onLaunch: () -> Void

    @State private var isHovered = false
    @State private var showingLaunchOptions = false
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager

    private var isEpicGame: Bool {
        epicGamesManager.epicGames.contains { epicGame in
            epicGame.id == game.id
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            // Game icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                if let icon = game.icon, let nsImage = NSImage(data: icon) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Game info
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(game.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if isEpicGame {
                        HStack(spacing: 6) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("EPIC")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                    }

                    Spacer()
                }

                HStack(spacing: 16) {
                    if let lastPlayed = game.lastPlayed {
                        Label(
                            "Last played \(lastPlayed, formatter: dateFormatter)",
                            systemImage: "clock"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    } else {
                        Label("Never played", systemImage: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            // Game actions
            HStack(spacing: 12) {
                // Launch options button
                Button {
                    showingLaunchOptions = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.borderless)
                .help("Launch Options")

                // Play button
                Button {
                    onLaunch()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Play")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 100, height: 40)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.borderless)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.15 : 0.1),
                            Color.white.opacity(isHovered ? 0.1 : 0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            Color.white.opacity(isHovered ? 0.3 : 0.2),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .sheet(isPresented: $showingLaunchOptions) {
            GameLaunchOptionsView(game: game, isPresented: $showingLaunchOptions)
                .environmentObject(gamePortingToolkitManager)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
