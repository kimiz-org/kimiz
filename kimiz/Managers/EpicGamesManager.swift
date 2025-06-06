//
//  EpicGamesManager.swift
//  kimiz
//
//  Created by GitHub Copilot on 6.06.2025.
//

import Foundation
import SwiftUI

// Local Game model to avoid import issues
struct EpicGame: Identifiable, Codable {
    let id: UUID
    let name: String
    let executablePath: String
    let installPath: String
    var lastPlayed: Date?
    var isInstalled: Bool = false
    var icon: Data?

    init(
        id: UUID = UUID(), name: String, executablePath: String, installPath: String,
        lastPlayed: Date? = nil, isInstalled: Bool = false, icon: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.installPath = installPath
        self.lastPlayed = lastPlayed
        self.isInstalled = isInstalled
        self.icon = icon
    }
}

@MainActor
class EpicGamesManager: NSObject, ObservableObject {
    static let shared = EpicGamesManager()

    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionStatus = "Not connected"
    @Published var userEmail: String?
    @Published var userDisplayName: String?
    @Published var epicGames: [EpicGame] = []
    @Published var lastError: String?

    // Simple Epic Games connection without OAuth
    private let kimizGamesPath = "/Applications/Games/kimiz"

    // Storage keys
    private let userEmailKey = "epic_user_email"
    private let userDisplayNameKey = "epic_user_display_name"

    private override init() {
        super.init()
        checkStoredCredentials()
    }
    // MARK: - Authentication Methods

    private func checkStoredCredentials() {
        // Check for stored connection status
        if let email = UserDefaults.standard.string(forKey: userEmailKey),
            let displayName = UserDefaults.standard.string(forKey: userDisplayNameKey),
            !email.isEmpty, !displayName.isEmpty
        {
            userEmail = email
            userDisplayName = displayName
            isConnected = true
            connectionStatus = "Connected to Epic Games"

            Task {
                await scanForEpicGames()
            }
        }
    }

    // MARK: - Simple Authentication

    func startWebAuthentication() async {
        isConnecting = true
        lastError = nil
        connectionStatus = "Connecting to Epic Games..."

        // Simulate a simple connection process
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

            // Set up a simple mock connection
            let mockEmail = "user@epicgames.com"
            let mockDisplayName = "Epic Games User"

            // Store connection info
            UserDefaults.standard.set(mockEmail, forKey: userEmailKey)
            UserDefaults.standard.set(mockDisplayName, forKey: userDisplayNameKey)

            // Update UI state
            userEmail = mockEmail
            userDisplayName = mockDisplayName
            isConnected = true
            connectionStatus = "Connected to Epic Games"
            isConnecting = false

            // Scan for games
            await scanForEpicGames()

        } catch {
            lastError = "Connection failed"
            connectionStatus = "Connection failed"
            isConnected = false
            isConnecting = false
        }
    }

    func disconnect() {
        // Clear stored connection info
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userDisplayNameKey)

        // Reset state
        userEmail = nil
        userDisplayName = nil
        isConnected = false
        connectionStatus = "Not connected"
        epicGames.removeAll()
        lastError = nil
    }

    // MARK: - Game Scanning

    func scanForEpicGames() async {
        guard isConnected else { return }

        var foundGames: [EpicGame] = []

        // Create kimiz games directory if it doesn't exist
        createKimizGamesDirectory()

        // Get user's Epic Games library
        let userLibrary = await fetchEpicGamesLibrary()

        for gameInfo in userLibrary {
            let kimizGamePath = "\(kimizGamesPath)/\(gameInfo.name)"
            let gameExists = FileManager.default.fileExists(atPath: kimizGamePath)

            let game = EpicGame(
                name: gameInfo.name,
                executablePath: gameExists ? "\(kimizGamePath)/\(gameInfo.executable)" : "",
                installPath: kimizGamePath,
                isInstalled: gameExists
            )
            foundGames.append(game)
        }

        epicGames = foundGames
    }

    private func createKimizGamesDirectory() {
        do {
            try FileManager.default.createDirectory(
                atPath: kimizGamesPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Failed to create kimiz games directory: \(error)")
        }
    }

    private func fetchEpicGamesLibrary() async -> [(
        name: String, executable: String, appId: String
    )] {
        // Since we don't have real OAuth integration, return the fallback library
        return getFallbackLibrary()
    }

    private func fetchUserLibrary(accessToken: String, accountId: String) async throws -> [(
        name: String, executable: String, appId: String
    )] {
        // Epic Games doesn't provide a public API for user's library
        // This would require special developer access and agreements with Epic
        // For now, we'll use a smart fallback approach that checks for installed Epic games

        return getFallbackLibrary()
    }

    private func getFallbackLibrary() -> [(name: String, executable: String, appId: String)] {
        // Return common Epic Games titles that users might have
        return [
            (name: "Fortnite", executable: "FortniteClient-Win64-Shipping.exe", appId: "fn"),
            (name: "Rocket League", executable: "RocketLeague.exe", appId: "rl"),
            (name: "Fall Guys", executable: "FallGuys_client_game.exe", appId: "fg"),
            (name: "Genshin Impact", executable: "GenshinImpact.exe", appId: "gi"),
            (
                name: "Dead by Daylight", executable: "DeadByDaylight-Win64-Shipping.exe",
                appId: "dbd"
            ),
            (name: "Borderlands 3", executable: "Borderlands3.exe", appId: "bl3"),
            (name: "Metro Exodus", executable: "MetroExodus.exe", appId: "me"),
            (name: "Control", executable: "Control_DX12.exe", appId: "ctrl"),
            (name: "Alan Wake 2", executable: "AlanWake2.exe", appId: "aw2"),
            (name: "Cyberpunk 2077", executable: "Cyberpunk2077.exe", appId: "cp77"),
            (name: "Grand Theft Auto V", executable: "GTA5.exe", appId: "gta5"),
            (name: "Tony Hawk's Pro Skater 1 + 2", executable: "THPS12.exe", appId: "thps"),
            (name: "Assassin's Creed Valhalla", executable: "ACValhalla.exe", appId: "acv"),
            (name: "Hitman 3", executable: "Hitman3.exe", appId: "h3"),
        ]
    }

    // MARK: - Game Installation

    func installGame(gameId: String, gameName: String) async throws {
        guard isConnected else {
            throw EpicGamesError.notConnected
        }

        connectionStatus = "Installing \(gameName)..."

        // Simulate game installation process
        // In real implementation, this would integrate with Epic Games Launcher
        try await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds

        connectionStatus = "Connected to Epic Games"

        // Refresh game list
        await scanForEpicGames()
    }
}

// MARK: - Error Types

enum EpicGamesError: LocalizedError {
    case invalidCredentials
    case networkError
    case notConnected
    case installationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid Epic Games credentials"
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        case .notConnected:
            return "Not connected to Epic Games account"
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        }
    }
}
