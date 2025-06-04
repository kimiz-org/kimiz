//
//  EmbeddedWineManager+Enhanced.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Foundation

// Extension to add enhanced capabilities to EmbeddedWineManager
extension EmbeddedWineManager {

    // Check if Winetricks is already installed
    func isWinetricksInstalled() -> Bool {
        let winetricksPaths = [
            "/usr/local/bin/winetricks",  // Homebrew
            "/opt/homebrew/bin/winetricks",  // Apple Silicon Homebrew
            "/usr/bin/winetricks",  // System package manager
        ]

        for path in winetricksPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    // Launch game with specific environment variables
    func launchGame(
        executablePath: String,
        in prefixPath: String? = nil,
        withArgs args: [String] = [],
        environment additionalEnv: [String: String] = [:]
    ) async throws {
        let workingPrefix = prefixPath ?? defaultPrefixPath

        // Apply runtime performance optimizations before launching game
        try await applyRuntimeOptimizations(in: workingPrefix)

        let gameArgs = [executablePath] + args

        // Create environment with additional variables
        var customEnv = createWineEnvironment(prefixPath: workingPrefix)
        for (key, value) in additionalEnv {
            customEnv[key] = value
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winePath)
            process.arguments = gameArgs
            process.environment = customEnv

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: WineError.commandFailed(output))
                }
            }

            do {
                try process.run()
                continuation.resume(returning: "Game launched successfully")
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // Get detailed system information about Wine installation
    func getWineSystemInfo() async -> [String: String] {
        var info: [String: String] = [:]

        // Check Wine version
        do {
            let wineVersion = try await runCommand([winePath, "--version"])
            info["Wine Version"] = wineVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            info["Wine Version"] = "Unknown"
        }

        // Check CPU architecture
        do {
            let arch = try await runCommand(["/usr/bin/arch"])
            info["Architecture"] = arch.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            info["Architecture"] = "Unknown"
        }

        // Check macOS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        info["macOS Version"] = osVersion

        // Check GPU
        do {
            let gpuInfo = try await runCommand(["/usr/sbin/system_profiler", "SPDisplaysDataType"])
            if let gpuName = gpuInfo.components(separatedBy: "Chipset Model:").dropFirst().first?
                .components(separatedBy: "\n").first?.trimmingCharacters(
                    in: .whitespacesAndNewlines)
            {
                info["GPU"] = gpuName
            } else {
                info["GPU"] = "Unknown"
            }
        } catch {
            info["GPU"] = "Unknown"
        }

        // Check Wine backend
        info["Wine Backend"] = wineBackend.displayName

        // Check default prefix location
        info["Default Prefix"] = defaultPrefixPath

        return info
    }

    // Optimize Wine for a specific game based on known optimal settings
    func optimizeForGame(_ game: GameInstallation) async throws {
        let gameName = game.name.lowercased()
        var optimizations: [[String]] = []

        // Common optimizations for all games
        optimizations.append([
            "regedit", "/S", "/C",
            "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"csmt\" /t REG_DWORD /d 1",
        ])

        // Game-specific optimizations
        if gameName.contains("cyberpunk") {
            // Cyberpunk 2077 optimizations
            optimizations.append([
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"VideoMemorySize\" /t REG_DWORD /d 4096",
            ])
            optimizations.append([
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"MaxShaderModelGS\" /t REG_DWORD /d 5",
            ])
        } else if gameName.contains("witcher") {
            // The Witcher optimizations
            optimizations.append([
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"VideoMemorySize\" /t REG_DWORD /d 2048",
            ])
        } else if gameName.contains("doom") || gameName.contains("eternal") {
            // DOOM Eternal optimizations
            optimizations.append([
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Vulkan\" /v \"VK_ICD_FILENAMES\" /t REG_SZ /d \"/usr/local/share/vulkan/icd.d/MoltenVK_icd.json\"",
            ])
        }

        // Apply all optimizations
        for command in optimizations {
            do {
                _ = try await runWineCommand(command, in: game.winePrefix.path)
            } catch {
                print("Failed to apply optimization \(command): \(error)")
            }
        }
    }
}
