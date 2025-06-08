//
//  EpicGamesManager.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
//

import Foundation
import SwiftUI

// Epic Game model for library integration
struct EpicGame: Identifiable, Codable {
    let id: UUID
    let appName: String  // Epic's internal app name
    let displayName: String
    let description: String?
    let publisher: String?
    let developer: String?
    var iconUrl: String?
    var imageUrl: String?
    var isOwned: Bool = false
    var isInstalled: Bool = false
    var installPath: String?
    var executablePath: String?
    var lastPlayed: Date?

    // Installation metadata
    var installSize: Int64?  // Size in bytes
    var version: String?
    var downloadUrl: String?  // Epic Games Store download manifest URL

    init(
        id: UUID = UUID(),
        appName: String,
        displayName: String,
        description: String? = nil,
        publisher: String? = nil,
        developer: String? = nil,
        iconUrl: String? = nil,
        imageUrl: String? = nil,
        isOwned: Bool = false,
        isInstalled: Bool = false,
        installPath: String? = nil,
        executablePath: String? = nil,
        lastPlayed: Date? = nil,
        installSize: Int64? = nil,
        version: String? = nil,
        downloadUrl: String? = nil
    ) {
        self.id = id
        self.appName = appName
        self.displayName = displayName
        self.description = description
        self.publisher = publisher
        self.developer = developer
        self.iconUrl = iconUrl
        self.imageUrl = imageUrl
        self.isOwned = isOwned
        self.isInstalled = isInstalled
        self.installPath = installPath
        self.executablePath = executablePath
        self.lastPlayed = lastPlayed
        self.installSize = installSize
        self.version = version
        self.downloadUrl = downloadUrl
    }
}

// User account information
struct EpicUserAccount: Codable {
    let id: String
    let displayName: String
    let email: String?
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date

    var isTokenValid: Bool {
        return Date() < expiresAt
    }
}

@MainActor
internal class EpicGamesManager: NSObject, ObservableObject {
    internal static let shared = EpicGamesManager()

    // Account connection state
    @Published var isConnected: Bool = false
    @Published var userAccount: EpicUserAccount?
    @Published var epicGames: [EpicGame] = []

    // UI State
    @Published var lastError: String?
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""

    // Installation state
    @Published var installingGames: Set<String> = []  // Set of app names being installed
    @Published var downloadProgress: [String: Double] = [:]  // App name -> progress

    private let kimizGamesPath = "/Applications/Games/kimiz"
    private let userDefaults = UserDefaults.standard
    private let accountKey = "kimiz.epicAccount"
    private let gamesKey = "kimiz.epicGames"

    // Default bottle path for game installations
    private var selectedBottlePath: String? {
        let defaultPath = NSString(
            string: "~/Library/Application Support/kimiz/gptk-bottles/default"
        ).expandingTildeInPath
        return FileManager.default.fileExists(atPath: defaultPath) ? defaultPath : nil
    }

    private override init() {
        super.init()
        loadAccountFromStorage()
        loadGamesFromStorage()

        // Auto-refresh if account is connected
        if isConnected {
            Task {
                await refreshGameLibrary()
            }
        }
    }

    // MARK: - Account Management

    /// Connect Epic Games account using OAuth-like flow
    func connectAccount() async {
        isLoading = true
        loadingMessage = "Connecting to Epic Games..."
        lastError = nil

        // This would normally use Epic's OAuth flow
        // For now, we'll simulate the connection process
        let mockAccount = EpicUserAccount(
            id: "mock_user_id",
            displayName: "Epic Games User",
            email: "user@example.com",
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            expiresAt: Date().addingTimeInterval(3600)  // 1 hour from now
        )

        userAccount = mockAccount
        isConnected = true
        saveAccountToStorage()

        // Fetch user's game library
        await refreshGameLibrary()

        isLoading = false
        loadingMessage = ""
    }

    /// Disconnect Epic Games account
    func disconnectAccount() {
        userAccount = nil
        isConnected = false
        epicGames = []

        // Clear stored data
        userDefaults.removeObject(forKey: accountKey)
        userDefaults.removeObject(forKey: gamesKey)

        print("[EpicGamesManager] Account disconnected")
    }

    /// Refresh access token if needed
    private func refreshTokenIfNeeded() async throws {
        guard var account = userAccount else {
            throw EpicGamesError.notConnected
        }

        if account.isTokenValid {
            return  // Token is still valid
        }

        // In a real implementation, you'd use the refresh token to get a new access token
        // For now, we'll simulate this
        account.accessToken = "new_mock_access_token"
        account.expiresAt = Date().addingTimeInterval(3600)

        userAccount = account
        saveAccountToStorage()
    }

    // MARK: - Game Library Management

    /// Refresh the user's Epic Games library
    func refreshGameLibrary() async {
        guard isConnected else {
            lastError = "Account not connected"
            return
        }

        isLoading = true
        loadingMessage = "Loading game library..."

        do {
            try await refreshTokenIfNeeded()

            // In a real implementation, you'd call Epic's API to get the user's library
            // For now, we'll simulate with some popular Epic Games Store titles
            let mockGames = await getMockEpicGamesLibrary()

            epicGames = mockGames
            saveGamesToStorage()

        } catch {
            lastError = "Failed to load library: \(error.localizedDescription)"
            print("[EpicGamesManager] Library refresh failed: \(error)")
        }

        isLoading = false
        loadingMessage = ""
    }

    /// Get mock Epic Games library for demonstration
    private func getMockEpicGamesLibrary() async -> [EpicGame] {
        // Simulate network delay
        try? await Task.sleep(for: .seconds(1))

        return [
            EpicGame(
                appName: "fortnite",
                displayName: "Fortnite",
                description:
                    "Battle Royale, building skills and destructible environments combined with intense PvP combat.",
                publisher: "Epic Games",
                developer: "Epic Games",
                iconUrl: "https://cdn2.unrealengine.com/fortnite-icon-1200x1200-9e6ac3b4b53b.png",
                isOwned: true,
                installSize: 26_843_545_600  // ~25GB
            ),
            EpicGame(
                appName: "gta5",
                displayName: "Grand Theft Auto V",
                description: "The biggest, most dynamic and most diverse open world ever created.",
                publisher: "Rockstar Games",
                developer: "Rockstar North",
                iconUrl:
                    "https://cdn1.epicgames.com/salesEvent/salesEvent/EGS_GrandTheftAutoV_RockstarGames_S2_1200x1600-96ce3c69120a7ad2cd0efc24b88b06b2.jpg",
                isOwned: true,
                installSize: 94_371_840_000  // ~88GB
            ),
            EpicGame(
                appName: "rocket-league",
                displayName: "Rocket League",
                description:
                    "Rocket League is a high-powered hybrid of arcade-style soccer and vehicular mayhem.",
                publisher: "Psyonix LLC",
                developer: "Psyonix LLC",
                iconUrl:
                    "https://cdn1.epicgames.com/salesEvent/salesEvent/EGS_RocketLeague_Psyonix_S2_1200x1600-5e2c2bc3edc2d7b5b1d56e90e87cf5c2.jpg",
                isOwned: true,
                installSize: 21_474_836_480  // ~20GB
            ),
            EpicGame(
                appName: "fall-guys",
                displayName: "Fall Guys",
                description: "Stumble through chaotic obstacle courses with friends online.",
                publisher: "Epic Games",
                developer: "Mediatonic",
                iconUrl:
                    "https://cdn1.epicgames.com/salesEvent/salesEvent/EGS_FallGuys_Mediatonic_S2_1200x1600-87b21f87baec72fb8ff54f7e6db6eed5.jpg",
                isOwned: true,
                installSize: 8_589_934_592  // ~8GB
            ),
            EpicGame(
                appName: "borderlands3",
                displayName: "Borderlands 3",
                description:
                    "The original shooter-looter returns, packing bazillions of guns and a mayhem-fueled adventure!",
                publisher: "2K",
                developer: "Gearbox Software",
                iconUrl:
                    "https://cdn1.epicgames.com/salesEvent/salesEvent/EGS_Borderlands3_GearboxSoftware_S2_1200x1600-ba4f82f5cdf7d0fff78fb29c3b0e06f7.jpg",
                isOwned: true,
                installSize: 75_161_927_680  // ~70GB
            ),
            EpicGame(
                appName: "cyberpunk2077",
                displayName: "Cyberpunk 2077",
                description:
                    "An open-world, action-adventure RPG set in the megalopolis of Night City.",
                publisher: "CD PROJEKT RED",
                developer: "CD PROJEKT RED",
                iconUrl:
                    "https://cdn1.epicgames.com/salesEvent/salesEvent/EGS_Cyberpunk2077_CDPROJEKTRED_S2_1200x1600-b1c11ac0f39f6d7b1a1893dde6f95dc8.jpg",
                isOwned: true,
                installSize: 70_866_960_384  // ~66GB
            ),
            EpicGame(
                appName: "genshin-impact",
                displayName: "Genshin Impact",
                description:
                    "Step into Teyvat, a vast world teeming with life and flowing with elemental energy.",
                publisher: "miHoYo Limited",
                developer: "miHoYo Limited",
                iconUrl:
                    "https://cdn1.epicgames.com/salesEvent/salesEvent/EGS_GenshinImpact_miHoYoLimited_S2_1200x1600-09b53d0b3a48e48e56de76fc7b5c8b25.jpg",
                isOwned: true,
                installSize: 60_129_542_144  // ~56GB
            ),
        ]
    }

    // MARK: - Game Installation

    /// Install a game from Epic Games Store
    func installGame(_ game: EpicGame) async {
        guard isConnected else {
            lastError = "Account not connected"
            return
        }

        guard game.isOwned else {
            lastError = "Game not owned. Please purchase from Epic Games Store."
            return
        }

        guard !installingGames.contains(game.appName) else {
            lastError = "Game is already being installed"
            return
        }

        installingGames.insert(game.appName)
        downloadProgress[game.appName] = 0.0
        lastError = nil

        do {
            try await performGameInstallation(game)

            // Update game as installed
            if let index = epicGames.firstIndex(where: { $0.id == game.id }) {
                epicGames[index].isInstalled = true
                epicGames[index].installPath = getGameInstallPath(for: game)
                epicGames[index].executablePath = findGameExecutable(for: game)
            }

            saveGamesToStorage()

        } catch {
            lastError = "Failed to install \(game.displayName): \(error.localizedDescription)"
            print("[EpicGamesManager] Installation failed for \(game.displayName): \(error)")
        }

        installingGames.remove(game.appName)
        downloadProgress.removeValue(forKey: game.appName)
    }

    /// Perform the actual game installation
    private func performGameInstallation(_ game: EpicGame) async throws {
        guard selectedBottlePath != nil else {
            throw EpicGamesError.installationFailed("No bottle available for installation")
        }

        // Create game installation directory
        let gameInstallPath = getGameInstallPath(for: game)
        try FileManager.default.createDirectory(
            atPath: gameInstallPath,
            withIntermediateDirectories: true
        )

        // Simulate download progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            downloadProgress[game.appName] = progress
            try await Task.sleep(for: .milliseconds(500))
        }

        // In a real implementation, you would:
        // 1. Download the game manifest from Epic's CDN
        // 2. Download game files in chunks
        // 3. Verify checksums
        // 4. Create Wine shortcuts and registry entries

        // For now, we'll create a mock executable
        let executablePath = "\(gameInstallPath)/\(game.appName).exe"
        let mockExecutableContent = """
            @echo off
            echo Starting \(game.displayName)...
            echo This is a mock executable for demonstration
            pause
            """

        try mockExecutableContent.write(
            to: URL(fileURLWithPath: executablePath),
            atomically: true,
            encoding: .utf8
        )

        print("[EpicGamesManager] Successfully installed \(game.displayName) to \(gameInstallPath)")
    }

    /// Launch an installed Epic game
    func launchGame(_ game: EpicGame) async throws {
        guard game.isInstalled, let executablePath = game.executablePath else {
            throw EpicGamesError.gameNotInstalled(game.displayName)
        }

        guard FileManager.default.fileExists(atPath: executablePath) else {
            throw EpicGamesError.gameNotFound(executablePath)
        }

        // Update last played time
        if let index = epicGames.firstIndex(where: { $0.id == game.id }) {
            epicGames[index].lastPlayed = Date()
        }
        saveGamesToStorage()

        // Launch the game using Wine/GPTK
        try await launchGameWithWine(executablePath: executablePath, gameName: game.displayName)
    }

    /// Launch game using Wine with optimized environment
    private func launchGameWithWine(executablePath: String, gameName: String) async throws {
        // Find Wine/GPTK executable - just verify it exists
        let possibleWinePaths = [
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
        ]

        guard
            possibleWinePaths.contains(where: {
                FileManager.default.fileExists(atPath: $0)
            })
        else {
            throw EpicGamesError.wineNotFound
        }

        print("[EpicGamesManager] Launching \(gameName) with Wine")
        print("[EpicGamesManager] Executable: \(executablePath)")

        // Use WineManager to launch the game
        // TODO: Fix WineManager scope issue
        /*
        let gameDirectory = (executablePath as NSString).deletingLastPathComponent
        guard let winePath = possibleWinePaths.first(where: {
            FileManager.default.fileExists(atPath: $0)
        }) else {
            throw EpicGamesError.wineNotFound
        }
        let environment = getOptimizedEnvironment()
        
        try await WineManager.shared.runWineProcess(
            winePath: winePath,
            executablePath: executablePath,
            environment: environment,
            workingDirectory: gameDirectory,
            defaultBottlePath: selectedBottlePath ?? ""
        )
        */

        // Temporary implementation - throw error until WineManager issue is resolved
        throw EpicGamesError.installationFailed("WineManager integration temporarily disabled")
    }

    // MARK: - Utility Methods

    private func getGameInstallPath(for game: EpicGame) -> String {
        guard let bottlePath = selectedBottlePath else {
            return ""
        }
        return "\(bottlePath)/drive_c/Program Files/Epic Games/\(game.displayName)"
    }

    private func findGameExecutable(for game: EpicGame) -> String? {
        let installPath = getGameInstallPath(for: game)
        // Look for common executable patterns
        let possibleExecutables = [
            "\(installPath)/\(game.appName).exe",
            "\(installPath)/\(game.displayName).exe",
            "\(installPath)/Binaries/Win64/\(game.appName).exe",
            "\(installPath)/Binaries/Win64/\(game.displayName).exe",
        ]

        return possibleExecutables.first { FileManager.default.fileExists(atPath: $0) }
    }

    /// Get optimized environment for Epic Games
    private func getOptimizedEnvironment() -> [String: String] {
        guard let bottlePath = selectedBottlePath else { return [:] }

        var environment: [String: String] = [:]
        environment["WINEPREFIX"] = bottlePath
        environment["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"
        environment["WINE_CPU_TOPOLOGY"] = "4:2"

        // Epic Games specific optimizations
        environment["MTL_FORCE_VALIDATION"] = "0"
        environment["METAL_DEVICE_WRAPPER_TYPE"] = "1"
        environment["MTL_CAPTURE_ENABLED"] = "0"
        environment["WINE_VK_INSTANCE_EXTENSIONS"] = ""
        environment["DXVK_FILTER_DEVICE_NAME"] = ""
        environment["VK_LOADER_DEBUG"] = "error"

        // Additional Epic Games fixes
        environment["MTL_SHADER_VALIDATION"] = "0"
        environment["MTL_DEBUG_LAYER"] = "0"
        environment["MTL_HUD_ENABLED"] = "0"
        environment["UE4_DISABLE_VULKAN"] = "1"
        environment["UE4_FORCE_DX11"] = "1"
        environment["EPIC_FORCE_OPENGL"] = "1"

        // Wine performance settings
        environment["WINEDEBUG"] = "-all"
        environment["WINEESYNC"] = "1"
        environment["WINE_LARGE_ADDRESS_AWARE"] = "1"

        return environment
    }

    // MARK: - Persistence

    private func saveAccountToStorage() {
        guard let account = userAccount else { return }

        do {
            let data = try JSONEncoder().encode(account)
            userDefaults.set(data, forKey: accountKey)
        } catch {
            print("[EpicGamesManager] Failed to save account: \(error)")
        }
    }

    private func loadAccountFromStorage() {
        guard let data = userDefaults.data(forKey: accountKey) else { return }

        do {
            let account = try JSONDecoder().decode(EpicUserAccount.self, from: data)
            userAccount = account
            isConnected = account.isTokenValid
        } catch {
            print("[EpicGamesManager] Failed to load account: \(error)")
        }
    }

    private func saveGamesToStorage() {
        do {
            let data = try JSONEncoder().encode(epicGames)
            userDefaults.set(data, forKey: gamesKey)
        } catch {
            print("[EpicGamesManager] Failed to save games: \(error)")
        }
    }

    private func loadGamesFromStorage() {
        guard let data = userDefaults.data(forKey: gamesKey) else { return }

        do {
            epicGames = try JSONDecoder().decode([EpicGame].self, from: data)
        } catch {
            print("[EpicGamesManager] Failed to load games: \(error)")
        }
    }
}

// MARK: - Error Types

enum EpicGamesError: LocalizedError {
    case notConnected
    case gameNotInstalled(String)
    case gameNotFound(String)
    case installationFailed(String)
    case wineNotFound

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Epic Games account not connected."
        case .gameNotInstalled(let gameName):
            return "\(gameName) is not installed."
        case .gameNotFound(let path):
            return "Game executable not found at \(path)."
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        case .wineNotFound:
            return "Wine or Game Porting Toolkit not found. Please install it first."
        }
    }
}
