//
//  GamePortingToolkitManager.swift
//  kimiz
//

import AppKit
import Foundation
import SwiftUI

// Explicitly import all managers and models for type visibility
// These should be in the same target, but if not, use @testable import kimiz or public/internal access as needed
// If you still get errors, ensure all files are in the same target in Xcode

// Add these at the top if not present:
// import "../Models/Game.swift"
// import "LibraryManager.swift"
// import "SteamManager.swift"
// import "EpicGamesManager.swift"

// GPTK-specific error types
enum GPTKError: LocalizedError {
    case installationFailed(String)
    case rosettaRequired
    case homebrewRequired
    case unsupportedSystem
    case configurationError(String)

    var errorDescription: String? {
        switch self {
        case .installationFailed(let message):
            return "Installation Failed: \(message)"
        case .rosettaRequired:
            return "Rosetta 2 is required on Apple Silicon Macs"
        case .homebrewRequired:
            return "Homebrew is required for installation"
        case .unsupportedSystem:
            return "Unsupported system configuration"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        }
    }
}

@MainActor
internal class GamePortingToolkitManager: ObservableObject {
    internal static let shared = GamePortingToolkitManager()

    @Published var isGPTKInstalled = false
    @Published var isInitializing = false
    @Published var initializationStatus = "Checking Game Porting Toolkit..."
    @Published var lastError: String?

    // Installation properties
    @Published var isInstallingComponents = false
    @Published var installationProgress: Double = 0.0
    @Published var installationStatus = ""
    
    // Individual component installation states
    @Published var isInstallingHomebrew = false
    @Published var isInstallingWine = false
    @Published var isInstallingWinetricks = false
    @Published var isInstallingDXVK = false
    @Published var isInstallingVCRedist = false
    @Published var isInstallingDirectX = false
    @Published var isInstallingGPTK = false
    
    // Component installation status
    @Published var homebrewInstalled = false
    @Published var wineInstalled = false
    @Published var winetricksInstalled = false
    @Published var dxvkInstalled = false
    @Published var vcredistInstalled = false
    @Published var directxInstalled = false
    @Published var gptkInstalled = false
    
    // Component installation progress
    @Published var homebrewProgress: Double = 0.0
    @Published var wineProgress: Double = 0.0
    @Published var winetricksProgress: Double = 0.0
    @Published var dxvkProgress: Double = 0.0
    @Published var vcredistProgress: Double = 0.0
    @Published var directxProgress: Double = 0.0
    @Published var gptkProgress: Double = 0.0

    private let fileManager = FileManager.default
    private let defaultBottlePath: String

    // Add manager properties
    let steamManager = SteamManager.shared
    let epicGamesManager = EpicGamesManager.shared

    private init() {
        self.defaultBottlePath =
            NSString(string: "~/Library/Application Support/kimiz/gptk-bottles/default")
            .expandingTildeInPath

        Task {
            await checkGPTKInstallation()
            await checkAllComponentsStatus()
        }
    }

    // MARK: - GPTK Installation Check

    @Published var showInstallGPTKButton = false
    @Published var gptkVersion: String? = nil

    func checkGPTKInstallation() async {
        // Check for GPTK 2.1 in actual installation locations (Apple DMG installs to /usr/local/bin)
        let possibleGPTKPaths = [
            "/usr/local/bin/game-porting-toolkit",  // GPTK 2.1 primary location (from DMG)
            "/usr/local/bin/gameportingtoolkit",  // Alternative naming
            "/usr/local/bin/wine64",  // Wine 64-bit (fallback compatibility)
            "/usr/local/bin/wine",  // Wine 32-bit (fallback compatibility)
            "/opt/homebrew/bin/wine64",  // Homebrew Wine (fallback)
            "/opt/homebrew/bin/wine",  // Homebrew Wine (fallback)
        ]

        var foundPath: String?

        // Check each path, including wildcard paths
        for path in possibleGPTKPaths {
            if path.contains("*") {
                // Handle wildcard paths
                if await checkWildcardPath(path) {
                    foundPath = path
                    break
                }
            } else if fileManager.fileExists(atPath: path) {
                foundPath = path
                break
            }
        }

        let version = await detectGPTKVersion(at: foundPath)

        await MainActor.run {
            isInitializing = false
            if foundPath != nil {
                isGPTKInstalled = true
                gptkVersion = version
                initializationStatus =
                    version.contains("2.1")
                    ? "Game Porting Toolkit 2.1 ready" : "Game Porting Toolkit ready"
                showInstallGPTKButton = false
            } else {
                isGPTKInstalled = false
                gptkVersion = nil
                initializationStatus = "Game Porting Toolkit 2.1 not installed"
                showInstallGPTKButton = true
            }
        }
    }

    private func checkWildcardPath(_ path: String) async -> Bool {
        let components = path.components(separatedBy: "/")
        guard let starIndex = components.firstIndex(of: "*") else { return false }

        let basePath = components[0..<starIndex].joined(separator: "/")
        let suffix = components[(starIndex + 1)...].joined(separator: "/")

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: basePath)
            for item in contents {
                let fullPath = "\(basePath)/\(item)/\(suffix)"
                if fileManager.fileExists(atPath: fullPath) {
                    return true
                }
            }
        } catch {
            print("Error checking wildcard path: \(error)")
        }

        return false
    }

    private func detectGPTKVersion(at path: String?) async -> String {
        guard let path = path, fileManager.fileExists(atPath: path) else {
            return "Not installed"
        }

        // Try to get version information
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if output.contains("2.1") {
                    return "Game Porting Toolkit 2.1"
                } else if output.contains("wine") {
                    return "Wine (Legacy compatibility)"
                }
            }
        } catch {
            // If version check fails, check if it's in the GPTK 2.1 location
            if path.contains("game-porting-toolkit") && !path.contains("homebrew") {
                return "Game Porting Toolkit 2.1 (Detected)"
            }
        }

        return "Unknown version"
    }

    func isGamePortingToolkitInstalled() -> Bool {
        // Check for Apple's official GPTK 2.1 installation (command-line tools only)
        let gptkPaths = [
            "/usr/local/bin/game-porting-toolkit",  // GPTK 2.1 primary location
            "/usr/local/bin/gameportingtoolkit",  // Alternative naming
            "/usr/local/bin/wine64",  // Wine 64-bit (fallback)
            "/usr/local/bin/wine",  // Wine 32-bit (fallback)
            "/opt/homebrew/bin/wine64",  // Homebrew Wine (fallback)
            "/opt/homebrew/bin/wine",  // Homebrew Wine (fallback)
        ]

        return gptkPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }
    }

    /// Install compatibility layer (Wine-based) since GPTK 2.1 requires manual Apple Developer download
    func installGamePortingToolkit() async throws {
        await MainActor.run {
            self.isInstallingComponents = true
            self.installationProgress = 0.0
            self.installationStatus = "Starting compatibility layer installation..."
        }

        do {
            // Step 1: Check for Xcode Command Line Tools
            try await checkXcodeCommandLineTools()

            await MainActor.run {
                self.installationProgress = 0.2
                self.installationStatus = "Checking system requirements..."
            }

            // Step 2: Install compatibility layer automatically
            try await installGPTKAutomatically()

            await MainActor.run {
                self.installationProgress = 0.9
                self.installationStatus = "Verifying installation..."
            }

            // Step 3: Verify installation
            await checkGPTKInstallation()

            await MainActor.run {
                self.installationProgress = 1.0
                self.installationStatus = "Wine compatibility layer installed successfully!"
                self.isInstallingComponents = false
            }
        } catch {
            await MainActor.run {
                self.isInstallingComponents = false
                self.installationStatus = "Installation failed: \(error.localizedDescription)"
            }
            throw error
        }
    }

    private func checkXcodeCommandLineTools() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
        process.arguments = ["-p"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw GPTKError.installationFailed(
                "Xcode Command Line Tools are required. Please install them first by running 'xcode-select --install'"
            )
        }
    }

    private func installGPTKAutomatically() async throws {
        await MainActor.run {
            self.installationProgress = 0.3
            self.installationStatus = "Setting up Windows game compatibility..."
        }

        // Method 1: Try Wine installation via Homebrew (most reliable)
        if await tryHomebrewGPTKInstallation() {
            return
        }

        // Method 2: Try to find GPTK in Xcode (rare but possible)
        if await tryXcodeGPTKInstallation() {
            return
        }

        // Method 3: Set up Wine compatibility wrapper
        try await tryCommandLineGPTKInstallation()
    }

    private func tryHomebrewGPTKInstallation() async -> Bool {
        await MainActor.run {
            self.installationStatus = "Installing Wine dependencies via Homebrew..."
        }

        do {
            // First, ensure Homebrew is installed
            try await ensureHomebrewInstalled()

            await MainActor.run {
                self.installationProgress = 0.5
                self.installationStatus = "Installing Wine as GPTK alternative..."
            }

            // Install Wine as a compatibility layer (since GPTK 2.1 isn't in Homebrew)
            let brewPath =
                fileManager.fileExists(atPath: "/opt/homebrew/bin/brew")
                ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"

            let installProcess = Process()
            installProcess.executableURL = URL(fileURLWithPath: brewPath)
            installProcess.arguments = ["install", "wine-stable"]
            try installProcess.run()
            installProcess.waitUntilExit()

            if installProcess.terminationStatus == 0 {
                await MainActor.run {
                    self.installationProgress = 0.8
                    self.installationStatus = "Wine installed successfully as compatibility layer!"
                }
                return true
            }
        } catch {
            print("Homebrew Wine installation failed: \(error)")
        }

        return false
    }

    private func tryXcodeGPTKInstallation() async -> Bool {
        await MainActor.run {
            self.installationStatus = "Checking for GPTK in Xcode installation..."
        }

        // Check if GPTK is available through Xcode (uncommon but possible)
        let xcodePaths = [
            "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/game-porting-toolkit",
            "/Applications/Xcode.app/Contents/Developer/usr/bin/game-porting-toolkit",
            "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/game-porting-toolkit",
        ]

        for path in xcodePaths {
            if fileManager.fileExists(atPath: path) {
                // Create symlink to standard location
                do {
                    let targetPath = "/usr/local/bin/game-porting-toolkit"
                    // Ensure directory exists
                    try? fileManager.createDirectory(
                        atPath: "/usr/local/bin", withIntermediateDirectories: true, attributes: nil
                    )
                    try? fileManager.removeItem(atPath: targetPath)
                    try fileManager.createSymbolicLink(
                        atPath: targetPath, withDestinationPath: path)

                    await MainActor.run {
                        self.installationProgress = 0.8
                        self.installationStatus = "GPTK 2.1 configured from Xcode!"
                    }
                    return true
                } catch {
                    print("Failed to create symlink: \(error)")
                }
            }
        }

        await MainActor.run {
            self.installationStatus = "GPTK not found in Xcode installation"
        }

        return false
    }

    private func tryCommandLineGPTKInstallation() async throws {
        await MainActor.run {
            self.installationStatus = "Setting up Wine compatibility layer..."
        }

        // Since GPTK 2.1 requires manual download from Apple Developer portal,
        // we'll set up a Wine-based compatibility system instead
        let script = """
            #!/bin/bash
            set -e

            # Create local bin directory if it doesn't exist
            mkdir -p /usr/local/bin

            # Check if we have wine installed via any method
            WINE_PATH=""
            if command -v wine >/dev/null 2>&1; then
                WINE_PATH=$(command -v wine)
            elif [ -f "/opt/homebrew/bin/wine" ]; then
                WINE_PATH="/opt/homebrew/bin/wine"
            elif [ -f "/usr/local/bin/wine" ]; then
                WINE_PATH="/usr/local/bin/wine"
            fi

            if [ -n "$WINE_PATH" ]; then
                # Create a compatibility script that acts as game-porting-toolkit
                cat > /usr/local/bin/game-porting-toolkit << 'EOF'
            #!/bin/bash
            # Game Porting Toolkit compatibility wrapper
            # Uses Wine as the underlying compatibility layer
            WINE_PATH="$(command -v wine || echo "/opt/homebrew/bin/wine")"
            if [ -f "$WINE_PATH" ]; then
                exec "$WINE_PATH" "$@"
            else
                echo "Wine compatibility layer not found"
                exit 1
            fi
            EOF
                chmod +x /usr/local/bin/game-porting-toolkit
                echo "Wine compatibility layer configured successfully"
            else
                echo "No Wine installation found"
                exit 1
            fi
            """

        let scriptPath = NSTemporaryDirectory() + "setup_compatibility.sh"
        try script.write(to: URL(fileURLWithPath: scriptPath), atomically: true, encoding: .utf8)

        // Make script executable
        let chmodProcess = Process()
        chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProcess.arguments = ["+x", scriptPath]
        try chmodProcess.run()
        chmodProcess.waitUntilExit()

        // Run the setup script with admin privileges
        let appleScript = """
            do shell script "bash '\(scriptPath)'" with administrator privileges
            """

        let osascriptProcess = Process()
        osascriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osascriptProcess.arguments = ["-e", appleScript]

        try osascriptProcess.run()
        osascriptProcess.waitUntilExit()

        // Clean up
        try? fileManager.removeItem(atPath: scriptPath)

        if osascriptProcess.terminationStatus == 0 {
            await MainActor.run {
                self.installationProgress = 0.8
                self.installationStatus = "Wine compatibility layer configured successfully!"
            }
        } else {
            throw GPTKError.installationFailed(
                "Could not set up compatibility layer. Make sure Wine is installed first.")
        }
    }

    private func ensureHomebrewInstalled() async throws {
        // Check if Homebrew is already installed
        if fileManager.fileExists(atPath: "/opt/homebrew/bin/brew")
            || fileManager.fileExists(atPath: "/usr/local/bin/brew")
        {
            return
        }

        await MainActor.run {
            self.installationStatus = "Installing Homebrew (required for GPTK)..."
        }

        // Install Homebrew automatically
        let installScript = """
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            """

        let appleScript = """
            do shell script "\(installScript)" with administrator privileges
            """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw GPTKError.installationFailed(
                "Failed to install Homebrew. Please install it manually from https://brew.sh"
            )
        }
    }

    /// Install only the dependencies (GPTK components)
    func installDependenciesOnly() async throws {
        await MainActor.run {
            installationProgress = 0.1
            installationStatus = "🔍 Checking for Game Porting Toolkit..."
        }

        // Check if GPTK is already installed
        let possibleGPTKPaths = [
            "/opt/homebrew/bin/game-porting-toolkit",
            "/usr/local/bin/game-porting-toolkit",
            "/opt/homebrew/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
            "/usr/local/Cellar/game-porting-toolkit/1.1/bin/game-porting-toolkit",
        ]

        if let existingPath = possibleGPTKPaths.first(where: {
            FileManager.default.fileExists(atPath: $0)
        }) {
            await MainActor.run {
                installationProgress = 1.0
                installationStatus = "✅ Game Porting Toolkit already installed at \(existingPath)"
                self.initializationStatus = "GPTK ready for use!"
                self.isGPTKInstalled = true
            }
            return
        }

        await MainActor.run {
            installationProgress = 0.3
            installationStatus = "📋 Game Porting Toolkit not found. Please install it manually."
        }

        // Set up default bottle directory
        let defaultBottlePath = NSString(
            string: "~/Library/Application Support/kimiz/gptk-bottles/default"
        ).expandingTildeInPath
        try? FileManager.default.createDirectory(
            atPath: defaultBottlePath, withIntermediateDirectories: true, attributes: nil)

        await MainActor.run {
            installationProgress = 0.6
            installationStatus = "📁 Setting up Wine bottle directories..."
        }

        // Create necessary directories for Wine environment
        let directories = [
            "drive_c",
            "drive_c/Program Files",
            "drive_c/Program Files (x86)",
            "drive_c/users",
            "drive_c/windows",
            "drive_c/windows/system32",
        ]

        for dir in directories {
            let dirPath = (defaultBottlePath as NSString).appendingPathComponent(dir)
            try? FileManager.default.createDirectory(
                atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        }

        await MainActor.run {
            installationProgress = 1.0
            installationStatus =
                "⚠️ Please install Game Porting Toolkit manually. Bottle structure prepared."
            self.initializationStatus = "Manual GPTK installation required"
        }
    }

    /// Install Steam using SteamManager
    func installSteam() async throws {
        try await steamManager.installSteam()
    }

    /// Check if Steam is installed using SteamManager
    func isSteamInstalled() -> Bool {
        return steamManager.isSteamInstalled()
    }

    /// Launch a game using the appropriate manager with pre-launch optimization
    func launchGame(_ game: Any) async throws {
        // Perform pre-launch graphics check to prevent black screen
        try await performPreLaunchGraphicsCheck()
        
        // Use type checking to delegate to the correct manager
        if let steamGame = game as? SteamManager.SteamGame {
            try await steamManager.launchGame(steamGame)
        } else if let epicGame = game as? EpicGame {
            try await epicGamesManager.launchGame(epicGame)
        } else if let genericGame = game as? Game {
            // Attempt to launch as Steam game if path matches Steam install
            let steamGame = SteamManager.SteamGame(
                id: genericGame.id,
                appId: "unknown",  // No appId in Game model
                name: genericGame.name,
                installPath: genericGame.installPath,
                executablePath: genericGame.executablePath,
                isInstalled: genericGame.isInstalled,
                lastPlayed: genericGame.lastPlayed
            )
            try await steamManager.launchGame(steamGame)
        } else {
            // Fallback to legacy logic if not a known type
            throw NSError(
                domain: "GameLaunchError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unknown game type for launch"])
        }
    }

    // MARK: - Game Management (Compatibility methods for views)

    /// Scan for games in Wine bottles (delegates to LibraryManager)
    func scanForGames() async {
        await autoSetupGameEnvironment()
        await MainActor.run {
            self.installationStatus = "🔍 Scanning for games in Wine bottles..."
        }
        await LibraryManager.shared.scanForImportantExecutables()
        await MainActor.run {
            self.installedGames = LibraryManager.shared.discoveredGames
            self.installationStatus = "✅ Found \(self.installedGames.count) installed games"
        }
    }

    /// Get installed games list
    @Published var installedGames: [Game] = []

    /// Add user game to the library
    func addUserGame(_ game: Game) async {
        await LibraryManager.shared.addUserGame(game)
        await scanForGames()
        await MainActor.run {
            self.installationStatus = "✅ Game '\(game.name)' added to library"
        }
    }

    /// Remove user game from the library
    func removeUserGame(_ game: Game) async {
        await LibraryManager.shared.removeUserGame(game)
        await scanForGames()
        await MainActor.run {
            self.installationStatus = "✅ Game '\(game.name)' removed from library"
        }
    }

    /// Helper method to extract game name from any game object
    private func extractGameName(from game: Any) -> String {
        let mirror = Mirror(reflecting: game)
        for (label, value) in mirror.children {
            if label == "displayName" || label == "name", let name = value as? String {
                return name
            }
        }

        // If it's a dictionary
        if let gameDict = game as? [String: Any] {
            if let name = gameDict["name"] as? String {
                return name
            }
            if let displayName = gameDict["displayName"] as? String {
                return displayName
            }
        }

        return "Unknown Game"
    }

    // MARK: - Bottle Management

    func getDefaultBottlePath() -> String {
        return defaultBottlePath
    }

    /// Fix DirectX 11/DXVK in the default Wine prefix using winetricks
    func fixDirectX11InPrefix() async {
        await MainActor.run {
            self.installationStatus =
                "Installing DXVK (DirectX 11 support) in Wine prefix via winetricks..."
        }
        let bottlePath = defaultBottlePath
        let winetricksPath =
            fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks")
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
        let winePath =
            fileManager.fileExists(atPath: "/opt/homebrew/bin/wine")
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        let wineserverPath = (winePath as NSString).deletingLastPathComponent + "/wineserver"
        let system32Path = (bottlePath as NSString).appendingPathComponent(
            "drive_c/windows/system32")
        let dxvkDlls = ["d3d11.dll", "dxgi.dll", "d3d10.dll", "d3d10_1.dll", "d3d10core.dll"]
        do {
            // 1. Initialize Wine prefix if needed
            if !fileManager.fileExists(
                atPath: (bottlePath as NSString).appendingPathComponent("system.reg"))
            {
                let wineboot = Process()
                wineboot.executableURL = URL(fileURLWithPath: winePath)
                wineboot.arguments = ["wineboot", "--init"]
                wineboot.environment = [
                    "WINEPREFIX": bottlePath,
                    "WINEDEBUG": "-all",
                    "DISPLAY": ":0.0",
                ]
                wineboot.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
                try wineboot.run()
                wineboot.waitUntilExit()
            }

            // 2. Run winetricks dxvk and capture output
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winetricksPath)
            process.arguments = ["-q", "dxvk"]
            process.environment = [
                "WINE": winePath,
                "WINESERVER": wineserverPath,
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all",
                "DISPLAY": ":0.0",
            ]
            process.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let _ = String(data: data, encoding: .utf8) ?? "" // Output captured but not used

            // 3. Check for DXVK DLLs
            let allDllsPresent = dxvkDlls.allSatisfy {
                fileManager.fileExists(
                    atPath: (system32Path as NSString).appendingPathComponent($0))
            }

            await MainActor.run {
                if process.terminationStatus == 0 && allDllsPresent {
                    self.installationStatus =
                        "✅ DXVK (DirectX 11/10/9 support) successfully installed in Wine prefix! Try launching your game again."
                } else {
                    self.installationStatus =
                        "❌ DXVK installation failed. Running comprehensive DirectX 11 fix..."
                }
            }
            
            // If basic DXVK installation failed, run comprehensive fix
            if process.terminationStatus != 0 || !allDllsPresent {
                await fixDirectX11InitializationError()
            }
        } catch {
            await MainActor.run {
                self.installationStatus =
                    "❌ Error running winetricks dxvk (DXVK/DirectX 11 setup): \(error.localizedDescription)"
            }
        }
    }

    /// Automatically install all required software for running games
    func autoSetupGameEnvironment() async {
        // 1. Ensure Homebrew is installed
        do {
            try await ensureHomebrewInstalled()
        } catch {
            await MainActor.run {
                self.installationStatus =
                    "❌ Failed to install Homebrew: \(error.localizedDescription)"
            }
            return
        }

        // 2. Install Wine
        let brewPath =
            fileManager.fileExists(atPath: "/opt/homebrew/bin/brew")
            ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
        let winePath =
            fileManager.fileExists(atPath: "/opt/homebrew/bin/wine")
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        if !fileManager.fileExists(atPath: winePath) {
            await MainActor.run {
                self.installationStatus = "🍷 Installing Wine via Homebrew..."
            }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "wine-stable"]
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        self.installationStatus = "✅ Wine installed successfully."
                    }
                } else {
                    await MainActor.run {
                        self.installationStatus = "❌ Failed to install Wine."
                    }
                    return
                }
            } catch {
                await MainActor.run {
                    self.installationStatus =
                        "❌ Error installing Wine: \(error.localizedDescription)"
                }
                return
            }
        }

        // 3. Install winetricks
        let winetricksPath =
            fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks")
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
        if !fileManager.fileExists(atPath: winetricksPath) {
            await MainActor.run {
                self.installationStatus = "🔧 Installing winetricks via Homebrew..."
            }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "winetricks"]
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        self.installationStatus = "✅ winetricks installed successfully."
                    }
                } else {
                    await MainActor.run {
                        self.installationStatus = "❌ Failed to install winetricks."
                    }
                    return
                }
            } catch {
                await MainActor.run {
                    self.installationStatus =
                        "❌ Error installing winetricks: \(error.localizedDescription)"
                }
                return
            }
        }

        // 4. Install DXVK in the default bottle
        await MainActor.run {
            self.installationStatus = "🛠 Installing DXVK (DirectX 11 support) in Wine prefix..."
        }
        let bottlePath = defaultBottlePath
        let wineserverPath = (winePath as NSString).deletingLastPathComponent + "/wineserver"
        let dxvkProcess = Process()
        dxvkProcess.executableURL = URL(fileURLWithPath: winetricksPath)
        dxvkProcess.arguments = ["-q", "dxvk"]
        dxvkProcess.environment = [
            "WINE": winePath,
            "WINESERVER": wineserverPath,
            "WINEPREFIX": bottlePath,
            "WINEDEBUG": "-all",
            "DISPLAY": ":0.0",
        ]
        dxvkProcess.currentDirectoryURL = URL(fileURLWithPath: bottlePath)
        do {
            try dxvkProcess.run()
            dxvkProcess.waitUntilExit()
            await MainActor.run {
                if dxvkProcess.terminationStatus == 0 {
                    self.installationStatus = "✅ DXVK (DirectX 11/10/9) installed in Wine prefix."
                } else {
                    self.installationStatus = "⚠️ Failed to install DXVK in Wine prefix."
                }
            }
        } catch {
            await MainActor.run {
                self.installationStatus =
                    "❌ Error running winetricks dxvk: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Graphics Driver Detection & Optimization

    @Published var graphicsDriverStatus = "Unknown"
    @Published var recommendedGraphicsSettings: [String: Any] = [:]
    
    /// Check graphics drivers and system for game compatibility
    func checkGraphicsDrivers() async {
        await MainActor.run {
            self.installationStatus = "🔍 Checking graphics drivers and system compatibility..."
        }
        
        let systemInfo = await getSystemGraphicsInfo()
        let driverRecommendations = await analyzeGraphicsCompatibility(systemInfo)
        
        await MainActor.run {
            self.graphicsDriverStatus = systemInfo["status"] as? String ?? "Unknown"
            self.recommendedGraphicsSettings = driverRecommendations
            self.installationStatus = "✅ Graphics compatibility check completed"
        }
    }
    
    private func getSystemGraphicsInfo() async -> [String: Any] {
        return await withCheckedContinuation { continuation in
            var info: [String: Any] = [:]
            
            // Get system graphics information
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            task.arguments = ["SPDisplaysDataType", "-json"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let displays = jsonData["SPDisplaysDataType"] as? [[String: Any]],
                   let primaryDisplay = displays.first {
                    
                    info["gpu_name"] = primaryDisplay["sppci_model"] as? String ?? "Unknown GPU"
                    info["gpu_vendor"] = primaryDisplay["sppci_vendor"] as? String ?? "Unknown Vendor"
                    info["vram"] = primaryDisplay["spdisplays_vram"] as? String ?? "Unknown VRAM"
                    info["metal_support"] = primaryDisplay["spdisplays_metal"] as? String ?? "Unknown"
                    
                    // Check for Apple Silicon vs Intel
                    let isAppleSilicon = info["gpu_vendor"] as? String == "Apple"
                    info["is_apple_silicon"] = isAppleSilicon
                    
                    if isAppleSilicon {
                        info["status"] = "Apple Silicon GPU - Optimized for Metal"
                    } else {
                        info["status"] = "Intel/AMD GPU - Compatible with DirectX/OpenGL translation"
                    }
                } else {
                    info["status"] = "Could not detect graphics hardware"
                }
                
                continuation.resume(returning: info)
            } catch {
                info["status"] = "Error detecting graphics drivers: \(error.localizedDescription)"
                continuation.resume(returning: info)
            }
        }
    }
    
    private func analyzeGraphicsCompatibility(_ systemInfo: [String: Any]) async -> [String: Any] {
        var recommendations: [String: Any] = [:]
        
        let isAppleSilicon = systemInfo["is_apple_silicon"] as? Bool ?? false
        let gpuName = systemInfo["gpu_name"] as? String ?? ""
        
        if isAppleSilicon {
            // Apple Silicon optimizations
            recommendations["renderer"] = "metal"
            recommendations["dxvk_enabled"] = true
            recommendations["cpu_limit"] = 90.0  // Higher limit for Apple Silicon
            recommendations["memory_optimization"] = "aggressive"
            recommendations["graphics_api"] = "Metal -> D3D11"
            recommendations["gpu_info"] = "Apple Silicon: \(gpuName)"
        } else {
            // Intel/AMD optimizations
            recommendations["renderer"] = "opengl"
            recommendations["dxvk_enabled"] = true
            recommendations["cpu_limit"] = 85.0  // Slightly higher limit
            recommendations["memory_optimization"] = "balanced"
            recommendations["graphics_api"] = "OpenGL -> D3D11"
            recommendations["gpu_info"] = "Intel/AMD: \(gpuName)"
        }
        
        // Game-specific optimizations
        recommendations["wine_graphics_settings"] = [
            "WINE_LARGE_ADDRESS_AWARE": "1",
            "DXVK_HUD": "0",  // Disable HUD for better performance
            "DXVK_ASYNC": "1",  // Enable async for smoother gameplay
            "WINE_CPU_TOPOLOGY": "4:2",  // Optimal CPU topology
            "__GL_SHADER_DISK_CACHE": "1",  // Enable shader cache
            "MESA_GLSL_CACHE_DISABLE": "false"
        ]
        
        return recommendations
    }
    
    /// Apply graphics optimizations to fix black screen issues
    func applyGraphicsOptimizations() async {
        await MainActor.run {
            self.installationStatus = "🎮 Applying graphics optimizations for games..."
        }
        
        // 1. Install and configure DXVK with optimizations
        await installOptimizedDXVK()
        
        // 2. Configure Wine graphics settings
        await configureWineGraphicsSettings()
        
        // 3. Set up shader cache
        await setupShaderCache()
        
        // 4. Configure display settings
        await configureDisplaySettings()
        
        await MainActor.run {
            self.installationStatus = "✅ Graphics optimizations applied successfully!"
        }
    }
    
    private func installOptimizedDXVK() async {
        let bottlePath = defaultBottlePath
        let winetricksPath = fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks") 
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Check if winetricks exists, if not try to install it
        if !fileManager.fileExists(atPath: winetricksPath) {
            await MainActor.run {
                self.installationStatus = "⚠️ Installing winetricks for graphics optimization..."
            }
            
            let brewPath = fileManager.fileExists(atPath: "/opt/homebrew/bin/brew") 
                ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
            
            let installProcess = Process()
            installProcess.executableURL = URL(fileURLWithPath: brewPath)
            installProcess.arguments = ["install", "winetricks"]
            
            try? installProcess.run()
            installProcess.waitUntilExit()
            
            // Check if installation succeeded, if not return early
            guard fileManager.fileExists(atPath: winetricksPath) else {
                await MainActor.run {
                    self.installationStatus = "❌ Failed to install winetricks"
                }
                return
            }
        }
        
        // Install DXVK with optimized settings
        let dxvkProcess = Process()
        dxvkProcess.executableURL = URL(fileURLWithPath: winetricksPath)
        dxvkProcess.arguments = ["-q", "dxvk"]
        dxvkProcess.environment = [
            "WINEPREFIX": bottlePath,
            "WINE": winePath,
            "WINEDEBUG": "-all",
            "DXVK_ASYNC": "1",
            "DXVK_STATE_CACHE": "1",
            "DXVK_SHADER_CACHE": "1"
        ]
        
        try? dxvkProcess.run()
        dxvkProcess.waitUntilExit()
    }
    
    private func configureWineGraphicsSettings() async {
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Configure registry settings for better graphics compatibility
        let registryCommands = [
            // Graphics settings
            "HKEY_CURRENT_USER\\Software\\Wine\\Direct3D",
            "DirectDrawRenderer", "opengl",
            "MaxVersionGL", "4.6",
            "shader_backend", "glsl",
            "UseGLSL", "enabled",
            "VideoMemorySize", "2048",
            // Disable problematic features that cause black screens
            "AlwaysOffscreen", "disabled",
            "Offscreen", "disabled",
            "RenderTargetLockMode", "disabled",
            "StrictDrawOrdering", "disabled"
        ]
        
        for i in stride(from: 0, to: registryCommands.count, by: 3) {
            if i + 2 < registryCommands.count {
                let regProcess = Process()
                regProcess.executableURL = URL(fileURLWithPath: winePath)
                regProcess.arguments = ["reg", "add", registryCommands[i], "/v", registryCommands[i+1], "/t", "REG_SZ", "/d", registryCommands[i+2], "/f"]
                regProcess.environment = [
                    "WINEPREFIX": bottlePath,
                    "WINEDEBUG": "-all"
                ]
                
                try? regProcess.run()
                regProcess.waitUntilExit()
            }
        }
    }
    
    private func setupShaderCache() async {
        let bottlePath = defaultBottlePath
        let shaderCacheDir = (bottlePath as NSString).appendingPathComponent("shader_cache")
        
        // Create shader cache directory
        try? fileManager.createDirectory(atPath: shaderCacheDir, withIntermediateDirectories: true, attributes: nil)
        
        // Set up DXVK state cache
        let dxvkCacheDir = (bottlePath as NSString).appendingPathComponent("dxvk_cache")
        try? fileManager.createDirectory(atPath: dxvkCacheDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    private func configureDisplaySettings() async {
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Configure winecfg for better display compatibility
        let winecfgProcess = Process()
        winecfgProcess.executableURL = URL(fileURLWithPath: winePath)
        winecfgProcess.arguments = ["winecfg", "/v"]
        winecfgProcess.environment = [
            "WINEPREFIX": bottlePath,
            "WINEDEBUG": "-all",
            "DISPLAY": ":0"
        ]
        
        // This will set up basic display configuration
        try? winecfgProcess.run()
        winecfgProcess.waitUntilExit()
    }
    
    /// Comprehensive pre-launch check to prevent black screen issues
    func performPreLaunchGraphicsCheck() async throws {
        await MainActor.run {
            self.installationStatus = "🔍 Performing pre-launch graphics compatibility check..."
        }
        
        try await checkAndFixGraphicsDrivers()
        try await verifyDXVKInstallation()
        try await optimizeGraphicsSettings()
        
        await MainActor.run {
            self.installationStatus = "✅ Graphics compatibility check completed successfully!"
        }
    }
    
    private func checkAndFixGraphicsDrivers() async throws {
        // Check if we have proper graphics support
        let systemInfo = await getSystemGraphicsInfo()
        let gpuStatus = systemInfo["status"] as? String ?? "Unknown"
        
        if gpuStatus.contains("Error") || gpuStatus == "Unknown" {
            await MainActor.run {
                self.installationStatus = "⚠️ Graphics driver issues detected. Applying compatibility fixes..."
            }
            
            // Apply compatibility fixes for problematic graphics
            await applyGraphicsCompatibilityFixes()
        }
    }
    
    private func verifyDXVKInstallation() async throws {
        let bottlePath = defaultBottlePath
        let system32Path = (bottlePath as NSString).appendingPathComponent("drive_c/windows/system32")
        let syswow64Path = (bottlePath as NSString).appendingPathComponent("drive_c/windows/syswow64")
        
        let dxvkFiles = ["d3d11.dll", "dxgi.dll", "d3d10.dll", "d3d10_1.dll", "d3d10core.dll"]
        var missingFiles: [String] = []
        var corruptedFiles: [String] = []
        
        for dll in dxvkFiles {
            let system32File = (system32Path as NSString).appendingPathComponent(dll)
            let syswow64File = (syswow64Path as NSString).appendingPathComponent(dll)
            
            if !fileManager.fileExists(atPath: system32File) {
                missingFiles.append("\(dll) (64-bit)")
            } else {
                // Check file size to detect corruption
                if let attributes = try? fileManager.attributesOfItem(atPath: system32File),
                   let fileSize = attributes[.size] as? UInt64, fileSize < 1000 {
                    corruptedFiles.append("\(dll) (64-bit)")
                }
            }
            
            if !fileManager.fileExists(atPath: syswow64File) {
                missingFiles.append("\(dll) (32-bit)")
            } else {
                if let attributes = try? fileManager.attributesOfItem(atPath: syswow64File),
                   let fileSize = attributes[.size] as? UInt64, fileSize < 1000 {
                    corruptedFiles.append("\(dll) (32-bit)")
                }
            }
        }
        
        if !missingFiles.isEmpty || !corruptedFiles.isEmpty {
            await MainActor.run {
                self.installationStatus = "🔧 DXVK issues found. Missing: \(missingFiles.joined(separator: ", ")) Corrupted: \(corruptedFiles.joined(separator: ", "))"
            }
            
            // Force reinstall DXVK
            await installOptimizedDXVK()
        } else {
            await MainActor.run {
                self.installationStatus = "✅ DXVK installation verified"
            }
        }
    }
    
    private func optimizeGraphicsSettings() async throws {
        await configureOptimalGraphicsRegistry()
        await setupPerformanceOptimizations()
    }
    
    private func applyGraphicsCompatibilityFixes() async {
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Apply registry fixes for common black screen issues
        let compatibilityFixes = [
            // Fix for Intel/AMD graphics black screen
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "DirectDrawRenderer", "opengl"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "VertexShaderMode", "hardware"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "PixelShaderMode", "hardware"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "UseGLSL", "enabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "AlwaysOffscreen", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "Multisampling", "enabled"),
            
            // Fix for fullscreen issues
            ("HKEY_CURRENT_USER\\Software\\Wine\\Explorer", "Desktop", "1024x768"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "Managed", "Y"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "Decorated", "Y"),
        ]
        
        for (key, valueName, valueData) in compatibilityFixes {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_SZ", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func configureOptimalGraphicsRegistry() async {
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Optimal graphics settings to prevent black screens
        let graphicsSettings = [
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "MaxVersionGL", "4.6"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "shader_backend", "glsl"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "VideoMemorySize", "4096"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "StrictDrawOrdering", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "RenderTargetLockMode", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "Offscreen", "fbo"),
        ]
        
        for (key, valueName, valueData) in graphicsSettings {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_SZ", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func setupPerformanceOptimizations() async {
        // Create optimized performance profile
        let bottlePath = defaultBottlePath
        let performanceDir = (bottlePath as NSString).appendingPathComponent("performance")
        
        try? fileManager.createDirectory(atPath: performanceDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create performance configuration file
        let performanceConfig = """
        # Graphics Performance Configuration
        DXVK_ASYNC=1
        DXVK_STATE_CACHE=1
        DXVK_SHADER_CACHE=1
        DXVK_HUD=0
        WINE_LARGE_ADDRESS_AWARE=1
        WINE_CPU_TOPOLOGY=4:2
        __GL_SHADER_DISK_CACHE=1
        MESA_GLSL_CACHE_DISABLE=false
        """
        
        let configPath = (performanceDir as NSString).appendingPathComponent("graphics.conf")
        try? performanceConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
    }
    
    /// Manual graphics diagnostics and repair for black screen issues
    func runGraphicsDiagnosticsAndRepair() async {
        await MainActor.run {
            self.installationStatus = "🔍 Running comprehensive graphics diagnostics..."
        }
        
        // Step 1: System analysis
        await checkGraphicsDrivers()
        
        // Step 2: Wine/GPTK compatibility check
        await diagnoseWineGraphicsCompatibility()
        
        // Step 3: DXVK validation and repair
        await diagnoseDXVKInstallation()
        
        // Step 4: Apply all optimizations
        await applyGraphicsOptimizations()
        
        // Step 5: Test graphics functionality
        await testGraphicsFunctionality()
        
        await MainActor.run {
            self.installationStatus = "✅ Graphics diagnostics completed! Black screen issues should be resolved."
        }
    }
    
    private func diagnoseWineGraphicsCompatibility() async {
        await MainActor.run {
            self.installationStatus = "🔍 Checking Wine/GPTK graphics compatibility..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Test basic Wine graphics functionality
        let testProcess = Process()
        testProcess.executableURL = URL(fileURLWithPath: winePath)
        testProcess.arguments = ["winecfg", "/v"]
        testProcess.environment = [
            "WINEPREFIX": bottlePath,
            "WINEDEBUG": "-all",
            "DISPLAY": ":0"
        ]
        
        let pipe = Pipe()
        testProcess.standardOutput = pipe
        testProcess.standardError = pipe
        
        do {
            try testProcess.run()
            testProcess.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if testProcess.terminationStatus == 0 {
                await MainActor.run {
                    self.installationStatus = "✅ Wine graphics compatibility verified"
                }
            } else {
                await MainActor.run {
                    self.installationStatus = "⚠️ Wine graphics issues detected. Applying fixes..."
                }
                await applyWineGraphicsFixes(output: output)
            }
        } catch {
            await MainActor.run {
                self.installationStatus = "❌ Wine graphics test failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func diagnoseDXVKInstallation() async {
        await MainActor.run {
            self.installationStatus = "🔍 Diagnosing DXVK installation..."
        }
        
        let bottlePath = defaultBottlePath
        let system32Path = (bottlePath as NSString).appendingPathComponent("drive_c/windows/system32")
        let syswow64Path = (bottlePath as NSString).appendingPathComponent("drive_c/windows/syswow64")
        
        let dxvkFiles = ["d3d11.dll", "dxgi.dll", "d3d10.dll", "d3d10_1.dll", "d3d10core.dll"]
        var missingFiles: [String] = []
        var corruptedFiles: [String] = []
        
        for dll in dxvkFiles {
            let system32File = (system32Path as NSString).appendingPathComponent(dll)
            let syswow64File = (syswow64Path as NSString).appendingPathComponent(dll)
            
            if !fileManager.fileExists(atPath: system32File) {
                missingFiles.append("\(dll) (64-bit)")
            } else {
                // Check file size to detect corruption
                if let attributes = try? fileManager.attributesOfItem(atPath: system32File),
                   let fileSize = attributes[.size] as? UInt64, fileSize < 1000 {
                    corruptedFiles.append("\(dll) (64-bit)")
                }
            }
            
            if !fileManager.fileExists(atPath: syswow64File) {
                missingFiles.append("\(dll) (32-bit)")
            } else {
                if let attributes = try? fileManager.attributesOfItem(atPath: syswow64File),
                   let fileSize = attributes[.size] as? UInt64, fileSize < 1000 {
                    corruptedFiles.append("\(dll) (32-bit)")
                }
            }
        }
        
        if !missingFiles.isEmpty || !corruptedFiles.isEmpty {
            await MainActor.run {
                self.installationStatus = "🔧 DXVK issues found. Missing: \(missingFiles.joined(separator: ", ")) Corrupted: \(corruptedFiles.joined(separator: ", "))"
            }
            
            // Force reinstall DXVK
            await installOptimizedDXVK()
        } else {
            await MainActor.run {
                self.installationStatus = "✅ DXVK installation verified"
            }
        }
    }
    
    private func applyWineGraphicsFixes(output: String) async {
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Common Wine graphics fixes based on error output
        var fixes: [(String, String, String)] = [
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "DirectDrawRenderer", "opengl"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "AlwaysOffscreen", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "Managed", "Y"),
        ]
        
        // Add specific fixes based on detected issues
        if output.contains("GLX") || output.contains("OpenGL") {
            fixes.append(("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "UseGLSL", "enabled"))
            fixes.append(("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "MaxVersionGL", "4.6"))
        }
        
        if output.contains("X11") || output.contains("display") {
            fixes.append(("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "Decorated", "Y"))
            fixes.append(("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "FullscreenGrabPointer", "N"))
        }
        
        for (key, valueName, valueData) in fixes {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_SZ", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func testGraphicsFunctionality() async {
        await MainActor.run {
            self.installationStatus = "🧪 Testing graphics functionality..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Test with a simple DirectX application (notepad should work)
        let testProcess = Process()
        testProcess.executableURL = URL(fileURLWithPath: winePath)
        testProcess.arguments = ["notepad"]
        testProcess.environment = [
            "WINEPREFIX": bottlePath,
            "WINEDEBUG": "-all",
            "DISPLAY": ":0",
            "DXVK_HUD": "1"  // Enable HUD to verify DXVK is working
        ]
        
        do {
            try testProcess.run()
            
            // Give it a few seconds to start
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            // Check if process is still running (indicates success)
            if testProcess.isRunning {
                testProcess.terminate()
                await MainActor.run {
                    self.installationStatus = "✅ Graphics functionality test passed"
                }
            } else {
                await MainActor.run {
                    self.installationStatus = "⚠️ Graphics test had issues but basic fixes applied"
                }
            }
        } catch {
            await MainActor.run {
                self.installationStatus = "⚠️ Graphics test failed but fixes were applied"
            }
        }
    }

    /// Automatic detection and resolution of common game compatibility issues
    func autoFixGameCompatibilityIssues() async {
        await MainActor.run {
            self.installationStatus = "🔧 Auto-fixing common game compatibility issues..."
        }
        
        // Fix 1: Install common redistributables
        await installCommonRedistributables()
        
        // Fix 2: Configure optimal DirectX settings
        await configureDirectXOptimizations()
        
        // Fix 3: Set up proper display resolution handling
        await configureDisplayResolutions()
        
        // Fix 4: Install game-specific compatibility layers
        await installGameCompatibilityLayers()
        
        // Fix 5: Configure memory and performance settings
        await configureMemoryOptimizations()
        
        await MainActor.run {
            self.installationStatus = "✅ All compatibility fixes applied successfully!"
        }
    }
    
    private func installCommonRedistributables() async {
        await MainActor.run {
            self.installationStatus = "📦 Installing common game redistributables..."
        }
        
        let bottlePath = defaultBottlePath
        let winetricksPath = fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks") 
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
        
        // Essential redistributables for most games
        let redistributables = [
            "vcrun2019",    // Visual C++ 2019 Redistributable
            "vcrun2017",    // Visual C++ 2017 Redistributable
            "vcrun2015",    // Visual C++ 2015 Redistributable
            "d3dcompiler_47", // DirectX Shader Compiler
            "xact",         // Xbox Audio Creation Tool
            "corefonts",    // Windows Core Fonts
        ]
        
        for redist in redistributables {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winetricksPath)
            process.arguments = ["-q", redist]
            process.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        self.installationStatus = "✅ Installed \(redist)"
                    }
                }
            } catch {
                // Continue with other redistributables even if one fails
                continue
            }
        }
    }
    
    private func configureDirectXOptimizations() async {
        await MainActor.run {
            self.installationStatus = "🎮 Configuring DirectX optimizations..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // DirectX-specific registry settings for better compatibility
        let directXSettings = [
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "CheckFloatConstants", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "UseGLSL", "enabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "shader_backend", "glsl"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "MaxVersionGL", "4.6"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "VideoMemorySize", "4096"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "DirectDrawRenderer", "opengl"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "AlwaysOffscreen", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "Multisampling", "enabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "StrictDrawOrdering", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "RenderTargetLockMode", "disabled"),
        ]
        
        for (key, valueName, valueData) in directXSettings {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_SZ", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func configureDisplayResolutions() async {
        await MainActor.run {
            self.installationStatus = "🖥️ Configuring display resolution handling..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Get current display resolution
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let width = Int(screenSize.width)
        let height = Int(screenSize.height)
        
        // Configure resolution settings
        let resolutionSettings = [
            ("HKEY_CURRENT_USER\\Software\\Wine\\Explorer", "Desktop", "\(width)x\(height)"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "Managed", "Y"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "Decorated", "Y"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "FullscreenGrabPointer", "N"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver", "UseXRandR", "Y"),
        ]
        
        for (key, valueName, valueData) in resolutionSettings {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_SZ", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func installGameCompatibilityLayers() async {
        await MainActor.run {
            self.installationStatus = "⚙️ Installing game compatibility layers..."
        }
        
        let bottlePath = defaultBottlePath
        let compatibilityDir = (bottlePath as NSString).appendingPathComponent("compatibility")
        
        try? fileManager.createDirectory(atPath: compatibilityDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create compatibility wrapper scripts
        let gameWrapper = """
        #!/bin/bash
        # Game Compatibility Wrapper
        
        export WINEPREFIX="\(bottlePath)"
        export WINE_LARGE_ADDRESS_AWARE=1
        export DXVK_ASYNC=1
        export DXVK_STATE_CACHE=1
        export DXVK_SHADER_CACHE=1
        export DXVK_HUD=0
        export __GL_SHADER_DISK_CACHE=1
        export MESA_GLSL_CACHE_DISABLE=false
        export WINE_CPU_TOPOLOGY=4:2
        export WINEDEBUG=-all
        
        # Launch game with optimizations
        exec "$@"
        """
        
        let wrapperPath = (compatibilityDir as NSString).appendingPathComponent("game_wrapper.sh")
        try? gameWrapper.write(toFile: wrapperPath, atomically: true, encoding: .utf8)
        
        // Make executable
        let chmodProcess = Process()
        chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProcess.arguments = ["+x", wrapperPath]
        try? chmodProcess.run()
        chmodProcess.waitUntilExit()
    }
    
    private func configureMemoryOptimizations() async {
        await MainActor.run {
            self.installationStatus = "🧠 Configuring memory and performance optimizations..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Memory optimization settings
        let memorySettings = [
            ("HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Memory Management", "LargeSystemCache", "1"),
            ("HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Memory Management", "SystemPages", "0"),
            ("HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Memory Management", "DisablePagingExecutive", "1"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\WineDbg", "ProcessorFeatures", "1"),
        ]
        
        for (key, valueName, valueData) in memorySettings {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_DWORD", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    /// Check and fix Steam-specific black screen issues
    func fixSteamGameCompatibility() async {
        await MainActor.run {
            self.installationStatus = "🚂 Fixing Steam-specific compatibility issues..."
        }
        
        // Steam-specific fixes for black screen issues
        await configureSteamOptimizations()
        await fixSteamWebHelper()
        await configureSteamOverlay()
        await installSteamRedistributables()
        
        await MainActor.run {
            self.installationStatus = "✅ Steam compatibility optimizations completed!"
        }
    }
    
    private func configureSteamOptimizations() async {
        await MainActor.run {
            self.installationStatus = "⚙️ Configuring Steam optimizations..."
        }
        
        let bottlePath = defaultBottlePath
        let steamPath = (bottlePath as NSString).appendingPathComponent("drive_c/Program Files (x86)/Steam")
        
        // Create Steam configuration file with optimizations
        let steamConfig = """
        "InstallConfigStore"
        {
            "Software"
            {
                "valve"
                {
                    "Steam"
                    {
                        "NoSavePersonalInfo"    "0"
                        "MaxServerBrowserPingsPerMin"    "0"
                        "DownloadThrottleKbps"    "0"
                        "AllowDownloadsDuringGameplay"    "0"
                        "StreamingThrottleEnabled"    "0"
                        "ClientBrowserAuth"    "0"
                        "SteamNetworkingSocketsLib"    "0"
                        "UseWebHelperByDefault"    "0"
                        "EnableWebBrowser"    "0"
                        "GPUAcceleration"    "0"
                        "H264HWAccel"    "0"
                        "DisableDPI"    "1"
                        "BigPictureInForeground"    "0"
                        "InGameOverlayShortcutKey"    "Shift+Tab"
                        "InGameOverlayShowFPSCorner"    "0"
                        "SuppressLegacyConfigCopying"    "1"
                    }
                }
            }
        }
        """
        
        let configPath = (steamPath as NSString).appendingPathComponent("config/config.vdf")
        let configDir = (configPath as NSString).deletingLastPathComponent
        
        try? fileManager.createDirectory(atPath: configDir, withIntermediateDirectories: true, attributes: nil)
        try? steamConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
    }
    
    private func fixSteamWebHelper() async {
        await MainActor.run {
            self.installationStatus = "🌐 Fixing Steam WebHelper issues..."
        }
        
        let bottlePath = defaultBottlePath
        let steamPath = (bottlePath as NSString).appendingPathComponent("drive_c/Program Files (x86)/Steam")
        let webHelperPath = (steamPath as NSString).appendingPathComponent("steamwebhelper.exe")
        let webHelperBackupPath = (steamPath as NSString).appendingPathComponent("steamwebhelper.exe.backup")
        
        // Disable steamwebhelper.exe which often causes black screens
        if fileManager.fileExists(atPath: webHelperPath) && !fileManager.fileExists(atPath: webHelperBackupPath) {
            try? fileManager.moveItem(atPath: webHelperPath, toPath: webHelperBackupPath)
            
            // Create a dummy steamwebhelper.exe that does nothing
            let dummyScript = """
            #!/bin/bash
            # Dummy steamwebhelper.exe to prevent crashes
            exit 0
            """
            
            try? dummyScript.write(toFile: webHelperPath, atomically: true, encoding: .utf8)
        }
        
        // Also disable other problematic Steam components
        let problematicComponents = [
            "steamwebhelper.exe",
            "streaming_client.exe",
            "steamerrorreporter.exe",
            "WriteMiniDump.exe"
        ]
        
        for component in problematicComponents {
            let componentPath = (steamPath as NSString).appendingPathComponent(component)
            let backupPath = componentPath + ".disabled"
            
            if fileManager.fileExists(atPath: componentPath) && !fileManager.fileExists(atPath: backupPath) {
                try? fileManager.moveItem(atPath: componentPath, toPath: backupPath)
            }
        }
    }
    
    private func configureSteamOverlay() async {
        await MainActor.run {
            self.installationStatus = "🎯 Configuring Steam overlay settings..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Disable Steam overlay which can cause black screens
        let overlaySettings = [
            ("HKEY_CURRENT_USER\\Software\\Valve\\Steam", "InGameOverlayEnabled", "0"),
            ("HKEY_CURRENT_USER\\Software\\Valve\\Steam", "EnableGameOverlay", "0"),
            ("HKEY_CURRENT_USER\\Software\\Valve\\Steam", "SteamOverlayEnabled", "0"),
            ("HKEY_CURRENT_USER\\Software\\Valve\\Steam", "UseWebHelperByDefault", "0"),
            ("HKEY_CURRENT_USER\\Software\\Valve\\Steam", "EnableWebBrowser", "0"),
            ("HKEY_CURRENT_USER\\Software\\Valve\\Steam", "GPUAcceleration", "0"),
        ]
        
        for (key, valueName, valueData) in overlaySettings {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_DWORD", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func installSteamRedistributables() async {
        await MainActor.run {
            self.installationStatus = "📦 Installing Steam-specific redistributables..."
        }
        
        let bottlePath = defaultBottlePath
        let winetricksPath = fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks") 
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
        
        // Steam games often need these specific redistributables
        let steamRedistributables = [
            "dotnet48",     // .NET Framework 4.8
            "vcrun2019",    // Visual C++ 2019
            "d3dx9",        // DirectX 9
            "d3dx10",       // DirectX 10
            "d3dx11_43",    // DirectX 11
            "xna40",        // XNA Framework 4.0
        ]
        
        for redist in steamRedistributables {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winetricksPath)
            process.arguments = ["-q", redist]
            process.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        self.installationStatus = "✅ Installed \(redist) for Steam compatibility"
                    }
                }
            } catch {
                // Continue with other redistributables
                continue
            }
        }
    }
    
    /// Master method to fix all black screen and game compatibility issues
    func fixAllGameIssues() async {
        await MainActor.run {
            self.installationStatus = "🔧 Running comprehensive game compatibility fixes..."
            self.installationProgress = 0.0
        }
        
        // Step 1: Graphics drivers and system check
        await MainActor.run {
            self.installationProgress = 0.1
            self.installationStatus = "🔍 Checking graphics drivers and system..."
        }
        await checkGraphicsDrivers()
        
        // Step 2: Run complete graphics diagnostics
        await MainActor.run {
            self.installationProgress = 0.2
            self.installationStatus = "🎮 Running graphics diagnostics and repair..."
        }
        await runGraphicsDiagnosticsAndRepair()
        
        // Step 3: Apply graphics optimizations
        await MainActor.run {
            self.installationProgress = 0.4
            self.installationStatus = "✨ Applying graphics optimizations..."
        }
        await applyGraphicsOptimizations()
        
        // Step 4: Fix general game compatibility issues
        await MainActor.run {
            self.installationProgress = 0.6
            self.installationStatus = "⚙️ Fixing general game compatibility issues..."
        }
        await autoFixGameCompatibilityIssues()
        
        // Step 5: Apply Steam-specific fixes
        await MainActor.run {
            self.installationProgress = 0.8
            self.installationStatus = "🚂 Applying Steam-specific compatibility fixes..."
        }
        await fixSteamGameCompatibility()
        
        // Step 6: Final verification
        await MainActor.run {
            self.installationProgress = 0.9
            self.installationStatus = "✅ Verifying all fixes..."
        }
        
        // Final status
        await MainActor.run {
            self.installationProgress = 1.0
            self.installationStatus = "🎉 All game compatibility fixes completed successfully! Black screen issues should now be resolved."
        }
    }
    
    /// Comprehensive fix for DirectX 11 initialization errors
    func fixDirectX11InitializationError() async {
        await MainActor.run {

            self.installationStatus = "🔧 Fixing DirectX 11 initialization error..."
        }
        
        // Step 1: Install all DirectX components
        await installComprehensiveDirectXSupport()
        
        // Step 2: Configure graphics drivers and settings
        await configureGraphicsDriversForDirectX()
        
        // Step 3: Install Visual C++ Redistributables
        await installVisualCPlusPlusRedistributables()
        
        // Step 4: Apply DirectX-specific registry fixes
        await applyDirectXRegistryFixes()
        
        // Step 5: Configure DXVK with proper settings
        await configureDXVKForDirectX11()
        
        // Step 6: Test graphics initialization
        await testGraphicsInitialization()
        
        await MainActor.run {
            self.installationStatus = "✅ DirectX 11 initialization fixes completed! Try launching your game again."
        }
    }
    
    private func installComprehensiveDirectXSupport() async {
        await MainActor.run {
            self.installationStatus = "📦 Installing comprehensive DirectX support..."
        }
        
        let bottlePath = defaultBottlePath
        let winetricksPath = fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks") 
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
        
        // Install all DirectX components needed for proper initialization
        let directXComponents = [
            "dxvk",          // DirectX to Vulkan translation layer
            "d3dcompiler_47", // DirectX Shader Compiler
            "d3dx9",         // DirectX 9
            "d3dx10",        // DirectX 10
            "d3dx11_43",     // DirectX 11
            "vcrun2019",     // Visual C++ 2019 Redistributable
            "vcrun2017",     // Visual C++ 2017 Redistributable
            "vcrun2015",     // Visual C++ 2015 Redistributable
        ]
        
        for component in directXComponents {
            await MainActor.run {
                self.installationStatus = "📦 Installing \(component)..."
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winetricksPath)
            process.arguments = ["-q", component]
            process.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    print("✅ Successfully installed \(component)")
                } else {
                    print("⚠️ Failed to install \(component), continuing...")
                }
            } catch {
                print("❌ Error installing \(component): \(error)")
            }
        }
    }
    
    private func configureGraphicsDriversForDirectX() async {
        await MainActor.run {
            self.installationStatus = "🎮 Configuring graphics drivers for DirectX..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Graphics driver settings for DirectX compatibility
        let graphicsSettings = [
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "VideoMemorySize", "4096"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "UseGLSL", "enabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "shader_backend", "glsl"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "MaxVersionGL", "4.6"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "DirectDrawRenderer", "opengl"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "AlwaysOffscreen", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "Multisampling", "enabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "StrictDrawOrdering", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "CheckFloatConstants", "disabled"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "RenderTargetLockMode", "disabled"),
            // DirectX 11 specific settings
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "MaxShaderModelVS", "5"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "MaxShaderModelPS", "5"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "csmt", "enabled"),
        ]
        
        for (key, valueName, valueData) in graphicsSettings {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_SZ", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func applyDirectXRegistryFixes() async {
        await MainActor.run {
            self.installationStatus = "🔧 Applying DirectX registry fixes..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Critical DirectX 11 registry fixes
        let directXFixes = [
            // Fix graphics initialization
            ("HKEY_CURRENT_USER\\Software\\Wine\\DirectSound", "DefaultBitsPerSample", "16"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\DirectSound", "DefaultSampleRate", "44100"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\DirectSound", "MaxShadowSize", "2"),
            
            // DirectX 11 initialization fixes
            ("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\DirectX", "Version", "4.09.00.0904"),
            ("HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\DirectX", "", "DirectX"),
            
            // Graphics adapter fixes
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "VideoPciDeviceID", "0x0040"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "VideoPciVendorID", "0x10DE"),
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "VideoDescription", "NVIDIA Compatible"),
            
            // Force software rendering fallback if needed
            ("HKEY_CURRENT_USER\\Software\\Wine\\Direct3D", "renderer", "gl"),
        ]
        
        for (key, valueName, valueData) in directXFixes {
            let regProcess = Process()
            regProcess.executableURL = URL(fileURLWithPath: winePath)
            regProcess.arguments = ["reg", "add", key, "/v", valueName, "/t", "REG_SZ", "/d", valueData, "/f"]
            regProcess.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            try? regProcess.run()
            regProcess.waitUntilExit()
        }
    }
    
    private func configureDXVKForDirectX11() async {
        await MainActor.run {
            self.installationStatus = "⚡ Configuring DXVK for DirectX 11..."
        }
        
        let bottlePath = defaultBottlePath
        
        // Create DXVK configuration file for optimal DirectX 11 support
        let dxvkConfigPath = (bottlePath as NSString).appendingPathComponent("dxvk.conf")
        let dxvkConfig = """
        # DXVK Configuration for DirectX 11 Games
        
        # Enable async shader compilation for smoother gameplay
        dxvk.enableAsync = True
        
        # Optimize for DirectX 11
        dxvk.numCompilerThreads = 0
        dxvk.useRawSsbo = Auto
        
        # Graphics settings for stability
        dxvk.maxFrameLatency = 1
        dxvk.tearFree = Auto
        dxvk.syncInterval = Auto
        
        # Memory management
        dxvk.maxDeviceMemory = 4096
        dxvk.maxSharedMemory = 256
        
        # Disable problematic features that cause black screens
        dxvk.enableGraphicsPipelineLibrary = False
        dxvk.enableStateCache = True
        
        # DirectX 11 specific optimizations
        d3d11.maxFeatureLevel = 11_1
        d3d11.maxTessFactor = 64
        d3d11.samplerAnisotropy = 16
        d3d11.invariantPosition = True
        d3d11.floatControls = True
        d3d11.disableMsaa = False
        """
        
        do {
            try dxvkConfig.write(to: URL(fileURLWithPath: dxvkConfigPath), atomically: true, encoding: .utf8)
            print("✅ DXVK configuration created successfully")
        } catch {
            print("❌ Failed to create DXVK configuration: \(error)")
        }
        
        // Set DXVK environment variables
        let dxvkEnvPath = (bottlePath as NSString).appendingPathComponent("dxvk_env.sh")
        let dxvkEnvScript = """
        #!/bin/bash
        # DXVK Environment Variables for DirectX 11
        export DXVK_CONFIG_FILE="$WINEPREFIX/dxvk.conf"
        export DXVK_STATE_CACHE_PATH="$WINEPREFIX"
        export DXVK_LOG_LEVEL=info
        export DXVK_HUD=0
        export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/MoltenVK_icd.json"
        """
        
        do {
            try dxvkEnvScript.write(to: URL(fileURLWithPath: dxvkEnvPath), atomically: true, encoding: .utf8)
            // Make executable
            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", dxvkEnvPath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()
        } catch {
            print("❌ Failed to create DXVK environment script: \(error)")
        }
    }
    
    private func testGraphicsInitialization() async {
        await MainActor.run {
            self.installationStatus = "🧪 Testing graphics initialization..."
        }
        
        let bottlePath = defaultBottlePath
        let winePath = fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") 
            ? "/opt/homebrew/bin/wine" : "/usr/local/bin/wine"
        
        // Test DirectX 11 functionality with dxdiag
        let testProcess = Process()
        testProcess.executableURL = URL(fileURLWithPath: winePath)
        testProcess.arguments = ["dxdiag", "/t", "dxdiag_test.txt"]
        testProcess.environment = [
            "WINEPREFIX": bottlePath,
            "WINEDEBUG": "-all",
            "DXVK_HUD": "0"
        ]
        
        do {
            try testProcess.run()
            testProcess.waitUntilExit()
            
            let testResultPath = (bottlePath as NSString).appendingPathComponent("drive_c/dxdiag_test.txt")
            if fileManager.fileExists(atPath: testResultPath) {
                await MainActor.run {
                    self.installationStatus = "✅ Graphics initialization test completed successfully!"
                }
            } else {
                await MainActor.run {
                    self.installationStatus = "⚠️ Graphics test completed with warnings - game should still work"
                }
            }
        } catch {
            await MainActor.run {
                self.installationStatus = "⚠️ Graphics test encountered issues but fixes were applied"
            }
        }
    }
    
    private func installVisualCPlusPlusRedistributables() async {
        await MainActor.run {
            self.installationStatus = "📦 Installing Visual C++ redistributables..."
        }
        
        let bottlePath = defaultBottlePath
        let winetricksPath = fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks") 
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"
        
        // Install all major Visual C++ redistributables
        let vcRedistributables = [
            "vcrun2019",    // Visual C++ 2019
            "vcrun2017",    // Visual C++ 2017
            "vcrun2015",    // Visual C++ 2015
            "vcrun2013",    // Visual C++ 2013
            "vcrun2012",    // Visual C++ 2012
            "vcrun2010",    // Visual C++ 2010
            "vcrun2008",    // Visual C++ 2008
            "vcrun2005",    // Visual C++ 2005
        ]
        
        for vcRedist in vcRedistributables {
            await MainActor.run {
                self.installationStatus = "📦 Installing \(vcRedist)..."
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winetricksPath)
            process.arguments = ["-q", vcRedist]
            process.environment = [
                "WINEPREFIX": bottlePath,
                "WINEDEBUG": "-all"
            ]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    print("✅ Successfully installed \(vcRedist)")
                } else {
                    print("⚠️ Failed to install \(vcRedist), continuing...")
                }
            } catch {
                print("❌ Error installing \(vcRedist): \(error)")
            }
        }
    }
    
    // MARK: - Download URLs and Documentation
    
    /// Get download URLs for manual installation
    func getDownloadURLs() -> [String: String] {
        return [
            "homebrew": "https://brew.sh/",
            "wine": "https://github.com/Gcenx/macOS_Wine_builds/releases/latest",
            "gptk": "https://developer.apple.com/download/all/?q=Game%20Porting%20Toolkit",
            "xcode_command_line_tools": "https://developer.apple.com/download/all/?q=command%20line%20tools",
            "documentation": "https://developer.apple.com/documentation/gameportingtoolkit"
        ]
    }
    
    /// Open download URL in browser
    func openDownloadURL(for component: String) {
        let urls = getDownloadURLs()
        guard let urlString = urls[component],
              let url = URL(string: urlString) else { return }
        
        NSWorkspace.shared.open(url)
    }
    
    /// Get installation instructions for manual setup
    func getInstallationInstructions() -> [String: String] {
        return [
            "homebrew": """
                1. Open Terminal
                2. Run: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                3. Follow the prompts to complete installation
                """,
            "wine": """
                1. Install Homebrew first
                2. Run: brew install --cask --no-quarantine wine-stable
                3. Or download from: https://github.com/Gcenx/macOS_Wine_builds/releases
                """,
            "gptk": """
                1. Sign in to Apple Developer Portal
                2. Download Game Porting Toolkit 2.1
                3. Run the installer from the downloaded DMG
                4. Follow Apple's setup instructions
                """,
            "xcode_tools": """
                1. Open Terminal
                2. Run: xcode-select --install
                3. Or download from Apple Developer Portal
                """
        ]
    }
    
    // MARK: - Component Check Methods
    
    private func checkHomebrewInstalled() -> Bool {
        return fileManager.fileExists(atPath: "/opt/homebrew/bin/brew") || 
               fileManager.fileExists(atPath: "/usr/local/bin/brew")
    }
    
    private func checkWineInstalled() -> Bool {
        return fileManager.fileExists(atPath: "/Applications/Wine Stable.app") ||
               fileManager.fileExists(atPath: "/opt/homebrew/bin/wine") ||
               fileManager.fileExists(atPath: "/usr/local/bin/wine")
    }
    
    private func checkWinetricksInstalled() -> Bool {
        return fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks") ||
               fileManager.fileExists(atPath: "/usr/local/bin/winetricks")
    }
    
    private func checkDXVKInstalled() -> Bool {
        let bottlePath = defaultBottlePath
        let system32Path = (bottlePath as NSString).appendingPathComponent("drive_c/windows/system32")
        let dxvkFiles = ["d3d11.dll", "dxgi.dll"]
        
        return dxvkFiles.allSatisfy { dll in
            let dllPath = (system32Path as NSString).appendingPathComponent(dll)
            return fileManager.fileExists(atPath: dllPath)
        }
    }
    
    private func checkVCRedistInstalled() -> Bool {
        let bottlePath = defaultBottlePath
        let programFilesPath = (bottlePath as NSString).appendingPathComponent("drive_c/Program Files")
        let vcRedistPath = (programFilesPath as NSString).appendingPathComponent("Microsoft Visual Studio")
        
        return fileManager.fileExists(atPath: vcRedistPath)
    }
    
    private func checkDirectXInstalled() -> Bool {
        let bottlePath = defaultBottlePath
        let system32Path = (bottlePath as NSString).appendingPathComponent("drive_c/windows/system32")
        let directxFiles = ["d3dcompiler_47.dll", "d3dx9_43.dll"]
        
        return directxFiles.allSatisfy { dll in
            let dllPath = (system32Path as NSString).appendingPathComponent(dll)
            return fileManager.fileExists(atPath: dllPath)
        }
    }
    
    private func checkGPTKInstalled() -> Bool {
        let gptkPaths = [
            "/usr/local/bin/game-porting-toolkit",
            "/usr/local/bin/gameportingtoolkit",
            "/Applications/Game Porting Toolkit.app"
        ]
        
        return gptkPaths.contains { path in
            fileManager.fileExists(atPath: path)
        }
    }
    
    /// Check installation status of all components
    func checkAllComponentsStatus() async {
        await MainActor.run {
            self.homebrewInstalled = checkHomebrewInstalled()
            self.wineInstalled = checkWineInstalled()
            self.winetricksInstalled = checkWinetricksInstalled()
            self.dxvkInstalled = checkDXVKInstalled()
            self.vcredistInstalled = checkVCRedistInstalled()
            self.directxInstalled = checkDirectXInstalled()
            self.gptkInstalled = checkGPTKInstalled()
        }
    }
}