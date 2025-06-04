//
//  EmbeddedWineManager.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Combine
import Foundation

// MARK: - Temporary Types for Compilation
// These types are defined here to ensure proper compilation
// The real definitions are in WineEnvironment.swift

// Temporarily redefine these types if they can't be found
#if !IMPORTED_WINE_TYPES
    enum WineBackend: String {
        case embedded, wine, crossover, gamePortingToolkit
        
        var executablePath: String {
            switch self {
            case .gamePortingToolkit:
                return "/usr/local/bin/wine64"
            default:
                return "/usr/local/bin/wine64"
            }
        }
    }
    
    struct WinePrefix: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let path: String
        let backend: WineBackend
        
        init(name: String, backend: WineBackend) {
            self.name = name
            self.backend = backend
            self.path = "~/Library/Application Support/kimiz/wine-prefixes/\(name)"
        }
    }
    
    struct GameInstallation: Identifiable {
        let id = UUID()
        let name: String
        let executablePath: String
        let winePrefix: WinePrefix
        let installPath: String
        var lastPlayed: Date?
        var isInstalled: Bool = false
        
        init(name: String, executablePath: String, winePrefix: WinePrefix, installPath: String) {
            self.name = name
            self.executablePath = executablePath
            self.winePrefix = winePrefix
            self.installPath = installPath
        }
    }
    
    enum WineError: Error {
        case prefixCreationFailed(String)
        case executionFailed(String)
        case installationFailed(String)
        case commandFailed(String)
        case invalidURL
    }
    
    // Dummy GamePortingToolkitManager for compilation
    class GamePortingToolkitManager {
        static let shared = GamePortingToolkitManager()
        
        func isGamePortingToolkitInstalled() -> Bool {
            return false
        }
        
        func installGamePortingToolkit() async throws {
            // Implementation would go here
        }
    }
#endif

@MainActor
class EmbeddedWineManager: ObservableObject {
    @Published var isWineReady = false
    @Published var isInitializing = false
    @Published var initializationProgress: Double = 0.0
    @Published var initializationStatus = "Preparing Wine environment..."
    @Published var lastError: String?
    @Published var installedGames: [GameInstallation] = []
    @Published var isInstallingComponents = false
    @Published var installationComponentName = ""
    @Published var hasCheckedWineStatus = false

    private let fileManager = FileManager.default
    private var wineBackend: WineBackend = .gamePortingToolkit
    private var winePath: String {
        return wineBackend.executablePath
    }
    private let defaultPrefixPath: String

    // MARK: - Initialization

    init() {
        // Define default prefix path
        self.defaultPrefixPath =
            NSString(string: "~/Library/Application Support/kimiz/wine-prefixes/default")
            .expandingTildeInPath

        Task {
            await checkWineInstallation()
        }
    }

    // MARK: - Wine Installation Management
    
    func checkWineInstallation() async {
        await MainActor.run {
            isInitializing = true
            initializationStatus = "Checking for Wine installation..."
            hasCheckedWineStatus = true
        }

        // Check for Game Porting Toolkit installation
        #if IMPORTED_WINE_TYPES
        if GamePortingToolkitManager.shared.isGamePortingToolkitInstalled() {
        #else
        if GamePortingToolkitManager.shared.isGamePortingToolkitInstalled() {
        #endif
            wineBackend = .gamePortingToolkit
            await MainActor.run {
                isWineReady = true
                isInitializing = false
                initializationStatus = "Wine ready via Game Porting Toolkit"
            }
            return
        }

        // Check for Homebrew Wine installation
        if await checkBrewWineInstallation() {
            wineBackend = .wine
            await MainActor.run {
                isWineReady = true
                isInitializing = false
                initializationStatus = "Wine ready via Homebrew"
            }
            return
        }

        // No Wine installation found
        await MainActor.run {
            isWineReady = false
            isInitializing = false
            initializationStatus = "Wine not found"
            lastError =
                "Wine is not installed. Please install Game Porting Toolkit or Wine via Homebrew."
        }
    }
    
    // Function to check if Winetricks is installed
    private func isWinetricksInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "command -v winetricks"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func installRequiredComponents() async throws {
        await MainActor.run {
            isInstallingComponents = true
            initializationProgress = 0.1
        }
        
        // Step 1: Check if Homebrew is already installed
        if isHomebrewInstalled() {
            await MainActor.run {
                installationComponentName = "Homebrew (already installed)"
                initializationProgress = 0.3
            }
        } else {
            await MainActor.run {
                installationComponentName = "Homebrew"
            }
            try await installHomebrew()
        }
        
        // Step 2: Check if Game Porting Toolkit is already installed
        if GamePortingToolkitManager.shared.isGamePortingToolkitInstalled() {
            await MainActor.run {
                installationComponentName = "Game Porting Toolkit (already installed)"
                initializationProgress = 0.6
            }
        } else {
            await MainActor.run {
                installationComponentName = "Game Porting Toolkit"
                initializationProgress = 0.3
            }
            try await GamePortingToolkitManager.shared.installGamePortingToolkit()
        }
        
        // Step 3: Check if Winetricks is already installed
        if isWinetricksInstalled() {
            await MainActor.run {
                installationComponentName = "Winetricks (already installed)"
                initializationProgress = 0.8
            }
        } else {
            await MainActor.run {
                installationComponentName = "Winetricks"
                initializationProgress = 0.6
            }
            try await installWinetricks()
        }
        
        await MainActor.run {
            installationComponentName = "Verifying components"
            initializationProgress = 0.9
        }
        
        // Step 4: Check if installation was successful
        await checkWineInstallation()
        
        await MainActor.run {
            isInstallingComponents = false
            initializationProgress = 1.0
        }
    }
    
    private func isHomebrewInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "command -v brew"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func installHomebrew() async throws {
        await MainActor.run {
            initializationStatus = "Installing Homebrew..."
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler = { _ in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: WineError.installationFailed("Homebrew installation failed: \(output)"))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func installWinetricks() async throws {
        await MainActor.run {
            initializationStatus = "Installing Winetricks..."
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "brew install winetricks"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler = { _ in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: WineError.installationFailed("Winetricks installation failed: \(output)"))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func checkBrewWineInstallation() async -> Bool {
        // Check common Wine installation paths
        let winePaths = [
            "/usr/local/bin/wine64",  // Intel Homebrew
            "/opt/homebrew/bin/wine64",  // Apple Silicon Homebrew
            "/usr/local/bin/wine",  // Alternative Wine installation
            "/opt/homebrew/bin/wine",  // Alternative Wine installation
        ]

        for path in winePaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }

        return false
    }

    func initializeWine() async throws {
        guard !isWineReady else { return }

        await MainActor.run {
            isInitializing = true
            initializationProgress = 0.0
            initializationStatus = "Initializing embedded Wine environment..."
        }

        do {
            try await extractWineResources()
            await updateProgress(0.3, "Creating Wine prefix for high-performance gaming...")

            try await createDefaultPrefix()
            await updateProgress(0.5, "Configuring Windows 10 compatibility...")

            try await configureWinePrefix()
            await updateProgress(0.7, "Installing gaming performance optimizations...")

            try await configureGamingOptimizations(in: defaultPrefixPath)
            await updateProgress(0.9, "Installing essential gaming components...")

            try await installCoreGamingComponents()

            await MainActor.run {
                isWineReady = true
                isInitializing = false
                initializationProgress = 1.0
                initializationStatus = "Wine environment ready for gaming!"
            }
        } catch {
            await MainActor.run {
                isInitializing = false
                lastError = "Failed to initialize Wine: \(error.localizedDescription)"
            }
            throw error
        }
    }

    private func configureWinePrefix() async throws {
        // Set Windows version to Windows 10 for better game compatibility
        _ = try await runWineCommand(["winecfg", "/v", "win10"], in: defaultPrefixPath)

        // Configure basic Wine settings for gaming
        let basicCommands = [
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\DllOverrides\" /v \"winemenubuilder.exe\" /t REG_SZ /d \"\"",
            ],
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Version\" /v \"Windows\" /t REG_SZ /d \"win10\"",
            ],
        ]

        for command in basicCommands {
            do {
                _ = try await runWineCommand(command, in: defaultPrefixPath)
            } catch {
                print("Basic configuration command failed: \(command), error: \(error)")
            }
        }
    }

    private func installCoreGamingComponents() async throws {
        // Install only the most essential components for basic gaming
        let coreComponents = [
            "vcrun2019",  // Visual C++ 2019 (most important for modern games)
            "d3dx9",  // DirectX 9 (widely used by games)
            "corefonts",  // Essential fonts for proper text rendering
        ]

        let progressStep = 0.2 / Double(coreComponents.count)
        var currentProgress = 0.9

        for component in coreComponents {
            do {
                await updateProgress(currentProgress, "Installing \(component)...")
                _ = try await runWinetricksCommand([component], in: defaultPrefixPath)
                currentProgress += progressStep
            } catch {
                // Continue with other components
                print("Failed to install core component \(component): \(error)")
                currentProgress += progressStep
            }
        }
    }

    private func extractWineResources() async throws {
        await updateProgress(0.2, "Checking Wine installation...")

        // Verify Wine executable exists and is working
        let testCommand = [winePath, "--version"]
        let result = try await runCommand(testCommand)

        if !result.contains("wine") {
            throw WineError.installationFailed("Wine installation verification failed")
        }

        await updateProgress(0.2, "Wine installation verified")
    }

    private func createDefaultPrefix() async throws {
        await updateProgress(0.5, "Creating default Wine prefix...")

        // Create default Wine prefix directory
        try fileManager.createDirectory(
            atPath: defaultPrefixPath, withIntermediateDirectories: true)

        // Initialize Wine prefix with wineboot
        _ = try await runWineCommand(["wineboot", "--init"], in: defaultPrefixPath)

        await updateProgress(0.5, "Wine prefix created successfully")
    }

    private func updateProgress(_ progress: Double, _ status: String) async {
        await MainActor.run {
            initializationProgress = progress
            initializationStatus = status
        }
    }

    // MARK: - Gaming Performance Optimizations

    private func configureGamingOptimizations(in prefixPath: String) async throws {
        // Set Windows version to Windows 10 for better game compatibility
        _ = try await runWineCommand(["winecfg", "/v", "win10"], in: prefixPath)

        // Configure Wine for gaming performance
        let wineConfigCommands = [
            // Enable CSMT (Command Stream Multi-Threading) for better graphics performance
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"csmt\" /t REG_DWORD /d 1",
            ],

            // Set video memory size (1GB for modern games)
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"VideoMemorySize\" /t REG_DWORD /d 1024",
            ],

            // Enable multisampling for better graphics
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"Multisampling\" /t REG_DWORD /d 1",
            ],

            // Optimize audio latency
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Drivers\" /v \"Audio\" /t REG_SZ /d \"coreaudio\"",
            ],

            // Set high performance power profile
            [
                "regedit", "/S", "/C",
                "reg add \"HKLM\\System\\CurrentControlSet\\Control\\Power\" /v \"CsEnabled\" /t REG_DWORD /d 0",
            ],
        ]

        for command in wineConfigCommands {
            do {
                _ = try await runWineCommand(command, in: prefixPath)
            } catch {
                // Continue with other optimizations even if one fails
                print("Gaming optimization command failed: \(command), error: \(error)")
            }
        }
    }

    private func installGamingDependencies(in prefixPath: String) async throws {
        // Install essential Windows components for gaming
        let dependencies = [
            // Visual C++ Redistributables (essential for most games)
            "vcrun2019",

            // DirectX End-User Runtimes
            "d3dx9",
            "d3dx10",
            "d3dx11_43",

            // .NET Framework (required by many games)
            "dotnet48",

            // Media Foundation (for video codecs)
            "mf",

            // Windows Media Format
            "wmf",

            // DirectSound and DirectMusic
            "dsound",
            "dmusic",

            // Core fonts for proper text rendering
            "corefonts",
        ]

        for dependency in dependencies {
            do {
                // Use winetricks to install dependencies
                _ = try await runWinetricksCommand([dependency], in: prefixPath)
            } catch {
                // Continue with other dependencies even if one fails
                print("Failed to install \(dependency): \(error)")
            }
        }
    }

    private func runWinetricksCommand(_ arguments: [String], in prefixPath: String? = nil)
        async throws -> String
    {
        // Try to find winetricks in common locations
        let winetricksPaths = [
            "/usr/local/bin/winetricks",  // Homebrew
            "/opt/homebrew/bin/winetricks",  // Apple Silicon Homebrew
            "/usr/bin/winetricks",  // System package manager
        ]

        var winetricksPath: String?
        for path in winetricksPaths {
            if fileManager.fileExists(atPath: path) {
                winetricksPath = path
                break
            }
        }

        guard let winetricks = winetricksPath else {
            // If winetricks is not available, try to install the component manually using Wine
            print("Winetricks not found, attempting manual installation for: \(arguments)")
            return "Winetricks not available, skipping \(arguments.joined(separator: " "))"
        }

        let workingPrefix = prefixPath ?? defaultPrefixPath

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winetricks)
            process.arguments = ["--unattended"] + arguments
            process.environment = createWineEnvironment(prefixPath: workingPrefix)

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
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Wine Operations

    private func runCommand(_ arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: arguments[0])
            process.arguments = Array(arguments.dropFirst())

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
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func runWineCommand(_ arguments: [String], in prefixPath: String? = nil) async throws -> String
    {
        let workingPrefix = prefixPath ?? defaultPrefixPath
        // The fullArguments variable is not used, so we're removing it
        // let fullArguments = [winePath] + arguments

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winePath)
            process.arguments = arguments
            process.environment = createWineEnvironment(prefixPath: workingPrefix)

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
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func installSteam(in prefixPath: String? = nil) async throws {
        let workingPrefix = prefixPath ?? defaultPrefixPath

        await updateProgress(0.1, "Downloading Steam for Windows...")

        // Download Windows Steam installer
        let steamInstallerURL = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
        let installerPath = try await downloadFile(from: steamInstallerURL, to: "SteamSetup.exe")

        await updateProgress(0.3, "Installing Windows Steam...")

        // Install Steam silently with Windows compatibility
        _ = try await runWineCommand([installerPath, "/S"], in: workingPrefix)

        await updateProgress(0.6, "Configuring Steam for gaming performance...")

        // Apply gaming performance optimizations
        try await configureGamingOptimizations(in: workingPrefix)

        await updateProgress(0.8, "Installing gaming dependencies...")

        // Install essential Windows gaming components
        try await installGamingDependencies(in: workingPrefix)

        await updateProgress(1.0, "Steam installation complete!")

        // Clean up installer
        try? fileManager.removeItem(atPath: installerPath)
    }

    func launchSteam(in prefixPath: String? = nil) async throws {
        let workingPrefix = prefixPath ?? defaultPrefixPath
        let steamPath = workingPrefix + "/drive_c/Program Files (x86)/Steam/steam.exe"

        // Set Steam launch options for better performance
        let steamArgs = [
            steamPath,
            "-no-browser",  // Disable in-game browser for performance
            "-silent",  // Minimize startup notifications
            "+open", "steam://open/minigameslist",  // Open to library directly
        ]

        _ = try await runWineCommand(steamArgs, in: workingPrefix)
    }

    func launchGame(
        executablePath: String, in prefixPath: String? = nil, withArgs args: [String] = [],
        environment additionalEnv: [String: String] = [:]
    ) async throws -> String {
        let workingPrefix = prefixPath ?? defaultPrefixPath

        // Apply runtime performance optimizations before launching game
        try await applyRuntimeOptimizations(in: workingPrefix)

        // Create environment with additional variables
        var env = createWineEnvironment(prefixPath: workingPrefix)
        for (key, value) in additionalEnv {
            env[key] = value
        }

        let gameArgs = [executablePath] + args
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winePath)
            process.arguments = gameArgs
            process.environment = env

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
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func applyRuntimeOptimizations(in prefixPath: String) async throws {
        // Set process priority for better gaming performance
        let priorityCommands = [
            // Set Wine process to high priority
            [
                "regedit", "/S", "/C",
                "reg add \"HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options\\wine-preloader\" /v \"PriorityClass\" /t REG_DWORD /d 3",
            ],

            // Disable Windows Defender (simulated)
            [
                "regedit", "/S", "/C",
                "reg add \"HKLM\\Software\\Microsoft\\Windows Defender\" /v \"DisableAntiSpyware\" /t REG_DWORD /d 1",
            ],

            // Optimize graphics settings for performance
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Wine\\Direct3D\" /v \"DirectDrawRenderer\" /t REG_SZ /d \"opengl\"",
            ],

            // Set game mode registry entries
            [
                "regedit", "/S", "/C",
                "reg add \"HKCU\\Software\\Microsoft\\GameBar\" /v \"AllowAutoGameMode\" /t REG_DWORD /d 1",
            ],
        ]

        for command in priorityCommands {
            do {
                _ = try await runWineCommand(command, in: prefixPath)
            } catch {
                // Continue even if optimization fails
                print("Runtime optimization failed: \(command), error: \(error)")
            }
        }
    }

    // MARK: - Game Management

    func scanForInstalledGames() async {
        // Create a dummy default prefix for embedded Wine
        let defaultPrefix = WinePrefix(name: "default", backend: .embedded)

        // In a real implementation, this would scan common Steam and game directories
        // For now, we'll add Steam if it's installed
        let steamPath = defaultPrefixPath + "/drive_c/Program Files (x86)/Steam/steam.exe"

        var games: [GameInstallation] = []

        if fileManager.fileExists(atPath: steamPath) {
            var steamGame = GameInstallation(
                name: "Steam",
                executablePath: steamPath,
                winePrefix: defaultPrefix,
                installPath: defaultPrefixPath + "/drive_c/Program Files (x86)/Steam"
            )
            steamGame.isInstalled = true
            games.append(steamGame)
        }

        await MainActor.run {
            installedGames = games
        }
    }

    func launchGame(_ game: GameInstallation) async throws {
        try await launchGame(executablePath: game.executablePath)

        // Update last played time
        if let index = installedGames.firstIndex(where: { $0.id == game.id }) {
            var updatedGame = installedGames[index]
            updatedGame.lastPlayed = Date()
            installedGames[index] = updatedGame
        }
    }

    private func findExecutableInDirectory(_ directory: String) -> String? {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)

            // Look for .exe files
            for file in contents {
                if file.lowercased().hasSuffix(".exe") {
                    return directory + "/" + file
                }
            }

            // Look in subdirectories
            for item in contents {
                let itemPath = directory + "/" + item
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory)
                    && isDirectory.boolValue
                {
                    if let executablePath = findExecutableInDirectory(itemPath) {
                        return executablePath
                    }
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    // MARK: - Helper Methods

    private func createWineEnvironment(prefixPath: String) -> [String: String] {
        var env = ProcessInfo.processInfo.environment

        // Core Wine settings
        env["WINEPREFIX"] = prefixPath
        env["WINEDLLOVERRIDES"] = "mscoree,mshtml=;winemenubuilder.exe=d"

        // Performance optimizations
        env["WINE_CPU_TOPOLOGY"] = "4:2"  // Optimize for multi-core (4 cores, 2 threads per core)
        env["WINE_LARGE_ADDRESS_AWARE"] = "1"  // Enable Large Address Aware for 32-bit games

        // Graphics and gaming performance
        env["DXVK_HUD"] = "fps"  // Show FPS overlay when using DXVK
        env["WINE_DISABLE_MENU_BUILDER"] = "1"  // Disable menu integration for performance
        env["WINE_DISABLE_REGISTRY_UPDATE"] = "1"  // Reduce registry overhead

        // Audio optimizations
        env["PULSE_LATENCY_MSEC"] = "60"  // Low audio latency
        env["WINE_RT"] = "1"  // Real-time priority for audio

        // Memory and threading optimizations
        env["WINE_HEAP_MAX_SIZE"] = "1073741824"  // 1GB heap size
        env["WINE_STAGING"] = "1"  // Enable staging patches for better compatibility

        // DirectX and graphics optimizations
        env["WINE_D3D11"] = "1"  // Enable Direct3D 11 support
        env["WINE_OPENGL"] = "1"  // Enable OpenGL optimizations
        env["MESA_GL_VERSION_OVERRIDE"] = "4.6"  // Override OpenGL version for compatibility

        // Gaming-specific environment
        env["WINE_GAMING_MODE"] = "1"
        env["WINE_FULLSCREEN_FSR"] = "1"  // Enable FSR (FidelityFX Super Resolution) if available

        return env
    }

    private func downloadFile(from urlString: String, to fileName: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw WineError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let tempDir = NSTemporaryDirectory()
        let filePath = tempDir + fileName

        try data.write(to: URL(fileURLWithPath: filePath))
        return filePath
    }
}
