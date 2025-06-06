//
//  EpicGamesManager.swift
//  kimiz
//
//  Created by GitHub Copilot on 6.06.2025.
//

import AuthenticationServices
import Foundation
import SwiftUI

@MainActor
class EpicGamesManager: ObservableObject {
    static let shared = EpicGamesManager()

    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionStatus = "Not connected"
    @Published var userEmail: String?
    @Published var userDisplayName: String?
    @Published var epicGames: [Game] = []
    @Published var lastError: String?

    // Use UserDefaults to avoid keychain prompts
    private let userDefaults = UserDefaults.standard
    private let kimizGamesPath = "/Applications/Games/kimiz"

    private init() {
        // Check for existing connection without prompts
        checkStoredConnection()
    }

    // MARK: - Public Connection Methods

    func checkStoredConnection() {
        // Check UserDefaults for existing connection (safer than keychain for demo)
        if let token = userDefaults.string(forKey: "epic_demo_token"),
            !token.isEmpty,
            let email = userDefaults.string(forKey: "epic_demo_email"),
            let displayName = userDefaults.string(forKey: "epic_demo_display_name")
        {

            userEmail = email
            userDisplayName = displayName
            isConnected = true
            connectionStatus = "Connected to Epic Games (Demo Mode)"

            Task {
                await scanForEpicGames()
            }
        }
    }

    // MARK: - Web-based Authentication

    func startWebAuthentication() async {
        isConnecting = true
        connectionStatus = "Starting Epic Games authentication..."
        lastError = nil

        do {
            // For now, we'll simulate a successful Epic Games connection
            // In a real implementation, this would integrate with Epic Games OAuth
            connectionStatus = "Simulating Epic Games connection..."
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

            // Simulate successful authentication
            let simulatedToken = "epic_demo_token_\(Date().timeIntervalSince1970)"
            let simulatedUser = EpicUserInfo(
                id: "demo_user_id",
                displayName: "Epic Games Demo User",
                email: "demo@epicgames.com"
            )

            // Store credentials in UserDefaults (safer for demo)
            userDefaults.set(simulatedToken, forKey: "epic_demo_token")
            userDefaults.set(simulatedUser.email, forKey: "epic_demo_email")
            userDefaults.set(simulatedUser.displayName, forKey: "epic_demo_display_name")

            userEmail = simulatedUser.email
            userDisplayName = simulatedUser.displayName
            isConnected = true
            connectionStatus = "Connected to Epic Games (Demo Mode)"
            isConnecting = false

            // Scan for Epic Games
            await scanForEpicGames()

        } catch {
            lastError = error.localizedDescription
            connectionStatus = "Authentication failed"
            isConnected = false
            isConnecting = false
        }
    }

    func disconnect() {
        // Remove stored demo credentials
        userDefaults.removeObject(forKey: "epic_demo_token")
        userDefaults.removeObject(forKey: "epic_demo_email")
        userDefaults.removeObject(forKey: "epic_demo_display_name")

        userEmail = nil
        userDisplayName = nil
        isConnected = false
        connectionStatus = "Not connected"
        epicGames.removeAll()
    }

    // MARK: - Game Scanning

    func scanForEpicGames() async {
        guard isConnected else { return }

        var foundGames: [Game] = []

        // Create kimiz games directory if it doesn't exist
        createKimizGamesDirectory()

        // Get user's Epic Games library (simulated)
        let userLibrary = await fetchEpicGamesLibrary()

        for gameInfo in userLibrary {
            let kimizGamePath = "\(kimizGamesPath)/\(gameInfo.name)"
            let gameExists = FileManager.default.fileExists(atPath: kimizGamePath)

            let game = Game(
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
        // Simulate fetching user's Epic Games library
        // In real implementation, this would call Epic Games API

        // Return a simulated library of popular Epic games
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
        ]
    }

    // MARK: - Game Installation

    func installGame(gameId: String, gameName: String) async throws {
        guard isConnected else {
            throw EpicGamesError.notConnected
        }

        connectionStatus = "Installing \(gameName)..."

        // Simulate game installation process
        try await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds

        connectionStatus = "Connected to Epic Games (Demo Mode)"

        // Refresh game list
        await scanForEpicGames()
    }
}

// MARK: - Epic Games Errors

enum EpicGamesError: LocalizedError {
    case invalidCredentials
    case networkError
    case notConnected
    case installationFailed(String)
    case invalidAuthURL
    case authenticationCancelled
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        case .notConnected:
            return "Not connected to Epic Games account"
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        case .invalidAuthURL:
            return "Invalid authentication URL"
        case .authenticationCancelled:
            return "Authentication was cancelled"
        case .serverError:
            return "Server error occurred during authentication"
        }
    }
}

// MARK: - Epic User Info

struct EpicUserInfo: Codable {
    let id: String
    let displayName: String
    let email: String

    var encoded: String {
        if let data = try? JSONEncoder().encode(self),
            let string = String(data: data, encoding: .utf8)
        {
            return string
        }
        return ""
    }

    static func decode(from string: String) -> EpicUserInfo? {
        guard let data = string.data(using: .utf8),
            let userInfo = try? JSONDecoder().decode(EpicUserInfo.self, from: data)
        else {
            return nil
        }
        return userInfo
    }
}
