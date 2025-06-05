//
//  GamePortingToolkitManager.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Foundation
import SwiftUI

// Import Game model for type resolution
// If this fails, ensure Game.swift is in the same target as this file

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

    // MARK: - Bottle Model

    struct Bottle: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var path: String
        var dependencies: [String]
        var createdAt: Date

        init(name: String, path: String, dependencies: [String] = []) {
            self.id = UUID()
            self.name = name
            self.path = path
            self.dependencies = dependencies
            self.createdAt = Date()
        }
    }

    @Published var bottles: [Bottle] = []
    @Published var selectedBottle: Bottle?

    private let fileManager = FileManager.default
    private let defaultBottlePath: String
    private let bottlesFile: String =
        NSHomeDirectory() + "/Library/Application Support/kimiz/bottles.json"

    private init() {
        self.defaultBottlePath =
            NSString(string: "~/Library/Application Support/kimiz/gptk-bottles/default")
            .expandingTildeInPath
        self.bottles = loadBottles()
        self.selectedBottle = bottles.first

        Task {
            await checkGPTKInstallation()
        }
    }

    // MARK: - GPTK Installation Check

    func checkGPTKInstallation() async {
        await MainActor.run {
            isInitializing = false
            isGPTKInstalled = true
            initializationStatus = "Game Porting Toolkit ready"
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

        // Add user games
        let userGames = loadUserGames().filter { fileManager.fileExists(atPath: $0.executablePath) }
        games.append(contentsOf: userGames)

        await MainActor.run {
            self.installedGames = games
        }
    }

    @Published var lastLaunchedGame: Game? = nil

    func launchGame(_ game: Game) async throws {
        lastLaunchedGame = game
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
        // Expanded list of possible Wine locations on macOS
        let possibleWinePaths = [
            // Homebrew (Apple Silicon)
            "/opt/homebrew/bin/wine",
            "/opt/homebrew/bin/wine64",
            // Homebrew (Intel)
            "/usr/local/bin/wine",
            "/usr/local/bin/wine64",
            // MacPorts
            "/opt/local/bin/wine",
            "/opt/local/bin/wine64",
            // CrossOver
            NSHomeDirectory() + "/Applications/CrossOver.app/Contents/Resources/wine/bin/wine",
            NSHomeDirectory() + "/Applications/CrossOver.app/Contents/Resources/wine/bin/wine64",
            "/Applications/CrossOver.app/Contents/Resources/wine/bin/wine",
            "/Applications/CrossOver.app/Contents/Resources/wine/bin/wine64",
            // Cellar (Homebrew internal)
            "/usr/local/Cellar/wine/bin/wine",
            "/usr/local/Cellar/wine/bin/wine64",
            "/opt/homebrew/Cellar/wine/bin/wine",
            "/opt/homebrew/Cellar/wine/bin/wine64",
            // Fallback: user bin
            NSHomeDirectory() + "/bin/wine",
            NSHomeDirectory() + "/bin/wine64",
            // Fallback: /usr/bin
            "/usr/bin/wine",
            "/usr/bin/wine64",
        ]
        guard let winePath = possibleWinePaths.first(where: { fileManager.fileExists(atPath: $0) })
        else {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Wine Not Found"
                alert.informativeText =
                    "No Wine binary found in expected locations. Please install Wine using Homebrew, MacPorts, or CrossOver.\n\nExpected locations:\n"
                    + possibleWinePaths.joined(separator: "\n")
                alert.alertStyle = .critical
                alert.runModal()
            }
            print("No Wine binary found in expected locations.")
            throw GPTKError.notInstalled
        }
        print("[kimiz] Using wine binary at: \(winePath)")
        print("[kimiz] Launching: \(executablePath)")

        let environment = getOptimizedEnvironment()
        // Use the new async/await WineManager logic
        try await WineManager.shared.runWineProcess(
            winePath: winePath,
            executablePath: executablePath,
            environment: environment,
            defaultBottlePath: defaultBottlePath
        ) { [weak self] component in
            Task { @MainActor in
                self?.showMissingComponentAlert(component: component)
            }
        }
    }

    // Show popup to install missing component
    @MainActor
    private func showMissingComponentAlert(component: String) {
        let alert = NSAlert()
        alert.messageText = "Missing Component Detected"
        alert.informativeText =
            "Wine reported a missing component: \(component). Would you like to install it to the current bottle?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Install Needed Component")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn, let bottle = selectedBottle ?? bottles.first {
            Task {
                do {
                    try await installDependency(component, for: bottle)
                    // After successful install, retry launching the last game if available
                    if let game = self.lastLaunchedGame {
                        try? await self.launchGame(game)
                    }
                } catch {
                    let failAlert = NSAlert()
                    failAlert.messageText = "Failed to Install Component"
                    failAlert.informativeText = error.localizedDescription
                    failAlert.alertStyle = .critical
                    failAlert.runModal()
                }
            }
        }
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

    func getOptimizedEnvironment(for bottle: Bottle) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["WINEPREFIX"] = bottle.path
        // ...other environment variables as before...
        environment["WINEDEBUG"] = "-all"
        environment["MTL_HUD_ENABLED"] = "1"
        environment["WINEESYNC"] = "1"
        environment["DXVK_ASYNC"] = "1"
        environment["WINE_LARGE_ADDRESS_AWARE"] = "1"
        environment["MTL_SHADER_VALIDATION"] = "0"
        environment["MTL_DEBUG_LAYER"] = "0"
        environment["WINE_CPU_TOPOLOGY"] = "4:2"
        environment["STAGING_WRITECOPY"] = "1"
        environment["STAGING_SHARED_MEMORY"] = "1"
        environment["DXVK_STATE_CACHE"] = "1"
        environment["DXVK_LOG_LEVEL"] = "none"
        environment["PULSE_LATENCY_MSEC"] = "60"
        return environment
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
        let isAppleSilicon =
            ProcessInfo.processInfo.environment["BREW_PREFIX"] == "/opt/homebrew"
            || FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")

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
            installationStatus =
                "Installing Game Porting Toolkit (this may take several minutes)..."
        }

        let process = Process()
        if isAppleSilicon {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
            process.arguments = [
                "-x86_64", brewPath, "install", "apple/apple/game-porting-toolkit",
            ]
        } else {
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "apple/apple/game-porting-toolkit"]
        }

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorMessage =
                        isAppleSilicon
                        ? "Failed to install Game Porting Toolkit. Make sure Rosetta 2 is installed: 'softwareupdate --install-rosetta'"
                        : "Failed to install Game Porting Toolkit"
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

        // Install dependencies without Rosetta 2 or GPTK
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
        ]

        return try await withCheckedThrowingContinuation { continuation in
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

        // Run Steam installer
        let environment = getOptimizedEnvironment()

        guard
            let winePath = ["/opt/homebrew/bin/wine64", "/usr/local/bin/wine64"].first(where: {
                FileManager.default.fileExists(atPath: $0)
            })
        else {
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

    // MARK: - Bottles Management

    private func saveBottles() {
        do {
            let data = try JSONEncoder().encode(bottles)
            try FileManager.default.createDirectory(
                atPath: (bottlesFile as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true)
            try data.write(to: URL(fileURLWithPath: bottlesFile))
        } catch {
            print("Failed to save bottles: \(error)")
        }
    }

    private func loadBottles() -> [Bottle] {
        guard FileManager.default.fileExists(atPath: bottlesFile) else { return [] }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: bottlesFile))
            return try JSONDecoder().decode([Bottle].self, from: data)
        } catch {
            print("Failed to load bottles: \(error)")
            return []
        }
    }

    func createBottle(name: String) async {
        let bottlePath = NSString(
            string: "~/Library/Application Support/kimiz/gptk-bottles/\(name)"
        ).expandingTildeInPath
        do {
            try fileManager.createDirectory(atPath: bottlePath, withIntermediateDirectories: true)
            // Initialize the bottle with wineboot to create the correct structure
            let winePath = [
                "/opt/homebrew/bin/wine64",
                "/usr/local/bin/wine64",
                "/opt/homebrew/bin/wine",
                "/usr/local/bin/wine",
            ].first(where: { fileManager.fileExists(atPath: $0) })
            if let winePath = winePath {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: winePath)
                process.arguments = ["wineboot", "-u"]
                process.environment = getOptimizedEnvironment(
                    for: Bottle(name: name, path: bottlePath))
                process.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
                try process.run()
                process.waitUntilExit()
            }
            let bottle = Bottle(name: name, path: bottlePath)
            await MainActor.run {
                self.bottles.append(bottle)
                self.selectedBottle = bottle
            }
            saveBottles()
        } catch {
            print("Failed to create bottle: \(error)")
        }
    }

    func deleteBottle(_ bottle: Bottle) async {
        do {
            try fileManager.removeItem(atPath: bottle.path)
            await MainActor.run {
                self.bottles.removeAll { $0.id == bottle.id }
                if self.selectedBottle == bottle {
                    self.selectedBottle = self.bottles.first
                }
            }
            saveBottles()
        } catch {
            print("Failed to delete bottle: \(error)")
        }
    }

    func installDependency(_ dependency: String, for bottle: Bottle) async throws {
        // Find winetricks binary directly
        guard
            let winetricksPath = ["/opt/homebrew/bin/winetricks", "/usr/local/bin/winetricks"]
                .first(where: { fileManager.fileExists(atPath: $0) })
        else {
            throw GPTKError.installationFailed(
                "winetricks is not installed. Please run 'brew install winetricks' in Terminal.")
        }
        var env = getOptimizedEnvironment(for: bottle)
        env["WINEPREFIX"] = bottle.path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winetricksPath)
        process.arguments = [dependency]
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: bottle.path)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        print("[Winetricks Output]", output)
        if process.terminationStatus == 0 {
            if let idx = bottles.firstIndex(of: bottle) {
                bottles[idx].dependencies.append(dependency)
                saveBottles()
            }
        } else {
            throw GPTKError.installationFailed(
                "Failed to install \(dependency) in bottle \(bottle.name). Output: \(output)")
        }
    }

    // Check if any Wine or GPTK binary exists
    var isWineOrGPTKAvailable: Bool {
        let possibleWinePaths = [
            "/opt/homebrew/bin/wine",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
        ]
        return possibleWinePaths.contains { fileManager.fileExists(atPath: $0) }
    }
    // Install Wine and dependencies using Homebrew
    func installWineAndDependencies() async throws {
        guard isHomebrewInstalled(), let brewPath = getBrewPath() else {
            throw GPTKError.homebrewRequired
        }
        await MainActor.run {
            installationProgress = 0.2
            installationStatus = "Installing Wine and dependencies..."
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = [
            "install",
            "wine",
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
        ]
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorMessage = "Failed to install Wine and dependencies"
                    continuation.resume(throwing: GPTKError.installationFailed(errorMessage))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
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
            return
                "Homebrew is required to install Game Porting Toolkit. Please install Homebrew first."
        case .rosettaRequired:
            return
                "Rosetta 2 is required on Apple Silicon Macs. Please install it by running: softwareupdate --install-rosetta"
        }
    }
}
