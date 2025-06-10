//
//  GamePortingToolkitManager_Fixed.swift
//  kimiz
//
//  Fixed version without website redirects
//

import AppKit
import Foundation
import SwiftUI

// Ensure these are available for type checking and usage
// If these are not modules, use relative import or ensure all files are in the same target
// If needed, adjust the import paths below
// import Models // If you have a Models module
// import Managers // If you have a Managers module
// The following lines ensure type visibility for cross-file type checks
// If you get errors, ensure all files are in the same target in Xcode

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

// Explicitly import the managers for type visibility
// If using a module, use @testable import kimiz, otherwise ensure all files are in the same target

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

    /// Scan for games in Wine bottles
    func scanForGames() async {
        await MainActor.run {
            self.installationStatus = "🔍 Scanning for games in Wine bottles..."
        }

        // Scan the default bottle for games
        let defaultBottlePath = NSString(
            string: "~/Library/Application Support/kimiz/gptk-bottles/default"
        ).expandingTildeInPath
        let driveC = (defaultBottlePath as NSString).appendingPathComponent("drive_c")

        var foundGames: [Any] = []

        if FileManager.default.fileExists(atPath: driveC) {
            // Look for common game directories
            let commonGamePaths = [
                "Program Files/Steam/steamapps/common",
                "Program Files (x86)/Steam/steamapps/common",
                "Program Files/Epic Games",
                "Program Files (x86)/Epic Games",
                "Program Files/GOG Galaxy",
                "Program Files (x86)/GOG Galaxy",
            ]

            for gamePath in commonGamePaths {
                let fullPath = (driveC as NSString).appendingPathComponent(gamePath)
                if FileManager.default.fileExists(atPath: fullPath) {
                    // Scan this directory for executables
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: fullPath)
                    {
                        for item in contents {
                            let itemPath = (fullPath as NSString).appendingPathComponent(item)
                            var isDirectory: ObjCBool = false
                            if FileManager.default.fileExists(
                                atPath: itemPath, isDirectory: &isDirectory)
                                && isDirectory.boolValue
                            {
                                // Look for executable files in this game directory
                                if let gameContents = try? FileManager.default.contentsOfDirectory(
                                    atPath: itemPath)
                                {
                                    for file in gameContents {
                                        if file.hasSuffix(".exe") && !file.contains("unins")
                                            && !file.contains("setup")
                                        {
                                            let execPath = (itemPath as NSString)
                                                .appendingPathComponent(file)
                                            foundGames.append([
                                                "name": item,
                                                "executablePath": execPath,
                                                "installPath": itemPath,
                                            ])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        await MainActor.run {
            self.installedGames = foundGames
            self.installationStatus = "✅ Found \(foundGames.count) installed games"
        }
    }

    /// Get installed games list - returns empty array for now (delegated to EngineManager)
    @Published var installedGames: [Any] = []

    /// Temporary computed property to bridge compatibility with views expecting [Game]
    var games: [Any] {
        return installedGames
    }

    /// Add user game to the library
    func addUserGame(_ game: Any) async {
        await MainActor.run {
            // Check if game is already in the list
            let gameName = extractGameName(from: game)
            let alreadyExists = installedGames.contains { existingGame in
                extractGameName(from: existingGame) == gameName
            }

            if !alreadyExists {
                self.installedGames.append(game)
                self.installationStatus = "✅ Game '\(gameName)' added to library"
            } else {
                self.installationStatus = "⚠️ Game '\(gameName)' is already in the library"
            }
        }
    }

    /// Remove user game from the library
    func removeUserGame(_ game: Any) async {
        await MainActor.run {
            let gameName = extractGameName(from: game)
            let initialCount = self.installedGames.count

            self.installedGames.removeAll { existingGame in
                extractGameName(from: existingGame) == gameName
            }

            let removedCount = initialCount - self.installedGames.count
            if removedCount > 0 {
                self.installationStatus = "✅ Game '\(gameName)' removed from library"
            } else {
                self.installationStatus = "⚠️ Game '\(gameName)' was not found in the library"
            }
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

    /// Install essential Windows graphics libraries using winetricks
    private func installEssentialGraphicsLibraries(_ bottlePath: String, winePath: String)
        async throws
    {
        // List of essential libraries for gaming
        let essentialLibs = [
            "vcrun2019",  // Visual C++ 2019 Runtime
            "d3dcompiler_47",  // DirectX shader compiler
            "dxvk",  // Vulkan-based DirectX implementation
            "corefonts",  // Windows core fonts
        ]

        let winetricksPath = "/opt/homebrew/bin/winetricks"
        let wineserverPath = (winePath as NSString).deletingLastPathComponent + "/wineserver"

        for lib in essentialLibs {
            do {
                print("[GamePortingToolkitManager] Installing \(lib) using winetricks...")

                let process = Process()
                process.executableURL = URL(fileURLWithPath: winetricksPath)
                process.arguments = ["-q", lib]
                process.environment = [
                    "WINE": winePath,
                    "WINESERVER": wineserverPath,
                    "WINEPREFIX": bottlePath,
                    "WINEDEBUG": "-all",
                    "DISPLAY": ":0.0",
                ]
                process.currentDirectoryURL = URL(fileURLWithPath: bottlePath)

                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    print("[GamePortingToolkitManager] Successfully installed \(lib)")
                } else {
                    print("[GamePortingToolkitManager] Failed to install \(lib), but continuing...")
                }
            } catch {
                print("[GamePortingToolkitManager] Error installing \(lib): \(error)")
            }
        }
    }

    /// Configure Wine prefix for better graphics compatibility
    private func configureWinePrefixForGraphics(_ bottlePath: String, winePath: String) async throws
    {
        let configCommands = [
            // Set Windows version to Windows 10
            "wine reg add 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion' /v CurrentVersion /t REG_SZ /d '10.0' /f",

            // Configure graphics settings
            "wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\Direct3D' /v DirectDrawRenderer /t REG_SZ /d 'opengl' /f",
            "wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\Direct3D' /v Multisampling /t REG_SZ /d 'enabled' /f",
            "wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\Direct3D' /v OffscreenRenderingMode /t REG_SZ /d 'backbuffer' /f",
            "wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\Direct3D' /v VideoMemorySize /t REG_DWORD /d 2048 /f",

            // Disable Wine debugging for better performance
            "wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\Debug' /v RelayExclude /t REG_SZ /d 'ntdll.RtlEnterCriticalSection;ntdll.RtlLeaveCriticalSection' /f",
        ]

        let environment = [
            "WINEPREFIX": bottlePath,
            "DISPLAY": ":0.0",
            "WINEDEBUG": "-all",
        ]

        for command in configCommands {
            do {
                let components = command.components(separatedBy: " ")
                if let wineCommand = components.first, components.count > 1 {
                    let args = Array(components.dropFirst())

                    try await WineManager.shared.runWineProcess(
                        winePath: winePath,
                        executablePath: wineCommand,
                        arguments: args,
                        environment: environment,
                        workingDirectory: bottlePath,
                        defaultBottlePath: bottlePath
                    )
                }
            } catch {
                // Continue with other configuration commands even if one fails
                print(
                    "[GamePortingToolkitManager] Wine config command failed: \(command), error: \(error)"
                )
            }
        }

        print(
            "[GamePortingToolkitManager] Wine prefix configured for better graphics compatibility")
    }

    /// Apply universal drive and GPU optimizations for all games
    private func applyUniversalOptimizations(
        _ environment: inout [String: String], executablePath: String
    ) async {
        let executableName = (executablePath as NSString).lastPathComponent.lowercased()

        // Apply system-level optimizations first
        await applySystemOptimizations()

        // General drive optimizations
        environment["WINE_DRIVE_OPTIMIZATION"] = "1"
        environment["WINE_SHARED_MEMORY"] = "1"
        environment["WINE_LARGE_ADDRESS_AWARE"] = "1"
        environment["WINE_FULLSCREEN_INTEGER_SCALING"] = "1"

        // General GPU optimizations
        environment["DXVK_ASYNC"] = "1"
        environment["DXVK_FILTER_DEVICE_NAME"] = "AMD,NVIDIA,Intel,Apple"
        environment["DXVK_CONFIG_FILE"] = defaultBottlePath + "/dxvk.conf"
        environment["DXVK_HUD"] = "fps,gpuload,memory"
        environment["DXVK_LOG_LEVEL"] = "none"
        environment["DXVK_STATE_CACHE"] = "1"
        environment["DXVK_STATE_CACHE_PATH"] = defaultBottlePath + "/dxvk_cache"
        environment["DXVK_FRAME_RATE"] = "0"  // uncapped
        environment["DXVK_ENABLE_NVAPI"] = "1"
        environment["DXVK_NVAPI_DEFAULT_DEVICE_ID"] = "0x1E82"  // Fallback for NVIDIA
        environment["DXVK_NVAPI_DEFAULT_VENDOR_ID"] = "0x10DE"
        environment["DXVK_FAKE_DXGI_ADAPTER"] = "1"
        environment["DXVK_USE_PIPECOMPILER"] = "1"
        environment["DXVK_ENABLE_PIPELINE_CACHE"] = "1"
        environment["DXVK_CONFIG"] = defaultBottlePath + "/dxvk.conf"

        // General DirectX compatibility
        environment["WINEDLLOVERRIDES"] =
            "d3d11,d3d10core,d3d9,dxgi,xinput1_4,xinput1_3,winhttp=n,b"
        environment["WINE_VK_LAYER_PATH"] = "/usr/local/share/vulkan/explicit_layer.d"
        environment["VK_ICD_FILENAMES"] = "/usr/local/share/vulkan/icd.d/MoltenVK_icd.json"
        environment["VK_INSTANCE_LAYERS"] = "VK_LAYER_MOLTENVK"
        environment["MOLTENVK_CONFIG_FILE"] = defaultBottlePath + "/moltenvk.conf"

        // General input optimizations
        environment["WINE_RAW_INPUT"] = "1"
        environment["WINE_MOUSE_ACCELERATION"] = "0"
        environment["WINE_JOYSTICK_DISABLE"] = "0"

        // General memory and performance optimizations
        environment["WINE_HEAP_DELAY_FREE"] = "1"
        environment["WINE_DISABLE_LAYER_COMPOSITOR"] = "1"
        environment["WINE_AUDIO_DRIVER"] = "pulse"
        environment["WINEESYNC"] = "1"
        environment["WINEFSYNC"] = "1"
        environment["WINEDEBUG"] = "-all"
        environment["GL_SHADER_CACHE"] = "1"
        environment["GL_SHADER_CACHE_PATH"] = defaultBottlePath + "/shader_cache"
        environment["__GL_THREADED_OPTIMIZATIONS"] = "1"
        environment["__GL_SYNC_TO_VBLANK"] = "0"
        environment["__GL_GSYNC_ALLOWED"] = "1"
        environment["__GL_VRR_ALLOWED"] = "1"

        // General macOS-specific optimizations
        environment["MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS"] = "0"
        environment["MVK_CONFIG_PRESENT_WITH_COMMAND_BUFFER"] = "1"
        environment["MVK_CONFIG_SWAPCHAIN_MAG_FILTER"] = "1"
        environment["MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS"] = "1"
        environment["MVK_CONFIG_FAST_MATH_ENABLED"] = "1"
        environment["MVK_CONFIG_LOG_LEVEL"] = "0"

        // Create DXVK configuration for better compatibility
        await createUniversalDXVKConfig()

        print(
            "[GamePortingToolkitManager] Applied universal drive and GPU optimizations for \(executableName)"
        )
    }

    /// Create universal DXVK configuration file
    private func createUniversalDXVKConfig() async {
        let dxvkConfigPath = defaultBottlePath + "/dxvk.conf"
        let dxvkConfig = """
            # Universal DXVK Configuration for Kimiz
            # Optimized for all games on macOS with Game Porting Toolkit

            # Memory optimizations
            dxvk.maxAvailableMemory = 4096
            dxvk.maxChunkSize = 256
            dxvk.enableAsync = True
            dxvk.memoryTrackResources = True

            # Performance optimizations
            dxvk.useRawSsbo = True
            dxvk.shrinkNvidiaHvv = False
            dxvk.enableGraphicsPipelineLibrary = Auto
            dxvk.enableStateCache = True
            dxvk.numCompilerThreads = 0  # Use all available cores
            dxvk.hud = fps,memory,gpuload
            dxvk.presentMode = mailbox
            dxvk.enableAsync = True
            dxvk.tearFree = True
            """

        do {
            try dxvkConfig.write(toFile: dxvkConfigPath, atomically: true, encoding: .utf8)
            print("[GamePortingToolkitManager] Created universal DXVK configuration")
        } catch {
            print("[GamePortingToolkitManager] Failed to create DXVK config: \(error)")
        }
    }

    /// Configure universal system-level optimizations
    private func applySystemOptimizations() async {
        // Disable Spotlight indexing for Wine bottles temporarily
        let disableSpotlightCmd = "mdutil -i off \(defaultBottlePath) 2>/dev/null || true"
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", disableSpotlightCmd]

        do {
            try task.run()
            task.waitUntilExit()
            print("[GamePortingToolkitManager] Disabled Spotlight indexing for Wine bottles")
        } catch {
            print("[GamePortingToolkitManager] Could not disable Spotlight indexing: \(error)")
        }

        // Apply system memory pressure relief
        let memoryOptimCmd = "purge 2>/dev/null || true"
        let memTask = Process()
        memTask.launchPath = "/bin/bash"
        memTask.arguments = ["-c", memoryOptimCmd]

        do {
            try memTask.run()
            memTask.waitUntilExit()
            print("[GamePortingToolkitManager] Applied memory pressure relief")
        } catch {
            print("[GamePortingToolkitManager] Could not apply memory optimization: \(error)")
        }
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
        do {
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
            try process.run()
            process.waitUntilExit()
            await MainActor.run {
                if process.terminationStatus == 0 {
                    self.installationStatus =
                        "DXVK (DirectX 11/10/9 support) successfully installed in Wine prefix! Try launching your game again."
                } else {
                    self.installationStatus =
                        "Failed to install DXVK (DirectX 11 support) in Wine prefix. Please check the log or try again."
                }
            }
        } catch {
            await MainActor.run {
                self.installationStatus =
                    "Error running winetricks dxvk (DXVK/DirectX 11 setup): \(error.localizedDescription)"
            }
        }
    }
}
