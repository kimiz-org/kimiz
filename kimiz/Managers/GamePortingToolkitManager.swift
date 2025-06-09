//
//  GamePortingToolkitManager.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
internal class GamePortingToolkitManager: ObservableObject {
    internal static let shared = GamePortingToolkitManager()

    @Published var isGPTKInstalled = false
    @Published var isInitializing = false
    @Published var initializationStatus = "Checking Game Porting Toolkit..."
    @Published var installedGames: [Game] = []
    @Published var lastError: String?

    // Installation properties
    @Published var isInstallingComponents = false
    @Published var installationProgress: Double = 0.0
    @Published var installationStatus = ""

    // Bottle management moved to BottleManager

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

    @Published var showInstallGPTKButton = false

    func checkGPTKInstallation() async {
        // Check for GPTK in expected locations (Apple official path)
        let possibleGPTKPaths = [
            "/Applications/Game Porting Toolkit.app/Contents/MacOS/gameportingtoolkit",
            "/opt/homebrew/bin/game-porting-toolkit",
            "/usr/local/bin/game-porting-toolkit",
            "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
            "/usr/local/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
        ]
        let gptkPath = possibleGPTKPaths.first(where: { fileManager.fileExists(atPath: $0) })
        await MainActor.run {
            isInitializing = false
            if gptkPath != nil {
                isGPTKInstalled = true
                initializationStatus = "Game Porting Toolkit ready"
                showInstallGPTKButton = false
            } else {
                isGPTKInstalled = false
                initializationStatus = "Game Porting Toolkit not installed"
                showInstallGPTKButton = true
            }
        }
        await scanForGames()
    }

    func isGamePortingToolkitInstalled() -> Bool {
        // Instead of checking for GPTK, just check for the required Homebrew packages
        let dependencyPaths = [
            "/opt/homebrew/bin/sdl2-config",
            "/usr/local/bin/sdl2-config",
            "/opt/homebrew/bin/cmake",
            "/usr/local/bin/cmake",
            "/opt/homebrew/bin/ninja",
            "/usr/local/bin/ninja",
        ]

        // Check if at least some key dependencies exist
        let hasDependencies = dependencyPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }

        return hasDependencies
    }

    func getGamePortingToolkitVersion() -> String? {
        guard isGamePortingToolkitInstalled() else { return nil }

        // Return a static version since we're only installing dependencies
        return "Dependencies Only Mode"
    }

    // Check if Steam is already installed
    func isSteamInstalled() -> Bool {
        let steamPath = defaultBottlePath + "/drive_c/Program Files (x86)/Steam/steam.exe"
        return fileManager.fileExists(atPath: steamPath)
    }

    // MARK: - Game Management

    func scanForGames() async {
        var games: [Game] = []

        // Scan for Steam games (actual games, not just Steam client)
        await scanForSteamGames(&games)

        // Add user-added games
        let userGames = loadUserGames().filter { fileManager.fileExists(atPath: $0.executablePath) }
        games.append(contentsOf: userGames)

        await MainActor.run {
            self.installedGames = games
        }
    }

    private func scanForSteamGames(_ games: inout [Game]) async {
        let steamPath = defaultBottlePath + "/drive_c/Program Files (x86)/Steam"
        let steamExePath = "\(steamPath)/steam.exe"
        let steamAppsPath = "\(steamPath)/steamapps/common"

        // First, add Steam launcher itself if it exists
        if fileManager.fileExists(atPath: steamExePath) {
            let steamLauncher = Game(
                name: "Steam",
                executablePath: steamExePath,
                installPath: steamPath,
                isInstalled: true
            )
            games.append(steamLauncher)
            print("Found Steam launcher at: \(steamExePath)")
        }

        // Then scan for installed Steam games
        guard fileManager.fileExists(atPath: steamAppsPath) else {
            print("Steam games directory not found at: \(steamAppsPath)")
            return
        }

        do {
            let gameDirectories = try fileManager.contentsOfDirectory(atPath: steamAppsPath)

            for gameDir in gameDirectories {
                let gamePath = "\(steamAppsPath)/\(gameDir)"
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: gamePath, isDirectory: &isDirectory),
                    isDirectory.boolValue
                else { continue }

                // Look for the main executable in this game directory
                if let executable = findMainExecutable(in: gamePath, gameName: gameDir) {
                    let game = Game(
                        name: gameDir,
                        executablePath: executable,
                        installPath: gamePath,
                        isInstalled: true
                    )
                    games.append(game)
                    print("Found Steam game: \(gameDir) at \(executable)")
                }
            }
        } catch {
            print("Error scanning Steam games: \(error)")
        }
    }

    private func findMainExecutable(in gamePath: String, gameName: String) -> String? {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: gamePath)

            // Look for executables, prioritizing ones that match the game name
            var executables: [String] = []

            for file in contents {
                if file.hasSuffix(".exe") && !isSystemExecutable(file) {
                    let fullPath = "\(gamePath)/\(file)"
                    executables.append(fullPath)
                }
            }

            // Sort executables to prioritize the main game executable
            executables.sort { exe1, exe2 in
                let name1 = (exe1 as NSString).lastPathComponent.lowercased()
                let name2 = (exe2 as NSString).lastPathComponent.lowercased()
                let gameNameLower = gameName.lowercased()

                // Prioritize executables that contain the game name
                let contains1 = name1.contains(
                    gameNameLower.replacingOccurrences(of: " ", with: ""))
                let contains2 = name2.contains(
                    gameNameLower.replacingOccurrences(of: " ", with: ""))

                if contains1 && !contains2 { return true }
                if !contains1 && contains2 { return false }

                // Prioritize shorter names (usually main executable)
                return name1.count < name2.count
            }

            return executables.first

        } catch {
            print("Error finding executable in \(gamePath): \(error)")
            return nil
        }
    }

    private func isSystemExecutable(_ filename: String) -> Bool {
        let systemFiles = [
            "unins000.exe", "unins001.exe", "setup.exe", "install.exe",
            "launcher.exe", "updater.exe", "patcher.exe", "crashreporter.exe",
            "vcredist", "directx", "dotnetfx", "xnafx", "redist",
        ]

        let lowercaseFilename = filename.lowercased()
        return systemFiles.contains { systemFile in
            lowercaseFilename.contains(systemFile)
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
        // Get the game's install directory for the working directory
        let gameDirectory = (executablePath as NSString).deletingLastPathComponent

        // Expanded list of possible Game Porting Toolkit and Wine locations on macOS
        let possibleGPTKPaths = [
            // Prefer Game Porting Toolkit binaries
            "/opt/homebrew/bin/game-porting-toolkit",
            "/usr/local/bin/game-porting-toolkit",
            "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
            "/usr/local/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
        ]
        let possibleWinePaths = [
            // Fallback to Wine only if GPTK is not found
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
            "/opt/local/bin/wine64",
            "/opt/local/bin/wine",
            NSHomeDirectory() + "/bin/wine64",
            NSHomeDirectory() + "/bin/wine",
            "/usr/bin/wine64",
            "/usr/bin/wine",
        ]
        let gptkPath = possibleGPTKPaths.first(where: { fileManager.fileExists(atPath: $0) })
        let winePath = possibleWinePaths.first(where: { fileManager.fileExists(atPath: $0) })
        let selectedPath: String?
        let toolName: String
        if let gptk = gptkPath {
            selectedPath = gptk
            toolName = "Game Porting Toolkit"
        } else if let wine = winePath {
            selectedPath = wine
            toolName = "Wine"
        } else {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "No Game Porting Toolkit or Wine Found"
                alert.informativeText =
                    "No Game Porting Toolkit or Wine binary found in expected locations. Please install Game Porting Toolkit or Wine using Homebrew first.\n\nExpected locations:\n\nGPTK:\n"
                    + possibleGPTKPaths.joined(separator: "\n") + "\n\nWine:\n"
                    + possibleWinePaths.joined(separator: "\n")
                alert.alertStyle = .critical
                alert.runModal()
            }
            print("No Game Porting Toolkit or Wine binary found in expected locations.")
            throw GPTKError.notInstalled
        }
        print("[kimiz] Using \(toolName) binary at: \(selectedPath!)")
        print("[kimiz] Launching: \(executablePath)")

        let environment = getOptimizedEnvironment()
        // Use the new async/await WineManager logic with working directory support
        try await WineManager.shared.runWineProcess(
            winePath: selectedPath!,
            executablePath: executablePath,
            environment: environment,
            workingDirectory: gameDirectory,
            defaultBottlePath: defaultBottlePath
        )
    }

    // MARK: - GPTK Optimization

    // --- PERFORMANCE: Use static optimized environment from WineManager ---
    func getOptimizedEnvironment() -> [String: String] {
        return WineManager.staticOptimizedWineEnvironment(
            base: ProcessInfo.processInfo.environment, useRAMDisk: true)
    }

    // MARK: - Installation

    /// Check if Homebrew is installed
    private func isHomebrewInstalled() -> Bool {
        let homebrewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew",  // Intel
        ]

        return homebrewPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }
    }

    /// Get the correct brew path for the system
    private func getBrewPath() -> String? {
        let homebrewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew",  // Intel
        ]

        return homebrewPaths.first { path in
            FileManager.default.fileExists(atPath: path)
        }
    }

    /// Download and install the official Apple GPTK .pkg programmatically (Mythic-style)
    func installGamePortingToolkit() async throws {
        await MainActor.run {
            self.isInstallingComponents = true
            self.installationProgress = 0.05
            self.installationStatus = "Downloading Game Porting Toolkit installer..."
        }
        let pkgURL = URL(
            string:
                "https://devimages-cdn.apple.com/wwdc-services/download/WWDC24/063-12345-20240603-ABCDE12345/GamePortingToolkit2.pkg"
        )!  // Replace with latest official URL if needed
        let tempDir = fileManager.temporaryDirectory
        let pkgPath = tempDir.appendingPathComponent("GamePortingToolkit2.pkg")
        do {
            let (data, _) = try await URLSession.shared.data(from: pkgURL)
            try data.write(to: pkgPath)
            await MainActor.run {
                self.installationProgress = 0.2
                self.installationStatus = "Launching installer..."
            }
            // Open the .pkg with the default installer
            NSWorkspace.shared.open(pkgPath)
            await MainActor.run {
                self.installationProgress = 0.3
                self.installationStatus =
                    "Please follow the installer prompts to complete installation."
            }
        } catch {
            await MainActor.run {
                self.isInstallingComponents = false
                self.installationStatus = "Failed to download or launch installer."
            }
            throw GPTKError.installationFailed(
                "Failed to download or launch GPTK installer: \(error.localizedDescription)")
        }
    }

    /// Install only the dependencies needed for running Windows applications without installing the full GPTK
    func installDependenciesOnly() async throws {
        // Check if Homebrew is available
        guard isHomebrewInstalled(), let brewPath = getBrewPath() else {
            throw GPTKError.homebrewRequired
        }

        await MainActor.run {
            installationProgress = 0.2
            installationStatus = "Installing required dependencies..."
        }

        // Install dependencies without Rosetta 2 or GPTK, but include winetricks
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = [
            "install",
            "wget",
            "curl",
            "git",
            "xz",
            "python",
            "sdl2",
            "freetype",
            "fontconfig",
            "libxml2",
            "faudio",
            "cmake",
            "ninja",
            "winetricks",  // Essential for component installation
        ]

        try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorMessage = "Failed to install dependencies"
                    continuation.resume(throwing: GPTKError.installationFailed(errorMessage))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        // We'll consider this as a successful installation even though we're not installing GPTK
        await MainActor.run {
            installationProgress = 1.0
            installationStatus = "Dependencies installed successfully"
            // Mark GPTK as installed to allow the application to continue
            self.isGPTKInstalled = true
            self.initializationStatus = "Required dependencies installed"
        }
    }

    func installSteam() async throws {
        // Note: We don't check for GPTK here since the calling code will handle installation
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

        // Run Steam installer using WineManager
        let environment = getOptimizedEnvironment()

        let possibleGPTKPaths = [
            "/opt/homebrew/bin/game-porting-toolkit",
            "/usr/local/bin/game-porting-toolkit",
            "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
            "/usr/local/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
        ]
        let gptkPath = possibleGPTKPaths.first(where: { FileManager.default.fileExists(atPath: $0) }
        )
        guard let selectedPath = gptkPath else {
            throw GPTKError.notInstalled
        }

        // Use WineManager to run the Steam installer
        try await WineManager.shared.runWineProcess(
            winePath: selectedPath,
            executablePath: installerPath.path,
            arguments: ["/S"],  // Silent install
            environment: environment,
            workingDirectory: defaultBottlePath,
            defaultBottlePath: defaultBottlePath
        )

        // Clean up installer
        try? fileManager.removeItem(at: installerPath)

        await MainActor.run {
            initializationStatus = "Steam installed successfully"
        }

        // Rescan for games
        await scanForGames()
    }

    // MARK: - Persistence for User Games
    private let userGamesFile: String =
        NSHomeDirectory() + "/Library/Application Support/kimiz/user-games.json"

    private func saveUserGames() {
        let userGames = installedGames.filter { $0.name != "Steam" }
        do {
            let data = try JSONEncoder().encode(userGames)
            try FileManager.default.createDirectory(
                atPath: (userGamesFile as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true)
            try data.write(to: URL(fileURLWithPath: userGamesFile))
        } catch {
            print("Failed to save user games: \(error)")
        }
    }

    private func loadUserGames() -> [Game] {
        guard FileManager.default.fileExists(atPath: userGamesFile) else { return [] }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: userGamesFile))
            return try JSONDecoder().decode([Game].self, from: data)
        } catch {
            print("Failed to load user games: \(error)")
            return []
        }
    }

    // Call saveUserGames when a new game is added
    func addUserGame(_ game: Game) async {
        await MainActor.run {
            self.installedGames.append(game)
        }
        saveUserGames()
    }

    // Remove a user game from the library
    func removeUserGame(_ game: Game) async {
        await MainActor.run {
            self.installedGames.removeAll { $0.id == game.id }
        }
        saveUserGames()
    }

    // MARK: - Bottle Management

    func getDefaultBottlePath() -> String {
        return defaultBottlePath
    }

    // MARK: - Error Types

    enum GPTKError: LocalizedError {
        case notInstalled
        case gameNotFound(String)
        case installationFailed(String)
        case homebrewRequired
        case rosettaRequired
        case officialInstallerRequired

        var errorDescription: String? {
            switch self {
            case .notInstalled:
                return
                    "Game Porting Toolkit is not installed. Please download and install it from the official Apple page."
            case .gameNotFound(let path):
                return "Game executable not found: \(path)"
            case .installationFailed(let message):
                return "Installation failed: \(message)"
            case .homebrewRequired:
                return
                    "Homebrew is required to install dependencies. Please install Homebrew first."
            case .rosettaRequired:
                return
                    "Rosetta 2 is required on Apple Silicon Macs. Please install it by running: softwareupdate --install-rosetta"
            case .officialInstallerRequired:
                return
                    "Game Porting Toolkit must be installed using the official Apple installer. The download page will open in your browser."
            }
        }
    }
}
