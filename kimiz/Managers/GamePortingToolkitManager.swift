//
//  GamePortingToolkitManager.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Foundation

class GamePortingToolkitManager {
    static let shared = GamePortingToolkitManager()

    private init() {}

    // MARK: - GPTK Installation Check

    func isGamePortingToolkitInstalled() -> Bool {
        let gptPaths = [
            "/usr/local/bin/wine64",
            "/usr/local/lib/wine",
            "/usr/local/include/wine",
        ]

        return gptPaths.allSatisfy { path in
            FileManager.default.fileExists(atPath: path)
        }
    }

    func getGamePortingToolkitVersion() -> String? {
        guard isGamePortingToolkitInstalled() else { return nil }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/wine64")
        task.arguments = ["--version"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(
                in: .whitespacesAndNewlines)

            return output
        } catch {
            return nil
        }
    }

    // MARK: - GPTK Optimization

    func getOptimizedEnvironment(for prefix: WinePrefix) -> [String: String] {
        var environment: [String: String] = [
            "WINEPREFIX": prefix.path,
            "WINEDEBUG": "-all",
        ]

        if prefix.backend == .gamePortingToolkit {
            // Game Porting Toolkit specific optimizations
            environment["MTL_HUD_ENABLED"] = "1"
            environment["WINEESYNC"] = "1"
            environment["DXVK_ASYNC"] = "1"
            environment["WINE_LARGE_ADDRESS_AWARE"] = "1"
            environment["MTL_SHADER_VALIDATION"] = "0"
            environment["MTL_DEBUG_LAYER"] = "0"

            // Memory and performance optimizations
            environment["WINE_CPU_TOPOLOGY"] = "4:2"
            environment["STAGING_WRITECOPY"] = "1"
            environment["STAGING_SHARED_MEMORY"] = "1"

            // DirectX optimizations
            environment["DXVK_STATE_CACHE"] = "1"
            environment["DXVK_LOG_LEVEL"] = "none"

            // Audio optimizations
            environment["PULSE_LATENCY_MSEC"] = "60"
        }

        return environment
    }

    // MARK: - Game-specific Optimizations

    func getGameSpecificOptimizations(for gameName: String) -> [String: String] {
        var optimizations: [String: String] = [:]

        let gameNameLower = gameName.lowercased()

        // Steam-specific optimizations
        if gameNameLower.contains("steam") {
            optimizations["WINE_CPU_TOPOLOGY"] = "4:2"
            optimizations["STAGING_WRITECOPY"] = "1"
        }

        // Common game optimizations
        if gameNameLower.contains("game") || gameNameLower.contains(".exe") {
            optimizations["DXVK_ASYNC"] = "1"
            optimizations["DXVK_STATE_CACHE"] = "1"
            optimizations["MTL_HUD_ENABLED"] = "1"
        }

        // Specific game optimizations
        switch gameNameLower {
        case let name where name.contains("counter-strike") || name.contains("cs2"):
            optimizations["DXVK_ASYNC"] = "1"
            optimizations["RADV_PERFTEST"] = "aco"

        case let name where name.contains("cyberpunk"):
            optimizations["DXVK_ASYNC"] = "1"
            optimizations["DXVK_STATE_CACHE"] = "1"
            optimizations["WINE_LARGE_ADDRESS_AWARE"] = "1"

        case let name where name.contains("witcher"):
            optimizations["DXVK_ASYNC"] = "1"
            optimizations["STAGING_WRITECOPY"] = "1"

        default:
            break
        }

        return optimizations
    }

    // MARK: - Installation Scripts

    func generateGPTKInstallationScript() -> String {
        return """
            #!/bin/bash

            # Game Porting Toolkit Installation Script
            # This script helps install Apple's Game Porting Toolkit

            echo "Installing Game Porting Toolkit..."

            # Check for Xcode Command Line Tools
            if ! xcode-select -p &> /dev/null; then
                echo "Installing Xcode Command Line Tools..."
                xcode-select --install
                echo "Please complete the Xcode Command Line Tools installation and run this script again."
                exit 1
            fi

            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi

            # Add Homebrew to PATH
            if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
                export PATH="/opt/homebrew/bin:$PATH"
            fi

            # Tap Apple's Game Porting Toolkit repository
            echo "Adding Game Porting Toolkit tap..."
            brew tap apple/apple

            # Install Game Porting Toolkit
            echo "Installing Game Porting Toolkit..."
            brew install game-porting-toolkit

            # Verify installation
            if command -v wine64 &> /dev/null; then
                echo "Game Porting Toolkit installed successfully!"
                wine64 --version
            else
                echo "Installation may have failed. Please check the output above."
                exit 1
            fi

            echo "Installation complete. You can now create Game Porting Toolkit prefixes in Kimiz."
            """
    }

    func installGamePortingToolkit() async throws {
        let script = generateGPTKInstallationScript()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "install_gptk.sh")

        try script.write(to: tempURL, atomically: true, encoding: .utf8)

        // Make script executable
        let attributes = [FileAttributeKey.posixPermissions: 0o755]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: tempURL.path)

        // Run the script
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [tempURL.path]

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw WineError.installationFailed("Game Porting Toolkit installation failed")
        }

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Registry Modifications

    func applyRegistryOptimizations(to prefix: WinePrefix) async throws {
        let registryScript = """
            REGEDIT4

            [HKEY_CURRENT_USER\\Software\\Wine\\WineDbg]
            "DebugLevel"=dword:00000000

            [HKEY_CURRENT_USER\\Software\\Wine\\DirectSound]
            "MaxShadowSize"=dword:00000002
            "DefaultBitsPerSample"=dword:00000010
            "DefaultSampleRate"=dword:0000ac44

            [HKEY_CURRENT_USER\\Software\\Wine\\DirectInput]
            "MouseWarpOverride"="force"

            [HKEY_CURRENT_USER\\Software\\Wine\\Explorer]
            "Desktop"=""

            [HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
            "dxvk_config"="native"
            "d3d11"="native"
            "dxgi"="native"
            """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "gptk_optimizations.reg")
        try registryScript.write(to: tempURL, atomically: true, encoding: .utf8)

        // Apply registry modifications
        let task = Process()
        task.executableURL = URL(fileURLWithPath: prefix.backend.executablePath)
        task.arguments = ["regedit", tempURL.path]
        task.environment = ["WINEPREFIX": prefix.path]

        try task.run()
        task.waitUntilExit()

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
}
