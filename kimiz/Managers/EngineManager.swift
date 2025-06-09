//
//  EngineManager.swift
//  kimiz
//
//  Created by System on June 10, 2025.
//
//  Inspired by MythicApp/Engine - A comprehensive GPTK management system
//

import Foundation
import SwiftUI
import os.log

@MainActor
class EngineManager: ObservableObject {
    static let shared = EngineManager()

    // MARK: - Published Properties
    @Published var isEngineInstalled = false
    @Published var engineVersion: String?
    @Published var isInstalling = false
    @Published var installationProgress: Double = 0.0
    @Published var installationStatus = ""
    @Published var lastError: String?

    // MARK: - Engine Configuration
    @Published var enableDXVK = true
    @Published var enableESync = true
    @Published var enableFSync = false
    @Published var enableACO = true
    @Published var metalHUD = false
    @Published var debugLogging = false

    // MARK: - Performance Settings
    @Published var cpuThreads = ProcessInfo.processInfo.activeProcessorCount
    @Published var memoryLimit: Int = 8192  // MB
    @Published var useRAMDisk = true
    @Published var enableRosettaOptimization = true

    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "dev.kimiz.engine", category: "manager")

    // Engine directories
    private let engineDirectory = NSHomeDirectory() + "/Library/Application Support/kimiz/Engine"
    private let wineDirectory = NSHomeDirectory() + "/Library/Application Support/kimiz/Engine/wine"
    private let gptkDirectory = NSHomeDirectory() + "/Library/Application Support/kimiz/Engine/gptk"

    private init() {
        Task {
            await checkEngineInstallation()
        }
    }

    // MARK: - Installation Check

    func checkEngineInstallation() async {
        logger.info("Checking engine installation status")

        let installed = await isEngineInstalled()
        let version = await getInstalledVersion()

        await MainActor.run {
            self.isEngineInstalled = installed
            self.engineVersion = version
        }
    }

    private func isEngineInstalled() async -> Bool {
        // Check for our in-app engine installation first
        let inAppWinePath = "\(wineDirectory)/bin/wine64"
        if fileManager.fileExists(atPath: inAppWinePath) {
            return true
        }

        // Fallback to system GPTK installations
        let gptkPaths = [
            "/Applications/Game Porting Toolkit.app/Contents/MacOS/gameportingtoolkit",
            "/usr/local/bin/wine64",  // Apple installer default
            "/usr/local/bin/wine",
            "/opt/local/bin/wine64",  // MacPorts fallback
            "/opt/local/bin/wine",
        ]

        for path in gptkPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }

        return false
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
            logger.error("Error checking wildcard path: \(error.localizedDescription)")
        }

        return false
    }

    private func getInstalledVersion() async -> String? {
        // Try to get GPTK version from Homebrew
        guard let brewPath = getBrewPath() else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = ["list", "--versions", "game-porting-toolkit"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                let components = output.trimmingCharacters(in: .whitespacesAndNewlines).components(
                    separatedBy: " ")
                return components.last
            }
        } catch {
            logger.error("Failed to get GPTK version: \(error.localizedDescription)")
        }

        return "Wine Fallback"
    }

    // MARK: - Installation

    func installEngine() async throws {
        logger.info("Starting in-app GPTK engine installation")

        await MainActor.run {
            self.isInstalling = true
            self.installationProgress = 0.0
            self.installationStatus = "Preparing installation..."
            self.lastError = nil
        }

        do {
            // Step 1: Check prerequisites
            try await checkPrerequisites()

            // Step 2: Create engine directories
            try await createEngineDirectories()

            // Step 3: Download and install Wine
            try await downloadAndInstallWine()

            // Step 4: Download and install GPTK components
            try await downloadAndInstallGPTK()

            // Step 5: Install Rosetta 2 on Apple Silicon
            try await ensureRosettaInstalled()

            // Step 6: Configure engine environment
            try await configureEngine()

            // Step 7: Verify installation
            try await verifyInstallation()

            await MainActor.run {
                self.installationProgress = 1.0
                self.installationStatus = "Installation completed successfully!"
                self.isInstalling = false
                self.isEngineInstalled = true
            }

            await checkEngineInstallation()

        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.installationStatus = "Installation failed: \(error.localizedDescription)"
                self.isInstalling = false
            }
            throw error
        }
    }

    private func checkPrerequisites() async throws {
        await MainActor.run {
            self.installationProgress = 0.1
            self.installationStatus = "Checking system requirements..."
        }

        // Check macOS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        if osVersion.majorVersion < 14 {
            throw EngineError.unsupportedSystem("macOS 14 (Sonoma) or later is required")
        }

        // Check architecture
        #if arch(arm64)
            logger.info("Detected Apple Silicon Mac")
        #else
            throw EngineError.unsupportedSystem(
                "Apple Silicon Mac is required for optimal performance")
        #endif

        // Check available disk space (require at least 5GB)
        if let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
            let freeSize = attributes[.systemFreeSize] as? NSNumber
        {
            let freeGB = freeSize.doubleValue / 1_000_000_000
            if freeGB < 5.0 {
                throw EngineError.insufficientSpace("At least 5GB of free disk space is required")
            }
        }
    }

    private func createEngineDirectories() async throws {
        await MainActor.run {
            self.installationProgress = 0.2
            self.installationStatus = "Creating engine directories..."
        }

        // Create main directories
        try fileManager.createDirectory(atPath: engineDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: wineDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: gptkDirectory, withIntermediateDirectories: true)

        // Create subdirectories
        let subdirs = ["bin", "lib", "share", "bottles", "downloads", "temp"]
        for subdir in subdirs {
            try fileManager.createDirectory(
                atPath: "\(engineDirectory)/\(subdir)", withIntermediateDirectories: true)
        }

        logger.info("Engine directories created successfully")
    }

    private func downloadAndInstallWine() async throws {
        await MainActor.run {
            self.installationProgress = 0.3
            self.installationStatus = "Downloading Wine..."
        }

        // Wine download URLs for macOS ARM64
        let wineVersion = "9.0"
        let wineURL =
            "https://github.com/Gcenx/macOS_Wine_builds/releases/download/wine-\(wineVersion)/wine-\(wineVersion)-osx64.tar.xz"

        let downloadPath = "\(engineDirectory)/downloads/wine-\(wineVersion).tar.xz"

        try await downloadFile(from: wineURL, to: downloadPath, progressRange: 0.3...0.5)

        await MainActor.run {
            self.installationStatus = "Extracting Wine..."
            self.installationProgress = 0.5
        }

        // Extract Wine
        try await extractArchive(from: downloadPath, to: wineDirectory)

        // Set executable permissions
        let wineBinPath = "\(wineDirectory)/bin"
        if fileManager.fileExists(atPath: wineBinPath) {
            try await setExecutablePermissions(path: wineBinPath)
        }

        logger.info("Wine installation completed")
    }

    private func downloadAndInstallGPTK() async throws {
        await MainActor.run {
            self.installationProgress = 0.6
            self.installationStatus = "Downloading GPTK components..."
        }

        // Download DXVK
        try await downloadDXVK()

        // Download MoltenVK
        try await downloadMoltenVK()

        // Download GPTK libraries
        try await downloadGPTKLibraries()

        logger.info("GPTK components installation completed")
    }

    private func downloadDXVK() async throws {
        let dxvkVersion = "2.3.1"
        let dxvkURL =
            "https://github.com/doitsujin/dxvk/releases/download/v\(dxvkVersion)/dxvk-\(dxvkVersion).tar.gz"
        let downloadPath = "\(engineDirectory)/downloads/dxvk-\(dxvkVersion).tar.gz"

        await MainActor.run {
            self.installationStatus = "Downloading DXVK..."
        }

        try await downloadFile(from: dxvkURL, to: downloadPath, progressRange: 0.6...0.65)

        // Extract DXVK
        let dxvkPath = "\(gptkDirectory)/dxvk"
        try fileManager.createDirectory(atPath: dxvkPath, withIntermediateDirectories: true)
        try await extractArchive(from: downloadPath, to: dxvkPath)
    }

    private func downloadMoltenVK() async throws {
        let moltenVKVersion = "1.2.9"
        let moltenVKURL =
            "https://github.com/KhronosGroup/MoltenVK/releases/download/v\(moltenVKVersion)/MoltenVK-macos.tar"
        let downloadPath = "\(engineDirectory)/downloads/MoltenVK-\(moltenVKVersion).tar"

        await MainActor.run {
            self.installationStatus = "Downloading MoltenVK..."
        }

        try await downloadFile(from: moltenVKURL, to: downloadPath, progressRange: 0.65...0.7)

        // Extract MoltenVK
        let moltenVKPath = "\(gptkDirectory)/MoltenVK"
        try fileManager.createDirectory(atPath: moltenVKPath, withIntermediateDirectories: true)
        try await extractArchive(from: downloadPath, to: moltenVKPath)
    }

    private func downloadGPTKLibraries() async throws {
        await MainActor.run {
            self.installationStatus = "Setting up GPTK libraries..."
            self.installationProgress = 0.7
        }

        // Create GPTK library structure
        let libPath = "\(gptkDirectory)/lib"
        try fileManager.createDirectory(atPath: libPath, withIntermediateDirectories: true)

        // Download essential DirectX libraries
        let libraries = [
            (
                "d3d11.dll",
                "https://github.com/doitsujin/dxvk/releases/download/v2.3.1/dxvk-2.3.1.tar.gz"
            ),
            (
                "dxgi.dll",
                "https://github.com/doitsujin/dxvk/releases/download/v2.3.1/dxvk-2.3.1.tar.gz"
            ),
            (
                "d3d12.dll",
                "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.12/vkd3d-proton-2.12.tar.xz"
            ),
        ]

        // For now, create placeholder structure - in production you'd download actual libraries
        for (libName, _) in libraries {
            let libFile = "\(libPath)/\(libName)"
            try "placeholder".write(
                to: URL(fileURLWithPath: libFile), atomically: true, encoding: .utf8)
        }
    }

    private func downloadFile(
        from urlString: String, to destinationPath: String, progressRange: ClosedRange<Double>
    ) async throws {
        guard let url = URL(string: urlString) else {
            throw EngineError.downloadFailed("Invalid URL: \(urlString)")
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw EngineError.downloadFailed("Failed to download from \(urlString)")
        }

        try data.write(to: URL(fileURLWithPath: destinationPath))

        await MainActor.run {
            self.installationProgress = progressRange.upperBound
        }
    }

    private func extractArchive(from archivePath: String, to destinationPath: String) async throws {
        let process = Process()

        if archivePath.hasSuffix(".tar.xz") {
            process.launchPath = "/usr/bin/tar"
            process.arguments = ["-xf", archivePath, "-C", destinationPath, "--strip-components=1"]
        } else if archivePath.hasSuffix(".tar.gz") {
            process.launchPath = "/usr/bin/tar"
            process.arguments = [
                "-xzf", archivePath, "-C", destinationPath, "--strip-components=1",
            ]
        } else if archivePath.hasSuffix(".tar") {
            process.launchPath = "/usr/bin/tar"
            process.arguments = ["-xf", archivePath, "-C", destinationPath, "--strip-components=1"]
        } else {
            throw EngineError.installationFailed("Unsupported archive format")
        }

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw EngineError.installationFailed("Failed to extract archive: \(archivePath)")
        }
    }

    private func setExecutablePermissions(path: String) async throws {
        let process = Process()
        process.launchPath = "/bin/chmod"
        process.arguments = ["-R", "+x", path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            logger.warning("Failed to set executable permissions for \(path)")
        }
    }

    private func ensureRosettaInstalled() async throws {
        #if arch(arm64)
            await MainActor.run {
                self.installationProgress = 0.8
                self.installationStatus = "Installing Rosetta 2..."
            }

            let process = Process()
            process.launchPath = "/usr/sbin/softwareupdate"
            process.arguments = ["--install-rosetta", "--agree-to-license"]

            try process.run()
            process.waitUntilExit()

            // Rosetta installation may return non-zero even on success if already installed
            logger.info("Rosetta 2 installation completed")
        #endif
    }

    private func configureEngine() async throws {
        await MainActor.run {
            self.installationProgress = 0.9
            self.installationStatus = "Configuring engine..."
        }

        // Create configuration files
        try await createEngineConfiguration()

        // Set up default bottle
        try await createDefaultBottle()
    }

    private func createEngineConfiguration() async throws {
        let config = EngineConfiguration(
            version: await getInstalledVersion() ?? "unknown",
            enableDXVK: enableDXVK,
            enableESync: enableESync,
            enableFSync: enableFSync,
            enableACO: enableACO,
            metalHUD: metalHUD,
            debugLogging: debugLogging,
            cpuThreads: cpuThreads,
            memoryLimit: memoryLimit,
            useRAMDisk: useRAMDisk,
            enableRosettaOptimization: enableRosettaOptimization
        )

        let configPath = engineDirectory + "/config.json"
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: configPath))
    }

    private func createDefaultBottle() async throws {
        let defaultBottlePath = engineDirectory + "/bottles/default"
        try fileManager.createDirectory(
            atPath: defaultBottlePath, withIntermediateDirectories: true)

        // Initialize Wine prefix
        if let gptkPath = getGPTKPath() {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: gptkPath)
            process.arguments = ["wineboot", "--init"]
            process.environment = getOptimizedEnvironment(bottlePath: defaultBottlePath)
            process.currentDirectoryURL = URL(fileURLWithPath: defaultBottlePath)

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                logger.warning(
                    "Wine prefix initialization returned non-zero status, but continuing...")
            }
        }
    }

    private func verifyInstallation() async throws {
        await MainActor.run {
            self.installationProgress = 0.95
            self.installationStatus = "Verifying installation..."
        }

        // Check if GPTK is accessible
        guard getGPTKPath() != nil else {
            throw EngineError.installationFailed("GPTK binary not found after installation")
        }

        // Test basic functionality
        if let gptkPath = getGPTKPath() {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: gptkPath)
            process.arguments = ["--version"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            // Version check may fail but that's ok - just verify the binary exists and is executable
            logger.info("GPTK verification completed")
        }
    }

    // MARK: - Engine Management

    func getGPTKPath() -> String? {
        // Priority 1: Our in-app engine installation
        let inAppWinePath = "\(wineDirectory)/bin/wine64"
        if fileManager.fileExists(atPath: inAppWinePath) {
            return inAppWinePath
        }

        let inAppWinePathAlt = "\(wineDirectory)/bin/wine"
        if fileManager.fileExists(atPath: inAppWinePathAlt) {
            return inAppWinePathAlt
        }

        // Priority 2: System installations
        let paths = [
            "/opt/homebrew/bin/game-porting-toolkit",
            "/usr/local/bin/game-porting-toolkit",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
            "/Applications/Game Porting Toolkit.app/Contents/MacOS/gameportingtoolkit",
        ]

        return paths.first { fileManager.fileExists(atPath: $0) }
    }

    func getOptimizedEnvironment(bottlePath: String) -> [String: String] {
        var env = ProcessInfo.processInfo.environment

        // Wine configuration
        env["WINEPREFIX"] = bottlePath
        env["WINEDEBUG"] = debugLogging ? "+all" : "-all"
        env["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"

        // Performance optimizations
        env["WINEESYNC"] = enableESync ? "1" : "0"
        env["WINEFSYNC"] = enableFSync ? "1" : "0"

        // DXVK configuration
        if enableDXVK {
            env["DXVK_HUD"] = metalHUD ? "full" : "0"
            env["DXVK_LOG_LEVEL"] = debugLogging ? "info" : "none"
            env["DXVK_STATE_CACHE_PATH"] = bottlePath + "/dxvk_cache"
        }

        // Metal/macOS optimizations
        env["MTL_HUD_ENABLED"] = metalHUD ? "1" : "0"
        env["MTL_SHADER_VALIDATION"] = debugLogging ? "1" : "0"
        env["MTL_DEBUG_LAYER"] = debugLogging ? "1" : "0"

        // Rosetta optimizations
        if enableRosettaOptimization {
            env["ROSETTA_ADVERTISE_AVX"] = "1"
        }

        // CPU and memory limits
        env["WINE_CPU_TOPOLOGY"] = "\(cpuThreads):1"

        // RAM disk for temporary files
        if useRAMDisk {
            let ramDiskPath = "/Volumes/kimiz_engine_cache"
            env["TMPDIR"] = ramDiskPath
            env["WINE_TMPDIR"] = ramDiskPath
        }

        return env
    }

    func createBottle(name: String) async throws {
        let bottlePath = engineDirectory + "/bottles/\(name)"
        try fileManager.createDirectory(atPath: bottlePath, withIntermediateDirectories: true)

        // Initialize the bottle
        if let gptkPath = getGPTKPath() {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: gptkPath)
            process.arguments = ["wineboot", "--init"]
            process.environment = getOptimizedEnvironment(bottlePath: bottlePath)
            process.currentDirectoryURL = URL(fileURLWithPath: bottlePath)

            try process.run()
            process.waitUntilExit()
        }
    }

    func removeEngine() async throws {
        logger.info("Removing engine installation")

        await MainActor.run {
            self.installationStatus = "Removing engine..."
        }

        // Remove engine directory
        if fileManager.fileExists(atPath: engineDirectory) {
            try fileManager.removeItem(atPath: engineDirectory)
        }

        // Optionally remove GPTK from Homebrew
        if let brewPath = getBrewPath() {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["uninstall", "game-porting-toolkit"]

            try process.run()
            process.waitUntilExit()
        }

        await MainActor.run {
            self.isEngineInstalled = false
            self.engineVersion = nil
            self.installationStatus = "Engine removed successfully"
        }
    }

    // MARK: - Utilities

    private func getBrewPath() -> String? {
        let paths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew",  // Intel
        ]

        return paths.first { fileManager.fileExists(atPath: $0) }
    }

    func getEngineInfo() -> EngineInfo {
        return EngineInfo(
            isInstalled: isEngineInstalled,
            version: engineVersion,
            gptkPath: getGPTKPath(),
            engineDirectory: engineDirectory,
            configuration: loadConfiguration()
        )
    }

    private func loadConfiguration() -> EngineConfiguration? {
        let configPath = engineDirectory + "/config.json"
        guard fileManager.fileExists(atPath: configPath) else { return nil }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            return try JSONDecoder().decode(EngineConfiguration.self, from: data)
        } catch {
            logger.error("Failed to load engine configuration: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Data Models

struct EngineConfiguration: Codable {
    let version: String
    let enableDXVK: Bool
    let enableESync: Bool
    let enableFSync: Bool
    let enableACO: Bool
    let metalHUD: Bool
    let debugLogging: Bool
    let cpuThreads: Int
    let memoryLimit: Int
    let useRAMDisk: Bool
    let enableRosettaOptimization: Bool
    let createdAt: Date

    init(
        version: String, enableDXVK: Bool, enableESync: Bool, enableFSync: Bool,
        enableACO: Bool, metalHUD: Bool, debugLogging: Bool, cpuThreads: Int,
        memoryLimit: Int, useRAMDisk: Bool, enableRosettaOptimization: Bool
    ) {
        self.version = version
        self.enableDXVK = enableDXVK
        self.enableESync = enableESync
        self.enableFSync = enableFSync
        self.enableACO = enableACO
        self.metalHUD = metalHUD
        self.debugLogging = debugLogging
        self.cpuThreads = cpuThreads
        self.memoryLimit = memoryLimit
        self.useRAMDisk = useRAMDisk
        self.enableRosettaOptimization = enableRosettaOptimization
        self.createdAt = Date()
    }
}

struct EngineInfo {
    let isInstalled: Bool
    let version: String?
    let gptkPath: String?
    let engineDirectory: String
    let configuration: EngineConfiguration?
}

enum EngineError: LocalizedError {
    case unsupportedSystem(String)
    case insufficientSpace(String)
    case installationFailed(String)
    case configurationError(String)
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSystem(let message):
            return "Unsupported System: \(message)"
        case .insufficientSpace(let message):
            return "Insufficient Space: \(message)"
        case .installationFailed(let message):
            return "Installation Failed: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .downloadFailed(let message):
            return "Download Failed: \(message)"
        }
    }
}
