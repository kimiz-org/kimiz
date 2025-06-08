//
//  EpicGamesLibraryView.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
//

import SwiftUI

struct EpicGamesLibraryView: View {
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingInstalledOnly = false
    @State private var selectedGame: EpicGame?

    var filteredGames: [EpicGame] {
        var games = epicGamesManager.epicGames

        if showingInstalledOnly {
            games = games.filter { $0.isInstalled }
        }

        if !searchText.isEmpty {
            games = games.filter { game in
                game.displayName.localizedCaseInsensitiveContains(searchText)
                    || (game.publisher?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return games.sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: [.black, .gray.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Modern search and filter bar
                    modernSearchBarView

                    // Games grid with glassmorphism
                    if filteredGames.isEmpty {
                        modernEmptyStateView
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
                                ], spacing: 16
                            ) {
                                ForEach(filteredGames) { game in
                                    ModernGameCardView(game: game)
                                        .environmentObject(epicGamesManager)
                                        .onTapGesture {
                                            selectedGame = game
                                        }
                                }
                            }
                            .padding(24)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)

                        Text("Epic Games Library")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            await epicGamesManager.refreshGameLibrary()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .disabled(epicGamesManager.isLoading)
                    .opacity(epicGamesManager.isLoading ? 0.6 : 1.0)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(width: 800, height: 600)
        .sheet(item: $selectedGame) { game in
            ModernGameDetailView(game: game)
                .environmentObject(epicGamesManager)
        }
    }

    private var modernSearchBarView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                TextField("Search games...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            // Filter controls
            HStack {
                Toggle("Installed only", isOn: $showingInstalledOnly)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Spacer()

                Text("\(filteredGames.count) games")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(24)
    }

    private var modernEmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.4))

            VStack(spacing: 8) {
                Text("No games found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                if showingInstalledOnly {
                    Text("No installed games match your search.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("Try adjusting your search or refresh your library.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Button(action: {
                Task {
                    await epicGamesManager.refreshGameLibrary()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("Refresh Library")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .buttonStyle(.borderless)
            .disabled(epicGamesManager.isLoading)
            .opacity(epicGamesManager.isLoading ? 0.6 : 1.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ModernGameCardView: View {
    let game: EpicGame
    @EnvironmentObject var epicGamesManager: EpicGamesManager

    var isInstalling: Bool {
        epicGamesManager.installingGames.contains(game.appName)
    }

    var installProgress: Double {
        epicGamesManager.downloadProgress[game.appName] ?? 0.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game image/icon with modern overlay
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.05))
                    .aspectRatio(3 / 4, contentMode: .fit)

                if let iconUrl = game.iconUrl, let url = URL(string: iconUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .clipped()
                    .cornerRadius(12)
                } else {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                }

                // Status overlay with glassmorphism
                VStack {
                    HStack {
                        Spacer()

                        if game.isInstalled {
                            ZStack {
                                Circle()
                                    .fill(.green.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .background(.ultraThinMaterial, in: Circle())

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                            }
                        } else if isInstalling {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .background(.ultraThinMaterial, in: Circle())

                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.blue)
                            }
                        }
                    }
                    .padding(12)

                    Spacer()
                }
            }

            // Game info with modern typography
            VStack(alignment: .leading, spacing: 6) {
                Text(game.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let publisher = game.publisher {
                    Text(publisher)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                // Size info
                if let size = game.installSize {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Modern action button
            Button(action: {
                if game.isInstalled {
                    Task {
                        try await epicGamesManager.launchGame(game)
                    }
                } else {
                    Task {
                        await epicGamesManager.installGame(game)
                    }
                }
            }) {
                HStack(spacing: 6) {
                    if isInstalling {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                        Text("\(Int(installProgress * 100))%")
                            .font(.system(size: 12, weight: .medium))
                    } else if game.isInstalled {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("Play")
                            .font(.system(size: 12, weight: .medium))
                    } else {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12, weight: .medium))
                        Text("Install")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(
                            colors: game.isInstalled
                                ? [.green, .green.opacity(0.8)] : [.blue, .blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .buttonStyle(.borderless)
            .disabled(isInstalling)
            .opacity(isInstalling ? 0.8 : 1.0)
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ModernGameDetailView: View {
    let game: EpicGame
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @Environment(\.dismiss) private var dismiss

    var isInstalling: Bool {
        epicGamesManager.installingGames.contains(game.appName)
    }

    var installProgress: Double {
        epicGamesManager.downloadProgress[game.appName] ?? 0.0
    }

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [.black, .gray.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern header
                modernHeaderView

                // Content with glassmorphism
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Game image
                        modernGameImageView

                        // Description section
                        if let description = game.description {
                            modernDescriptionView(description)
                        }

                        // Game details section
                        modernDetailsView
                    }
                    .padding(24)
                }

                // Modern action buttons
                modernActionButtonsView
            }
        }
        .frame(width: 500, height: 600)
    }

    private var modernHeaderView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                if let publisher = game.publisher {
                    Text("by \(publisher)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(24)
    }

    private var modernGameImageView: some View {
        Group {
            if let imageUrl = game.imageUrl ?? game.iconUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.05))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.white.opacity(0.4))
                        )
                }
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    private func modernDescriptionView(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)

                Text("About")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(20)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var modernDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)

                Text("Details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                if let developer = game.developer {
                    modernDetailRow("Developer", value: developer)
                }

                if let publisher = game.publisher {
                    modernDetailRow("Publisher", value: publisher)
                }

                if let size = game.installSize {
                    modernDetailRow(
                        "Download Size",
                        value: ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                    )
                }

                if let lastPlayed = game.lastPlayed {
                    modernDetailRow(
                        "Last Played",
                        value: DateFormatter.localizedString(
                            from: lastPlayed, dateStyle: .medium, timeStyle: .short
                        )
                    )
                }

                modernDetailRow("Status", value: game.isInstalled ? "Installed" : "Not Installed")
            }
        }
        .padding(20)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var modernActionButtonsView: some View {
        HStack(spacing: 16) {
            if game.isInstalled {
                Button(action: {
                    Task {
                        try await epicGamesManager.launchGame(game)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Play")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.borderless)

                Button("Uninstall") {
                    // TODO: Implement uninstall
                }
                .buttonStyle(.borderless)
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            } else {
                Button(action: {
                    Task {
                        await epicGamesManager.installGame(game)
                    }
                }) {
                    HStack(spacing: 8) {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                            Text("Installing... \(Int(installProgress * 100))%")
                                .font(.system(size: 14, weight: .medium))
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 14, weight: .medium))
                            Text("Install")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.borderless)
                .disabled(isInstalling)
                .opacity(isInstalling ? 0.8 : 1.0)
            }
        }
        .padding(24)
    }

    private func modernDetailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}

#Preview {
    EpicGamesLibraryView()
        .environmentObject(EpicGamesManager.shared)
}
