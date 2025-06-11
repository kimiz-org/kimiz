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

    /// Launch a game using the appropriate manager
    func launchGame(_ game: Any) async throws {
        // Use type checking to delegate to the correct manager
        if let steamGame = game as? SteamManager.SteamGame {
            try await steamManager.launchGame(steamGame)
        } else if let epicGame = game as? EpicGame {
            try await epicGamesManager.launchGame(epicGame)
        } else if let genericGame = game as? Game {
            // Attempt to launch as Steam game if path matches Steam install
            let steamExePath = genericGame.executablePath
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
            let output = String(data: data, encoding: .utf8) ?? ""

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
                        "❌ Failed to install DXVK (DirectX 11 support) in Wine prefix. Output: \n\(output)"
                }
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
}
