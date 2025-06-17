//  SteamManager.swift
//  kimiz
//
//  Handles Steam-specific installation, validation, and launch logic using Wine/GPTK

import AppKit
import Foundation
import SwiftUI
import os.log

// Ensure WineManager.swift is visible to this file
// WineManager is defined as an internal actor in the same target, so use '@_implementationOnly import' if needed
// But normally, just referencing WineManager.shared should work if the file is in the same target

// Import WineManager for process launching
@MainActor
internal class SteamManager: ObservableObject {
    static let shared = SteamManager()

    private let fileManager = FileManager.default
    private let defaultBottlePath: String

    @Published var isInstallingSteam = false
    @Published var installationProgress: Double = 0.0
    @Published var installationStatus = ""

    private init() {
        self.defaultBottlePath =
            NSString(string: "~/Library/Application Support/kimiz/gptk-bottles/default")
            .expandingTildeInPath
    }

    /// Check if Steam is installed in the default bottle
    func isSteamInstalled() -> Bool {
        let steamPath = defaultBottlePath + "/drive_c/Program Files (x86)/Steam/steam.exe"
        return fileManager.fileExists(atPath: steamPath)
    }

    /// Remove broken or partial Steam installations
    private func cleanupBrokenSteamInstall(at steamDir: String) {
        let steamExe = (steamDir as NSString).appendingPathComponent("steam.exe")
        if !fileManager.fileExists(atPath: steamExe) {
            try? fileManager.removeItem(atPath: steamDir)
        }
    }

    /// Download and install Steam using Wine/GPTK
    func installSteam() async throws {
        await MainActor.run {
            self.isInstallingSteam = true
            self.installationProgress = 0.0
            self.installationStatus = "Downloading Steam installer..."
        }

        let steamInstallerURL = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
        let tmpDir = NSString(string: "~/Library/Application Support/kimiz/tmp")
            .expandingTildeInPath
        try? fileManager.createDirectory(
            atPath: tmpDir, withIntermediateDirectories: true, attributes: nil)
        let installerPath = (tmpDir as NSString).appendingPathComponent("SteamSetup.exe")
        try? fileManager.removeItem(atPath: installerPath)
        guard let url = URL(string: steamInstallerURL) else {
            await MainActor.run {
                self.installationStatus = "❌ Invalid Steam installer URL"
                self.isInstallingSteam = false
            }
            throw NSError(
                domain: "SteamInstallError", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Steam installer URL"])
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: URL(fileURLWithPath: installerPath))
            await MainActor.run {
                self.installationProgress = 0.6
                self.installationStatus = "Running SteamSetup.exe in bottle..."
            }
            let winePath = try findWineOrGPTK()
            let environment = [
                "WINEPREFIX": defaultBottlePath,
                "WINE_LARGE_ADDRESS_AWARE": "1",
            ]
            try await WineManager.shared.runWineProcess(
                winePath: winePath,
                executablePath: installerPath,
                arguments: ["/S"],
                environment: environment,
                workingDirectory: tmpDir,
                defaultBottlePath: defaultBottlePath
            )
            try? fileManager.removeItem(atPath: installerPath)
            let steamExePath = defaultBottlePath + "/drive_c/Program Files (x86)/Steam/steam.exe"
            if fileManager.fileExists(atPath: steamExePath) {
                await MainActor.run {
                    self.installationProgress = 1.0
                    self.installationStatus = "✅ Steam installed successfully!"
                    self.isInstallingSteam = false
                }
            } else {
                cleanupBrokenSteamInstall(
                    at: defaultBottlePath + "/drive_c/Program Files (x86)/Steam")
                await MainActor.run {
                    self.installationStatus =
                        "❌ Steam installation did not complete. Please try again or check logs."
                    self.isInstallingSteam = false
                }
                throw NSError(
                    domain: "SteamInstallError", code: 3,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Steam was not found after installation. Check your Wine/GPTK setup and try again."
                    ])
            }
        } catch {
            await MainActor.run {
                self.installationStatus = "❌ Failed to install Steam: \(error.localizedDescription)"
                self.isInstallingSteam = false
            }
            throw error
        }
    }

    /// Launch Steam in legacy/small mode for best compatibility with black screen prevention
    func launchSteam() async throws {
        // Ensure DXVK is installed before launching Steam
        try await installDXVKIfNeeded()
        
        // Apply Steam-specific compatibility fixes
        await GamePortingToolkitManager.shared.fixSteamGameCompatibility()

        let steamExePath = defaultBottlePath + "/drive_c/Program Files (x86)/Steam/steam.exe"
        guard fileManager.fileExists(atPath: steamExePath) else {
            throw NSError(
                domain: "SteamLaunchError", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Steam is not installed in this bottle. Please install Steam first."
                ])
        }
        let winePath = try findWineOrGPTK()
        var environment = [
            "WINEPREFIX": defaultBottlePath,
            "WINE_LARGE_ADDRESS_AWARE": "1",
            
            // Steam WebHelper and browser fixes
            "STEAM_WEBHELPER_DISABLED": "1",
            "STEAM_WEBHELPER_RENDERING": "disabled",
            "STEAM_USE_WEBHELPER": "0",
            "STEAM_DISABLE_BROWSER_SANDBOX": "1",
            "STEAM_DISABLE_GPU_ACCELERATION": "1",
            "STEAM_DISABLE_SHARED_TEXTURE": "1",
            "STEAM_NO_CEF_SANDBOX": "1",
            "STEAM_DISABLE_CEF_SANDBOX": "1",
            "STEAM_DISABLE_OVERLAY": "1",
            "STEAM_DISABLE_CHROME": "1",
            "STEAM_DISABLE_WEBVIEW": "1",
            
            // Graphics optimization to prevent black screens
            "DXVK_ASYNC": "1",
            "DXVK_STATE_CACHE": "1",
            "DXVK_SHADER_CACHE": "1",
            "DXVK_HUD": "0",
            "__GL_SHADER_DISK_CACHE": "1",
            "MESA_GLSL_CACHE_DISABLE": "false",
            
            // Display settings
            "DISPLAY": ":0.0",
            "WINE_DISABLE_LAYER_COMPOSITOR": "1",
            "WINEDLLOVERRIDES": "winemenubuilder.exe=d;steamwebhelper.exe=d",
        ]
        // Add Wine-specific tweaks if using Wine
        if winePath.contains("wine") {
            environment["WINEDEBUG"] = "-all"
            environment["WINE_CPU_TOPOLOGY"] = "4:2"
        }
        // Launch Steam in small mode/legacy UI with additional compatibility flags
        let steamArguments = [
            "-no-cef-sandbox",
            "-noreactlogin",
            "-no-browser",
            "-vgui",
            "-silent",
            "-nofriendsui",
            "-no-dwrite",
            "-nointro",
            "-nobootstrapupdate",
            "+open", "steam://open/minigameslist",
        ]
        // Rename steamwebhelper.exe to prevent it from running at all
        let steamWebHelperPath =
            (steamExePath as NSString).deletingLastPathComponent + "/steamwebhelper.exe"
        if fileManager.fileExists(atPath: steamWebHelperPath) {
            let disabledPath = steamWebHelperPath + ".disabled"
            try? fileManager.removeItem(atPath: disabledPath)
            try? fileManager.moveItem(atPath: steamWebHelperPath, toPath: disabledPath)
        }
        do {
            try await WineManager.shared.runWineProcess(
                winePath: winePath,
                executablePath: steamExePath,
                arguments: steamArguments,
                environment: environment,
                workingDirectory: (steamExePath as NSString).deletingLastPathComponent,
                defaultBottlePath: defaultBottlePath
            )
        } catch {
            throw NSError(
                domain: "SteamLaunchError", code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to launch Steam: \(error.localizedDescription)"
                ])
        }
    }

    /// Find Wine or GPTK binary, prefer GPTK
    private func findWineOrGPTK() throws -> String {
        let possibleGPTKPaths = [
            "/opt/homebrew/bin/game-porting-toolkit",
            "/usr/local/bin/game-porting-toolkit",
            "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
            "/usr/local/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
        ]
        let possibleWinePaths = [
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
        ]
        if let gptk = possibleGPTKPaths.first(where: { fileManager.fileExists(atPath: $0) }) {
            return gptk
        }
        if let wine = possibleWinePaths.first(where: { fileManager.fileExists(atPath: $0) }) {
            return wine
        }
        throw NSError(
            domain: "SteamSystem", code: 404,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Neither Game Porting Toolkit nor Wine found. Please install Wine via Homebrew or install GPTK."
            ])
    }

    // Steam game model for library integration
    struct SteamGame: Identifiable, Codable {
        let id: UUID
        let appId: String
        let name: String
        let installPath: String?
        let executablePath: String?
        var isInstalled: Bool
        var lastPlayed: Date?
        // Add more fields as needed
        init(
            id: UUID = UUID(), appId: String, name: String, installPath: String? = nil,
            executablePath: String? = nil, isInstalled: Bool = false, lastPlayed: Date? = nil
        ) {
            self.id = id
            self.appId = appId
            self.name = name
            self.installPath = installPath
            self.executablePath = executablePath
            self.isInstalled = isInstalled
            self.lastPlayed = lastPlayed
        }
    }

    /// Launch a Steam game using Wine/GPTK with optimized settings to prevent black screens
    func launchGame(_ game: SteamGame) async throws {
        // Ensure DXVK is installed before launching a game
        try await installDXVKIfNeeded()

        guard let exe = game.executablePath, FileManager.default.fileExists(atPath: exe) else {
            throw NSError(
                domain: "SteamGameLaunch", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Steam game executable not found."])
        }
        
        let winePath = try findWineOrGPTK()
        let gameDir = (exe as NSString).deletingLastPathComponent
        
        // Optimized environment for preventing black screens
        var environment = [
            "WINEPREFIX": defaultBottlePath,
            "WINE_LARGE_ADDRESS_AWARE": "1",
            
            // Graphics optimization to prevent black screens
            "DXVK_ASYNC": "1",
            "DXVK_STATE_CACHE": "1", 
            "DXVK_SHADER_CACHE": "1",
            "DXVK_HUD": "0",
            "DXVK_FILTER_DEVICE_NAME": "0",
            
            // Display settings
            "DISPLAY": ":0",
            "WINE_SYNCHRONOUS": "0",
            "WINEDEBUG": "-all",
            
            // OpenGL/Metal optimization
            "__GL_SHADER_DISK_CACHE": "1",
            "__GL_SHADER_DISK_CACHE_PATH": defaultBottlePath + "/shader_cache",
            "MESA_GLSL_CACHE_DISABLE": "false",
            "MESA_GLSL_CACHE_MAX_SIZE": "1G",
            
            // CPU optimization
            "WINE_CPU_TOPOLOGY": "4:2",
            "WINE_HEAP_SIZE": "2G",
            
            // Disable problematic features
            "WINEDLLOVERRIDES": "winemenubuilder.exe=d;mscoree=d;mshtml=d",
            "WINE_DISABLE_SVCHOST": "1"
        ]
        
        // Add game-specific arguments to improve compatibility
        var gameArguments: [String] = []
        
        // Check if it's a known problematic game and add fixes
        let gameName = game.name.lowercased()
        if gameName.contains("dx11") || gameName.contains("directx") {
            gameArguments.append("-dx11")
        }
        if gameName.contains("fullscreen") {
            gameArguments.append("-windowed")  // Force windowed mode to prevent black screen
        }
        
        try await WineManager.shared.runWineProcess(
            winePath: winePath,
            executablePath: exe,
            arguments: gameArguments,
            environment: environment,
            workingDirectory: gameDir,
            defaultBottlePath: defaultBottlePath
        )
    }

    /// Automatically install DXVK into the default bottle if not present
    func installDXVKIfNeeded() async throws {
        let bottlePath = defaultBottlePath
        let system32 = bottlePath + "/drive_c/windows/system32"
        let syswow64 = bottlePath + "/drive_c/windows/syswow64"
        let dxvkDlls = ["d3d11.dll", "dxgi.dll", "d3d10.dll", "d3d10_1.dll", "d3d10core.dll"]
        let dxvkVersion = "2.3.1"  // You may update this as needed
        let dxvkUrl =
            "https://github.com/doitsujin/dxvk/releases/download/v\(dxvkVersion)/dxvk-\(dxvkVersion).tar.gz"
        let tmpDir = NSString(string: "~/Library/Application Support/kimiz/tmp")
            .expandingTildeInPath
        let dxvkArchive = (tmpDir as NSString).appendingPathComponent("dxvk.tar.gz")
        let dxvkExtracted = (tmpDir as NSString).appendingPathComponent("dxvk-extracted")

        // Check if DXVK DLLs already exist
        let fileManager = FileManager.default
        let alreadyInstalled = dxvkDlls.allSatisfy {
            fileManager.fileExists(atPath: system32 + "/" + $0)
        }
        if alreadyInstalled { return }

        // Download DXVK
        if !fileManager.fileExists(atPath: dxvkArchive) {
            let (data, _) = try await URLSession.shared.data(from: URL(string: dxvkUrl)!)
            try data.write(to: URL(fileURLWithPath: dxvkArchive))
        }

        // Extract DXVK
        try? fileManager.removeItem(atPath: dxvkExtracted)
        try fileManager.createDirectory(atPath: dxvkExtracted, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xzf", dxvkArchive, "-C", dxvkExtracted]
        try process.run()
        process.waitUntilExit()

        // Find the x64 and x32 DLLs
        let dxvkX64 = dxvkExtracted + "/dxvk-\(dxvkVersion)/x64"
        let dxvkX32 = dxvkExtracted + "/dxvk-\(dxvkVersion)/x32"
        // Copy DLLs to system32 (x64) and syswow64 (x32)
        for dll in dxvkDlls {
            let src64 = dxvkX64 + "/" + dll
            let dst64 = system32 + "/" + dll
            if fileManager.fileExists(atPath: src64) {
                try? fileManager.removeItem(atPath: dst64)
                try fileManager.copyItem(atPath: src64, toPath: dst64)
            }
            let src32 = dxvkX32 + "/" + dll
            let dst32 = syswow64 + "/" + dll
            if fileManager.fileExists(atPath: src32) {
                try? fileManager.removeItem(atPath: dst32)
                try fileManager.copyItem(atPath: src32, toPath: dst32)
            }
        }
    }
}
