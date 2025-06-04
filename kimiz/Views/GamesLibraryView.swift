//
//  GamesLibraryView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct GamesLibraryView: View {
    @EnvironmentObject var wineManager: WineManager
    @State private var searchText = ""
    @State private var selectedGame: GameInstallation?
    @State private var showingGameDetails = false

    var filteredGames: [GameInstallation] {
        if searchText.isEmpty {
            return wineManager.gameInstallations
        }
        return wineManager.gameInstallations.filter { game in
            game.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if filteredGames.isEmpty {
                    EmptyGamesView()
                } else {
                    GameGridView(games: filteredGames, selectedGame: $selectedGame)
                }
            }
            .navigationTitle("Game Library")
            .searchable(text: $searchText, prompt: "Search games")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        Task {
                            await refreshGameLibrary()
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedGame) { game in
            GameDetailsView(game: game)
        }
    }

    private func refreshGameLibrary() async {
        // Scan Wine prefixes for installed games
        // This could scan common installation directories
    }
}

struct EmptyGamesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Games Installed")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Install Steam or other Windows games using the Install tab")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct GameGridView: View {
    let games: [GameInstallation]
    @Binding var selectedGame: GameInstallation?

    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(games, id: \.id) { game in
                    GameCard(game: game)
                        .onTapGesture {
                            selectedGame = game
                        }
                }
            }
            .padding()
        }
    }
}

struct GameCard: View {
    let game: GameInstallation
    @EnvironmentObject var wineManager: WineManager
    @State private var isLaunching = false

    var body: some View {
        VStack {
            // Game Icon/Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.gradient)
                .frame(height: 120)
                .overlay {
                    if let iconData = game.icon, let uiImage = NSImage(data: iconData) {
                        Image(nsImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(game.winePrefix.name)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lastPlayed = game.lastPlayed {
                    Text("Last played: \(lastPlayed, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                launchGame()
            }) {
                HStack {
                    if isLaunching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(isLaunching ? "Launching..." : "Play")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLaunching || !game.isInstalled)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func launchGame() {
        isLaunching = true
        Task {
            do {
                try await wineManager.launchGame(game)
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
            VStack(alignment: .leading, spacing: 20) {
                // Game header
                HStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.gradient)
                        .frame(width: 80, height: 80)
                        .overlay {
                            if let iconData = game.icon, let uiImage = NSImage(data: iconData) {
                                Image(nsImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }

                    VStack(alignment: .leading) {
                        Text(game.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Wine Prefix: \(game.winePrefix.name)")
                            .foregroundColor(.secondary)

                        Text("Backend: \(game.winePrefix.backend.displayName)")
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Game info
                GroupBox("Game Information") {
                    VStack(alignment: .leading, spacing: 8) {
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
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Game Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
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

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    GamesLibraryView()
        .environmentObject(WineManager())
}
