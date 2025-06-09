//
//  BottleManager.swift
//  kimiz
//
//  Created by temidaradev on 8.06.2025.
//

import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
internal class BottleManager: ObservableObject {
    internal static let shared = BottleManager()

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

    // MARK: - Published Properties

    @Published var bottles: [Bottle] = []
    @Published var selectedBottle: Bottle?

    // Installation properties
    @Published var isInstallingComponents = false
    @Published var installationProgress: Double = 0.0
    @Published var installationStatus = ""

    // MARK: - Private Properties

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
    }

    // MARK: - Bottle Management

    func createBottle(name: String) async {
        let bottlePath = NSString(
            string: "~/Library/Application Support/kimiz/gptk-bottles/\(name)"
        ).expandingTildeInPath
        do {
            try fileManager.createDirectory(atPath: bottlePath, withIntermediateDirectories: true)

            // Initialize the bottle with GPTK (no Wine fallback)
            let gptkPath = [
                "/opt/homebrew/bin/game-porting-toolkit",
                "/usr/local/bin/game-porting-toolkit",
                "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
                "/usr/local/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
            ].first(where: { fileManager.fileExists(atPath: $0) })

            if let gptkPath = gptkPath {
                print("[GPTK] Initializing bottle \(name) at \(bottlePath)")

                // First initialize the Wine prefix
                let initProcess = Process()
                initProcess.executableURL = URL(fileURLWithPath: gptkPath)
                initProcess.arguments = ["wineboot", "--init"]
                var initEnv = getOptimizedEnvironment(for: Bottle(name: name, path: bottlePath))
                initEnv["WINEPREFIX"] = bottlePath
                initProcess.environment = initEnv
                initProcess.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
                try initProcess.run()
                initProcess.waitUntilExit()

                // Then run wineboot to finalize setup
                let bootProcess = Process()
                bootProcess.executableURL = URL(fileURLWithPath: gptkPath)
                bootProcess.arguments = ["wineboot", "-u"]
                bootProcess.environment = initEnv
                bootProcess.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
                try bootProcess.run()
                bootProcess.waitUntilExit()

                print("[GPTK] Bottle \(name) initialized successfully")
            } else {
                print(
                    "[GPTK] Error: Game Porting Toolkit not found, bottle created without initialization"
                )
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

    func getDefaultBottlePath() -> String {
        return defaultBottlePath
    }

    func getOptimizedEnvironment(for bottle: Bottle) -> [String: String] {
        var base = ProcessInfo.processInfo.environment
        base["WINEPREFIX"] = bottle.path
        return WineManager.staticOptimizedWineEnvironment(base: base, useRAMDisk: true)
    }

    // MARK: - Dependency Management

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
                throw BottleError.homebrewRequired
            }

            // Install winetricks
            let installProcess = Process()
            installProcess.executableURL = URL(fileURLWithPath: brewPath)
            installProcess.arguments = ["install", "winetricks"]
            try installProcess.run()
            installProcess.waitUntilExit()

            if installProcess.terminationStatus != 0 {
                throw BottleError.installationFailed("Failed to install winetricks")
            }

            // Try to find winetricks again
            winetricksPath = ["/opt/homebrew/bin/winetricks", "/usr/local/bin/winetricks"]
                .first(where: { fileManager.fileExists(atPath: $0) })

            guard winetricksPath != nil else {
                throw BottleError.installationFailed("winetricks installation failed")
            }
        }

        await MainActor.run {
            self.installationProgress = 0.3
            self.installationStatus = "Preparing Wine prefix..."
        }

        // Initialize bottle if it doesn't exist
        if !fileManager.fileExists(atPath: bottle.path) {
            try fileManager.createDirectory(atPath: bottle.path, withIntermediateDirectories: true)

            // Initialize Wine prefix properly with GPTK only
            guard
                let gptkPath = [
                    "/opt/homebrew/bin/game-porting-toolkit",
                    "/usr/local/bin/game-porting-toolkit",
                    "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
                    "/usr/local/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
                ].first(where: { fileManager.fileExists(atPath: $0) })
            else {
                throw BottleError.installationFailed(
                    "Game Porting Toolkit not found for bottle initialization")
            }

            let initProcess = Process()
            initProcess.executableURL = URL(fileURLWithPath: gptkPath)
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
            throw BottleError.installationFailed(
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
    }

    // MARK: - Persistence

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

    // MARK: - Utility Methods

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

    // Returns the path of the currently selected bottle, or nil if none is selected
    var currentBottlePath: String? {
        selectedBottle?.path
    }
}

// MARK: - Error Types

enum BottleError: LocalizedError {
    case installationFailed(String)
    case homebrewRequired
    case wineNotFound
    case bottleNotFound(String)

    var errorDescription: String? {
        switch self {
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        case .homebrewRequired:
            return "Homebrew is required to install dependencies. Please install Homebrew first."
        case .wineNotFound:
            return "Wine not found. Please install Wine or Game Porting Toolkit."
        case .bottleNotFound(let name):
            return "Bottle not found: \(name)"
        }
    }
}
