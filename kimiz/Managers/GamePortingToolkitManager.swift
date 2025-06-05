//
//  GamePortingToolkitManager.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Foundation
import SwiftUI

// MARK: - Game Porting Toolkit Manager

@MainActor
class GamePortingToolkitManager: ObservableObject {
    static let shared = GamePortingToolkitManager()

    @Published var isGPTKInstalled = false
    @Published var isInitializing = false
    @Published var initializationStatus = "Checking Game Porting Toolkit..."
    @Published var installedGames: [Game] = []
    @Published var lastError: String?

    // Installation properties
    @Published var isInstallingComponents = false
    @Published var installationProgress: Double = 0.0
    @Published var installationStatus = ""

    private let fileManager = FileManager.default
    private let defaultBottlePath: String

    private init() {
        self.defaultBottlePath =
            NSString(string: "~/Library/Application Support/kimiz/gptk-bottles/default")
            .expandingTildeInPath

        Task {
            await checkGPTKInstallation()
        }
    }

    // MARK: - GPTK Installation Check

    func checkGPTKInstallation() async {
        await MainActor.run {
            isInitializing = true
            initializationStatus = "Checking Game Porting Toolkit installation..."
        }

        let isInstalled = isGamePortingToolkitInstalled()

        await MainActor.run {
            self.isGPTKInstalled = isInstalled
            self.isInitializing = false

            if isInstalled {
                self.initializationStatus = "Game Porting Toolkit ready"
            } else {
                self.initializationStatus = "Game Porting Toolkit not found"
                self.lastError = "Please install Game Porting Toolkit from Apple Developer portal"
            }
        }

        if isInstalled {
            await scanForGames()
        }
    }

    func isGamePortingToolkitInstalled() -> Bool {
        // Check common GPTK installation paths
        let commonPaths = [
            "/usr/local/bin/wine64",
            "/opt/homebrew/bin/wine64",
            "/usr/local/lib/wine",
            "/opt/homebrew/lib/wine"
        ]
        
        // Also check for the actual GPTK directories
        let gptkPaths = [
            "/usr/local/share/game-porting-toolkit",
            "/opt/homebrew/share/game-porting-toolkit"
        ]
        
        // Check if at least one wine64 binary exists and one GPTK directory exists
        let hasWine = commonPaths.prefix(2).contains { path in
            FileManager.default.fileExists(atPath: path)
        }
        
        let hasGPTK = gptkPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        } || commonPaths.suffix(2).contains { path in
            FileManager.default.fileExists(atPath: path)
        }
        
        return hasWine && hasGPTK
    }

    func getGamePortingToolkitVersion() -> String? {
        guard isGamePortingToolkitInstalled() else { return nil }

        // Try different wine64 paths
        let winePaths = [
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64"
        ]
        
        guard let winePath = winePaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            return nil
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: winePath)
        task.arguments = ["--version"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(
                in: .whitespacesAndNewlines)

            return output
        } catch {
            return nil
        }
    }

    // Check if Steam is already installed
    func isSteamInstalled() -> Bool {
        let steamPath = defaultBottlePath + "/drive_c/Program Files (x86)/Steam/steam.exe"
        return fileManager.fileExists(atPath: steamPath)
    }

    // MARK: - Game Management

    func scanForGames() async {
        let steamPath = defaultBottlePath + "/drive_c/Program Files (x86)/Steam/steam.exe"

        var games: [Game] = []

        if fileManager.fileExists(atPath: steamPath) {
            var steamGame = Game(
                name: "Steam",
                executablePath: steamPath,
                installPath: defaultBottlePath + "/drive_c/Program Files (x86)/Steam"
            )
            steamGame.isInstalled = true
            games.append(steamGame)
        }

        await MainActor.run {
            self.installedGames = games
        }
    }

    func launchGame(_ game: Game) async throws {
        guard isGPTKInstalled else {
            throw GPTKError.notInstalled
        }

        guard fileManager.fileExists(atPath: game.executablePath) else {
            throw GPTKError.gameNotFound(game.executablePath)
        }

        try await runGame(executablePath: game.executablePath)

        // Update last played time
        if let index = installedGames.firstIndex(where: { $0.id == game.id }) {
            var updatedGame = installedGames[index]
            updatedGame.lastPlayed = Date()
            installedGames[index] = updatedGame
        }
    }

    func runGame(executablePath: String) async throws {
        guard let winePath = ["/opt/homebrew/bin/wine64", "/usr/local/bin/wine64"].first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw GPTKError.notInstalled
        }
        
        let environment = getOptimizedEnvironment()

        let task = Process()
        task.executableURL = URL(fileURLWithPath: winePath)
        task.arguments = [executablePath]
        task.environment = environment

        try task.run()
        // Don't wait for completion as games should run in background
    }

    // MARK: - GPTK Optimization

    func getOptimizedEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment

        // Game Porting Toolkit specific optimizations
        environment["WINEPREFIX"] = defaultBottlePath
        environment["WINEDEBUG"] = "-all"
        environment["MTL_HUD_ENABLED"] = "1"
        environment["WINEESYNC"] = "1"
        environment["DXVK_ASYNC"] = "1"
        environment["WINE_LARGE_ADDRESS_AWARE"] = "1"
        environment["MTL_SHADER_VALIDATION"] = "0"
        environment["MTL_DEBUG_LAYER"] = "0"

        // Memory and performance optimizations
        environment["WINE_CPU_TOPOLOGY"] = "4:2"
        environment["STAGING_WRITECOPY"] = "1"
        environment["STAGING_SHARED_MEMORY"] = "1"

        // DirectX optimizations
        environment["DXVK_STATE_CACHE"] = "1"
        environment["DXVK_LOG_LEVEL"] = "none"

        // Audio optimizations
        environment["PULSE_LATENCY_MSEC"] = "60"

        return environment
    }

    // MARK: - Installation

    /// Check if Homebrew is installed
    private func isHomebrewInstalled() -> Bool {
        let homebrewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"      // Intel
        ]
        
        return homebrewPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }
    }
    
    /// Get the correct brew path for the system
    private func getBrewPath() -> String? {
        let homebrewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"      // Intel
        ]
        
        return homebrewPaths.first { path in
            FileManager.default.fileExists(atPath: path)
        }
    }

    /// Install Game Porting Toolkit via Homebrew (requires Homebrew to be pre-installed)
    func installGamePortingToolkit() async throws {
        // Check if Homebrew is available
        guard isHomebrewInstalled(), let brewPath = getBrewPath() else {
            throw GPTKError.homebrewRequired
        }

        await MainActor.run {
            installationProgress = 0.2
            installationStatus = "Checking system architecture..."
        }

        // Check if we're on Apple Silicon and need Rosetta 2
        let isAppleSilicon = ProcessInfo.processInfo.environment["BREW_PREFIX"] == "/opt/homebrew" || 
                           FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
        
        if isAppleSilicon {
            await MainActor.run {
                installationProgress = 0.3
                installationStatus = "Installing under Rosetta 2 for x86_64 compatibility..."
            }
        }

        // Add Apple's tap first
        let tapProcess = Process()
        if isAppleSilicon {
            tapProcess.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
            tapProcess.arguments = ["-x86_64", brewPath, "tap", "apple/apple"]
        } else {
            tapProcess.executableURL = URL(fileURLWithPath: brewPath)
            tapProcess.arguments = ["tap", "apple/apple"]
        }

        try await withCheckedThrowingContinuation { continuation in
            tapProcess.terminationHandler = { process in
                continuation.resume()
            }
            do {
                try tapProcess.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        await MainActor.run {
            installationProgress = 0.6
            installationStatus = "Installing Game Porting Toolkit (this may take several minutes)..."
        }

        let process = Process()
        if isAppleSilicon {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
            process.arguments = ["-x86_64", brewPath, "install", "apple/apple/game-porting-toolkit"]
        } else {
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "apple/apple/game-porting-toolkit"]
        }

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorMessage = isAppleSilicon ? 
                        "Failed to install Game Porting Toolkit. Make sure Rosetta 2 is installed: 'softwareupdate --install-rosetta'" :
                        "Failed to install Game Porting Toolkit"
                    continuation.resume(
                        throwing: GPTKError.installationFailed(errorMessage))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func installSteam() async throws {
        guard isGPTKInstalled else {
            throw GPTKError.notInstalled
        }

        await MainActor.run {
            initializationStatus = "Downloading Steam installer..."
        }

        // Create bottle directory if it doesn't exist
        try fileManager.createDirectory(
            atPath: defaultBottlePath, withIntermediateDirectories: true)

        // Download Steam installer
        let steamURL = URL(
            string: "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe")!
        let tempDir = fileManager.temporaryDirectory
        let installerPath = tempDir.appendingPathComponent("SteamSetup.exe")

        let (data, _) = try await URLSession.shared.data(from: steamURL)
        try data.write(to: installerPath)

        await MainActor.run {
            initializationStatus = "Installing Steam..."
        }

        // Run Steam installer
        let environment = getOptimizedEnvironment()
        
        guard let winePath = ["/opt/homebrew/bin/wine64", "/usr/local/bin/wine64"].first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw GPTKError.notInstalled
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: winePath)
        task.arguments = [installerPath.path, "/S"]  // Silent install
        task.environment = environment

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw GPTKError.installationFailed("Steam installation failed")
        }

        // Clean up installer
        try? fileManager.removeItem(at: installerPath)

        await MainActor.run {
            initializationStatus = "Steam installed successfully"
        }

        // Rescan for games
        await scanForGames()
    }
}

// MARK: - Error Types

enum GPTKError: LocalizedError {
    case notInstalled
    case gameNotFound(String)
    case installationFailed(String)
    case homebrewRequired
    case rosettaRequired

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Game Porting Toolkit is not installed"
        case .gameNotFound(let path):
            return "Game executable not found: \(path)"
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        case .homebrewRequired:
            return "Homebrew is required to install Game Porting Toolkit. Please install Homebrew first."
        case .rosettaRequired:
            return "Rosetta 2 is required on Apple Silicon Macs. Please install it by running: softwareupdate --install-rosetta"
        }
    }
}
