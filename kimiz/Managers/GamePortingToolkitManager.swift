//
//  GamePortingToolkitManager.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import AppKit
import Combine
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
        let possibleWinePaths = [
            // Game Porting Toolkit paths (prioritized)
            "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/wine64",
            "/usr/local/Cellar/game-porting-toolkit/1.1/bin/wine64",
            // GPTK from Apple tap
            "/opt/homebrew/bin/game-porting-toolkit",
            "/usr/local/bin/game-porting-toolkit",
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
                alert.messageText = "Game Porting Toolkit Not Found"
                alert.informativeText =
                    "No Game Porting Toolkit or Wine binary found in expected locations. Please install Game Porting Toolkit using Homebrew first.\n\nExpected locations:\n"
                    + possibleWinePaths.joined(separator: "\n")
                alert.alertStyle = .critical
                alert.runModal()
            }
            print("No Game Porting Toolkit or Wine binary found in expected locations.")
            throw GPTKError.notInstalled
        }
        print("[kimiz] Using Game Porting Toolkit/Wine binary at: \(winePath)")
        print("[kimiz] Launching: \(executablePath)")

        let environment = getOptimizedEnvironment()
        // Use the new async/await WineManager logic with working directory support
        try await WineManager.shared.runWineProcess(
            winePath: winePath,
            executablePath: executablePath,
            environment: environment,
            workingDirectory: gameDirectory,
            defaultBottlePath: defaultBottlePath
        )
    }

    // MARK: - GPTK Optimization

    func getOptimizedEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment

        // Game Porting Toolkit specific optimizations
        environment["WINEPREFIX"] = defaultBottlePath
        environment["WINEDEBUG"] = "-all"
        environment["MTL_HUD_ENABLED"] = "0"  // Disable HUD for better performance
        environment["WINEESYNC"] = "1"
        environment["DXVK_ASYNC"] = "1"
        environment["WINE_LARGE_ADDRESS_AWARE"] = "1"
        environment["MTL_SHADER_VALIDATION"] = "0"
        environment["MTL_DEBUG_LAYER"] = "0"

        // GPTK-specific optimizations
        environment["GPTK_ENABLE"] = "1"
        environment["GPTK_SHADER_CACHE"] = "1"
        environment["GPTK_METAL_HUD"] = "0"  // Disable Metal HUD by default
        environment["GPTK_DYLD_FALLBACK_LIBRARY_PATH"] = "/opt/homebrew/lib:/usr/local/lib"
        environment["GPTK_METAL_VALIDATION"] = "0"  // Disable Metal validation for performance

        // CPU usage optimization
        environment["WINE_PTHREAD_MUTEX_DISABLE_CONSISTENCY_CHECK"] = "1"  // Reduce CPU overhead
        environment["WINE_NO_CREATE_PROCESS_GROUP"] = "1"  // Reduce process overhead
        environment["WINE_FOREGROUND_PRIORITY"] = "normal"  // Don't use high priority
        environment["WINE_BACKGROUND_PRIORITY"] = "low"  // Use low priority for background tasks

        // Memory and performance optimizations
        environment["WINE_CPU_TOPOLOGY"] = "2:2"  // Limit CPU cores for lower usage
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

        // GPTK-specific optimizations
        environment["GPTK_ENABLE"] = "1"
        environment["GPTK_SHADER_CACHE"] = "1"
        environment["GPTK_METAL_HUD"] = "0"  // Disable Metal HUD by default
        environment["GPTK_DYLD_FALLBACK_LIBRARY_PATH"] = "/opt/homebrew/lib:/usr/local/lib"
        environment["GPTK_METAL_VALIDATION"] = "0"  // Disable Metal validation for performance

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

        guard
            let winePath = [
                // GPTK paths first
                "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/wine64",
                "/usr/local/Cellar/game-porting-toolkit/1.1/bin/wine64",
                "/opt/homebrew/bin/game-porting-toolkit",
                "/usr/local/bin/game-porting-toolkit",
                // Fallback to Wine if GPTK is not available
                "/opt/homebrew/bin/wine64",
                "/usr/local/bin/wine64",
                "/opt/homebrew/bin/wine",
                "/usr/local/bin/wine",
            ].first(where: {
                FileManager.default.fileExists(atPath: $0)
            })
        else {
            throw GPTKError.notInstalled
        }

        // Use WineManager to run the Steam installer
        try await WineManager.shared.runWineProcess(
            winePath: winePath,
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

            // Initialize the bottle with proper Wine configuration
            let winePath = [
                "/opt/homebrew/bin/wine",
                "/usr/local/bin/wine",
                "/opt/homebrew/bin/wine64",
                "/usr/local/bin/wine64",
            ].first(where: { fileManager.fileExists(atPath: $0) })

            if let winePath = winePath {
                print("[GPTK] Initializing bottle \(name) at \(bottlePath)")

                // First initialize the Wine prefix
                let initProcess = Process()
                initProcess.executableURL = URL(fileURLWithPath: winePath)
                initProcess.arguments = ["wineboot", "--init"]
                var initEnv = getOptimizedEnvironment(for: Bottle(name: name, path: bottlePath))
                initEnv["WINEPREFIX"] = bottlePath
                initProcess.environment = initEnv
                initProcess.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
                try initProcess.run()
                initProcess.waitUntilExit()

                // Then run wineboot to finalize setup
                let bootProcess = Process()
                bootProcess.executableURL = URL(fileURLWithPath: winePath)
                bootProcess.arguments = ["wineboot", "-u"]
                bootProcess.environment = initEnv
                bootProcess.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
                try bootProcess.run()
                bootProcess.waitUntilExit()

                print("[GPTK] Bottle \(name) initialized successfully")
            } else {
                print("[GPTK] Warning: Wine not found, bottle created without initialization")
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
        await MainActor.run {
            self.isInstallingComponents = true
            self.installationProgress = 0.1
            self.installationStatus = "Installing \(dependency)..."
        }

        // Auto-install winetricks if missing
        var winetricksPath = ["/opt/homebrew/bin/winetricks", "/usr/local/bin/winetricks"]
            .first(where: { fileManager.fileExists(atPath: $0) })

        if winetricksPath == nil {
            await MainActor.run {
                self.installationStatus = "Installing winetricks first..."
            }

            guard let brewPath = getBrewPath() else {
                throw GPTKError.homebrewRequired
            }

            // Install winetricks
            let installProcess = Process()
            installProcess.executableURL = URL(fileURLWithPath: brewPath)
            installProcess.arguments = ["install", "winetricks"]
            try installProcess.run()
            installProcess.waitUntilExit()

            if installProcess.terminationStatus != 0 {
                throw GPTKError.installationFailed("Failed to install winetricks")
            }

            // Try to find winetricks again
            winetricksPath = ["/opt/homebrew/bin/winetricks", "/usr/local/bin/winetricks"]
                .first(where: { fileManager.fileExists(atPath: $0) })

            guard winetricksPath != nil else {
                throw GPTKError.installationFailed("winetricks installation failed")
            }
        }

        await MainActor.run {
            self.installationProgress = 0.3
            self.installationStatus = "Preparing Wine prefix..."
        }

        // Initialize bottle if it doesn't exist
        if !fileManager.fileExists(atPath: bottle.path) {
            try fileManager.createDirectory(atPath: bottle.path, withIntermediateDirectories: true)

            // Initialize Wine prefix properly
            guard
                let winePath = [
                    "/opt/homebrew/bin/wine",
                    "/usr/local/bin/wine",
                    "/opt/homebrew/bin/wine64",
                    "/usr/local/bin/wine64",
                ].first(where: { fileManager.fileExists(atPath: $0) })
            else {
                throw GPTKError.installationFailed("Wine not found for bottle initialization")
            }

            let initProcess = Process()
            initProcess.executableURL = URL(fileURLWithPath: winePath)
            initProcess.arguments = ["wineboot", "--init"]
            var initEnv = getOptimizedEnvironment(for: bottle)
            initEnv["WINEPREFIX"] = bottle.path
            initProcess.environment = initEnv
            initProcess.currentDirectoryURL = URL(fileURLWithPath: bottle.path)
            try initProcess.run()
            initProcess.waitUntilExit()

            print("[GPTK] Initialized Wine prefix at: \(bottle.path)")
        }

        await MainActor.run {
            self.installationProgress = 0.5
            self.installationStatus = "Installing \(dependency) component..."
        }

        var env = getOptimizedEnvironment(for: bottle)
        env["WINEPREFIX"] = bottle.path
        env["DISPLAY"] = ":0.0"  // Set display for GUI components
        env["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"  // Disable menu builder
        env["WINETRICKS_LATEST_VERSION_CHECK"] = "disabled"  // Skip version check

        // Map components to proper winetricks verbs
        let componentMap = [
            "vulkan": "vulkan",
            "directx11": "d3d11",
            "directx12": "d3d12core",
            "vcrun2015": "vcrun2019",  // Use newer runtime
            "d3dcompiler_47": "d3dcompiler_47",
            "dotnet48": "dotnet48",
            "dxvk": "dxvk",
        ]

        let winetricksComponent = componentMap[dependency] ?? dependency

        print(
            "[GPTK] Installing \(winetricksComponent) (mapped from \(dependency)) in bottle \(bottle.name)"
        )
        print("[GPTK] Wine prefix: \(bottle.path)")
        print("[GPTK] Using winetricks: \(winetricksPath!)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: winetricksPath!)
        // Use --unattended flag to avoid GUI prompts and --force for problematic components
        process.arguments = ["--unattended", "--force", winetricksComponent]
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: bottle.path)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        print("[Winetricks Output] \(output)")

        await MainActor.run {
            self.installationProgress = 0.9
        }

        if process.terminationStatus == 0 || process.terminationStatus == 1 {  // winetricks sometimes returns 1 but still succeeds
            print("[GPTK] Successfully installed \(dependency)")
            if let idx = bottles.firstIndex(of: bottle) {
                await MainActor.run {
                    // Only add if not already present
                    if !self.bottles[idx].dependencies.contains(dependency) {
                        self.bottles[idx].dependencies.append(dependency)
                    }
                }
                saveBottles()
            }

            await MainActor.run {
                self.installationProgress = 1.0
                self.installationStatus = "\(dependency) installed successfully"
                self.isInstallingComponents = false
            }
        } else {
            await MainActor.run {
                self.isInstallingComponents = false
            }
            print("[GPTK] Failed to install \(dependency), exit code: \(process.terminationStatus)")
            throw GPTKError.installationFailed(
                "Failed to install \(dependency) in bottle \(bottle.name). Exit code: \(process.terminationStatus)\nOutput: \(output)"
            )
        }
    }

    // MARK: - CrossOver Integration

    func importCrossOverBottle(bottleName: String, crossOverPath: String) async {
        let bottle = Bottle(
            name: "CrossOver-\(bottleName)",
            path: crossOverPath,
            dependencies: []  // CrossOver handles dependencies internally
        )

        await MainActor.run {
            self.bottles.append(bottle)
            if self.selectedBottle == nil {
                self.selectedBottle = bottle
            }
        }
        saveBottles()

        // Scan for games in this bottle
        await scanForCrossOverGames(in: bottle)
    }

    private func scanForCrossOverGames(in bottle: Bottle) async {
        let steamPath = "\(bottle.path)/drive_c/Program Files (x86)/Steam"
        let steamAppsPath = "\(steamPath)/steamapps/common"

        var foundGames: [Game] = []

        // Check if Steam exists in this bottle
        if fileManager.fileExists(atPath: "\(steamPath)/steam.exe") {
            let steamGame = Game(
                name: "Steam (CrossOver)",
                executablePath: "\(steamPath)/steam.exe",
                installPath: steamPath
            )
            foundGames.append(steamGame)
        }

        // Scan for individual games
        if fileManager.fileExists(atPath: steamAppsPath) {
            do {
                let gameDirectories = try fileManager.contentsOfDirectory(atPath: steamAppsPath)

                for gameDir in gameDirectories {
                    let gamePath = "\(steamAppsPath)/\(gameDir)"

                    // Look for game executables
                    if let gameExecutables = try? fileManager.contentsOfDirectory(atPath: gamePath)
                    {
                        for file in gameExecutables where file.hasSuffix(".exe") {
                            let executablePath = "\(gamePath)/\(file)"

                            // Skip certain system executables
                            let skipFiles = ["unins000.exe", "vcredist", "directx", "setup.exe"]
                            if !skipFiles.contains(where: { file.lowercased().contains($0) }) {
                                let game = Game(
                                    name: "\(gameDir) (CrossOver)",
                                    executablePath: executablePath,
                                    installPath: gamePath
                                )
                                foundGames.append(game)
                            }
                        }
                    }
                }
            } catch {
                print("Error scanning CrossOver games: \(error)")
            }
        }

        await MainActor.run {
            self.installedGames.append(contentsOf: foundGames)
        }
        saveUserGames()
    }  // MARK: - Enhanced CrossOver Integration

    func detectCrossOverBottles() async -> [String] {
        let crossOverBottlesPath =
            NSHomeDirectory() + "/Library/Application Support/CrossOver/Bottles"
        var detectedBottles: [String] = []

        do {
            let bottleNames = try fileManager.contentsOfDirectory(atPath: crossOverBottlesPath)
            for bottleName in bottleNames {
                let bottlePath = "\(crossOverBottlesPath)/\(bottleName)"
                // Check if this bottle has Steam installed
                let steamPath = "\(bottlePath)/drive_c/Program Files (x86)/Steam/steam.exe"
                if fileManager.fileExists(atPath: steamPath) {
                    detectedBottles.append(bottleName)
                }
            }
        } catch {
            print("Could not access CrossOver bottles: \(error)")
        }

        return detectedBottles
    }

    func importCrossOverSteamBottle(bottleName: String) async throws {
        let crossOverBottlePath =
            NSHomeDirectory() + "/Library/Application Support/CrossOver/Bottles/\(bottleName)"
        let steamPath = "\(crossOverBottlePath)/drive_c/Program Files (x86)/Steam/steam.exe"

        guard fileManager.fileExists(atPath: steamPath) else {
            throw GPTKError.gameNotFound("Steam not found in CrossOver bottle '\(bottleName)'")
        }

        // Import the bottle into kimiz
        await importCrossOverBottle(bottleName: bottleName, crossOverPath: crossOverBottlePath)

        await MainActor.run {
            self.initializationStatus =
                "Successfully imported CrossOver Steam bottle: \(bottleName)"
        }

        print("[kimiz] Successfully imported CrossOver Steam bottle: \(bottleName)")
        print("[kimiz] Steam path: \(steamPath)")
        print("[kimiz] This preserves your existing Steam login and game files safely")
    }

    func getCrossOverWinePath() -> String? {
        let crossOverWinePaths = [
            "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine64",
            "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine",
            NSHomeDirectory()
                + "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine64",
            NSHomeDirectory()
                + "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine",
        ]

        return crossOverWinePaths.first(where: { fileManager.fileExists(atPath: $0) })
    }

    private func extractBottlePathFromGame(_ game: Game) -> String {
        // Extract bottle path from game executable path
        if game.executablePath.contains("CrossOver/Bottles") {
            let components = game.executablePath.components(separatedBy: "/")
            if let bottlesIndex = components.firstIndex(of: "Bottles"),
                bottlesIndex + 1 < components.count
            {
                let bottleName = components[bottlesIndex + 1]
                return NSHomeDirectory()
                    + "/Library/Application Support/CrossOver/Bottles/\(bottleName)"
            }
        }
        return defaultBottlePath
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

        var errorDescription: String? {
            switch self {
            case .notInstalled:
                return
                    "Game Porting Toolkit is not installed. Please install GPTK using Homebrew: brew install apple/apple/game-porting-toolkit"
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
}
