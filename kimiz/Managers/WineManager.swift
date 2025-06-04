//
//  WineManager.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Combine
import Foundation

@MainActor
class WineManager: ObservableObject {
    @Published var winePrefixes: [WinePrefix] = []
    @Published var gameInstallations: [GameInstallation] = []
    @Published var availableBackends: [WineBackend] = []
    @Published var isLoading = false
    @Published var lastError: String?

    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()

    init() {
        detectAvailableBackends()
        loadWinePrefixes()
        loadGameInstallations()
    }

    // MARK: - Backend Detection

    func detectAvailableBackends() {
        var backends: [WineBackend] = []

        // Always prioritize embedded Wine
        backends.append(.embedded)

        // Check for other Wine installations
        for backend in [WineBackend.wine, .crossover, .gamePortingToolkit] {
            if fileManager.fileExists(atPath: backend.executablePath) {
                backends.append(backend)
            }
        }

        // Special check for Game Porting Toolkit
        if fileManager.fileExists(atPath: "/usr/local/bin/wine64") {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/local/bin/wine64")
            task.arguments = ["--version"]

            do {
                try task.run()
                task.waitUntilExit()

                if task.terminationStatus == 0 {
                    if !backends.contains(.gamePortingToolkit) {
                        backends.append(.gamePortingToolkit)
                    }
                }
            } catch {
                print("Failed to check GPTK: \(error)")
            }
        }

        self.availableBackends = backends
    }

    // MARK: - Wine Prefix Management

    func createWinePrefix(name: String, backend: WineBackend, windowsVersion: String = "win10")
        async throws
    {
        isLoading = true
        defer { isLoading = false }

        let prefix = WinePrefix(name: name, backend: backend, windowsVersion: windowsVersion)

        // Create the directory
        try fileManager.createDirectory(atPath: prefix.path, withIntermediateDirectories: true)

        // Initialize the Wine prefix
        let task = Process()
        task.executableURL = URL(fileURLWithPath: backend.executablePath)
        task.arguments = ["winecfg"]
        task.environment = [
            "WINEPREFIX": prefix.path,
            "WINEARCH": prefix.architecture,
        ]

        // Add Game Porting Toolkit specific environment variables
        if backend == .gamePortingToolkit {
            var env = task.environment ?? [:]
            env["MTL_HUD_ENABLED"] = "1"
            env["WINEESYNC"] = "1"
            task.environment = env
        }

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw WineError.prefixCreationFailed("Failed to create Wine prefix")
        }

        winePrefixes.append(prefix)
        saveWinePrefixes()
    }

    func deleteWinePrefix(_ prefix: WinePrefix) throws {
        try fileManager.removeItem(atPath: prefix.path)
        winePrefixes.removeAll { $0.id == prefix.id }
        gameInstallations.removeAll { $0.winePrefix.id == prefix.id }
        saveWinePrefixes()
        saveGameInstallations()
    }

    // MARK: - Game Installation

    func installSteam(in prefix: WinePrefix) async throws {
        isLoading = true
        defer { isLoading = false }

        // Download Steam installer
        let steamURL = URL(
            string: "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe")!
        let tempDir = fileManager.temporaryDirectory
        let installerPath = tempDir.appendingPathComponent("SteamSetup.exe")

        // Download the installer
        let (data, _) = try await URLSession.shared.data(from: steamURL)
        try data.write(to: installerPath)

        // Run the Steam installer
        try await runWindowsExecutable(
            path: installerPath.path,
            in: prefix,
            arguments: ["/S"],  // Silent install
            waitForCompletion: true
        )

        // Create game installation entry
        let steamPath = "\(prefix.path)/drive_c/Program Files (x86)/Steam/Steam.exe"
        if fileManager.fileExists(atPath: steamPath) {
            let steamGame = GameInstallation(
                name: "Steam",
                executablePath: steamPath,
                winePrefix: prefix,
                installPath: "\(prefix.path)/drive_c/Program Files (x86)/Steam"
            )
            var mutableSteam = steamGame
            mutableSteam.isInstalled = true
            gameInstallations.append(mutableSteam)
            saveGameInstallations()
        }

        // Clean up installer
        try? fileManager.removeItem(at: installerPath)
    }

    func runWindowsExecutable(
        path: String, in prefix: WinePrefix, arguments: [String] = [],
        waitForCompletion: Bool = false
    ) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: prefix.backend.executablePath)

        var taskArgs = [path]
        taskArgs.append(contentsOf: arguments)
        task.arguments = taskArgs

        var environment = [
            "WINEPREFIX": prefix.path,
            "WINEDEBUG": "-all",  // Reduce Wine debug output
        ]

        // Add Game Porting Toolkit optimizations
        if prefix.backend == .gamePortingToolkit {
            environment["MTL_HUD_ENABLED"] = "1"
            environment["WINEESYNC"] = "1"
            environment["DXVK_ASYNC"] = "1"
            environment["WINE_LARGE_ADDRESS_AWARE"] = "1"
        }

        task.environment = environment

        try task.run()

        if waitForCompletion {
            task.waitUntilExit()
            if task.terminationStatus != 0 {
                throw WineError.executionFailed("Failed to run executable: \(path)")
            }
        }
    }

    func launchGame(_ game: GameInstallation) async throws {
        var mutableGame = game
        mutableGame.lastPlayed = Date()

        if let index = gameInstallations.firstIndex(where: { $0.id == game.id }) {
            gameInstallations[index] = mutableGame
        }

        try await runWindowsExecutable(
            path: game.executablePath,
            in: game.winePrefix
        )

        saveGameInstallations()
    }

    // MARK: - Persistence

    private func loadWinePrefixes() {
        // Load from UserDefaults or Core Data
        // Implementation would depend on chosen persistence method
    }

    private func saveWinePrefixes() {
        // Save to UserDefaults or Core Data
        // Implementation would depend on chosen persistence method
    }

    private func loadGameInstallations() {
        // Load from UserDefaults or Core Data
        // Implementation would depend on chosen persistence method
    }

    private func saveGameInstallations() {
        // Save to UserDefaults or Core Data
        // Implementation would depend on chosen persistence method
    }
}
