//
//  WineManager.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
//

import AppKit
import Foundation
import SwiftUI
import os.log

// Game Porting Toolkit-specific error types
enum WineError: LocalizedError {
    case resourceLimitExceeded
    case highCPUUsage(Double)
    case processTimeout
    case initializationFailed
    case gptkNotFound

    var errorDescription: String? {
        switch self {
        case .resourceLimitExceeded:
            return "Too many Game Porting Toolkit processes running simultaneously"
        case .highCPUUsage(let usage):
            return "System CPU usage too high (\(String(format: "%.1f", usage))%)"
        case .processTimeout:
            return "Game Porting Toolkit process timed out"
        case .initializationFailed:
            return "Failed to initialize Game Porting Toolkit process"
        case .gptkNotFound:
            return
                "Game Porting Toolkit not found. Please install GPTK using Homebrew: brew install apple/apple/game-porting-toolkit"
        }
    }
}

// MARK: - WineManager: Modern, Robust, and Modular

internal actor WineManager {
    static let shared = WineManager()
    private let fileManager = FileManager.default
    private let defaultBottlePath: String = NSString(
        string: "~/Library/Application Support/kimiz/gptk-bottles/default"
    ).expandingTildeInPath

    // Process and resource management
    private var activeProcesses: Set<Int32> = []
    private let processQueue = DispatchQueue(label: "kimiz.wine.process.queue", qos: .userInitiated)
    private let maxConcurrentProcesses = 5  // Increased from 3
    private let cpuThrottleThreshold: Double = 90.0  // Increased from 80% to 90%
    private let processTimeout: TimeInterval = 1800.0
    private let gameTimeout: TimeInterval = 7200.0  // Increased game timeout
    private let installerTimeout: TimeInterval = 7200.0

    // MARK: - Public API

    /// Run a Windows process using Wine or GPTK with robust resource and timeout management
    func runWineProcess(
        winePath: String,
        executablePath: String,
        arguments: [String] = [],
        environment: [String: String],
        workingDirectory: String? = nil,
        defaultBottlePath: String
    ) async throws {
        try await checkSystemResources()
        await cleanupStaleProcesses()
        let timeout = determineTimeout(for: executablePath)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = [executablePath] + arguments
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory ?? defaultBottlePath)
        process.environment = prepareEnvironment(base: environment)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let fileHandle = pipe.fileHandleForReading
        var hasResumed = false
        let resumeQueue = DispatchQueue(label: "kimiz.wine.resume.queue")
        try await withCheckedThrowingContinuation { continuation in
            func safeResume(_ block: @escaping () -> Void) {
                resumeQueue.sync {
                    guard !hasResumed else { return }
                    hasResumed = true
                    block()
                }
            }
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    fileHandle.readabilityHandler = nil
                    safeResume { continuation.resume() }
                    return
                }
                if let str = String(data: data, encoding: .utf8) {
                    print("[Wine Output]", str)
                }
            }
            do {
                try process.run()
                let pid = process.processIdentifier
                activeProcesses.insert(pid)
                monitorProcessWithTimeout(process: process, timeout: timeout)
            } catch {
                fileHandle.readabilityHandler = nil
                safeResume { continuation.resume(throwing: error) }
                return
            }
            DispatchQueue.global().async {
                process.waitUntilExit()
                fileHandle.readabilityHandler = nil
                let pid = process.processIdentifier
                Task { await self.removeActiveProcess(pid) }
                safeResume { continuation.resume() }
            }
        }
    }

    // MARK: - Resource & Process Management

    private func checkSystemResources() async throws {
        if activeProcesses.count >= maxConcurrentProcesses {
            throw WineError.resourceLimitExceeded
        }
        let cpuUsage = await getCurrentCPUUsage()
        if cpuUsage > cpuThrottleThreshold {
            throw WineError.highCPUUsage(cpuUsage)
        }
    }

    private func removeActiveProcess(_ pid: Int32) {
        activeProcesses.remove(pid)
    }

    private func cleanupStaleProcesses() async {
        // Optionally kill or clean up zombie/stuck Wine processes
        // (Implementation can be added as needed)
    }

    // MARK: - Timeout & Monitoring

    private func determineTimeout(for executablePath: String) -> TimeInterval {
        let fileName = (executablePath as NSString).lastPathComponent.lowercased()
        if fileName.contains("setup") || fileName.contains("install")
            || fileName.contains("steamsetup")
        {
            return installerTimeout
        }
        if fileName.hasSuffix(".exe") && !fileName.contains("unins") {
            return gameTimeout
        }
        return processTimeout
    }

    private func monitorProcessWithTimeout(process: Process, timeout: TimeInterval) {
        Task {
            let pid = process.processIdentifier
            let checkInterval: TimeInterval = 30.0
            var elapsed: TimeInterval = 0.0
            while elapsed < timeout && process.isRunning {
                try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                elapsed += checkInterval
            }
            if process.isRunning && elapsed >= timeout {
                process.terminate()
            }
        }
    }

    // MARK: - Environment Preparation

    private func prepareEnvironment(base: [String: String]) -> [String: String] {
        var env = base
        env["WINEDEBUG"] = "-all"
        env["WINE_LARGE_ADDRESS_AWARE"] = "1"
        env["WINE_DISABLE_LAYER_COMPOSITOR"] = "1"
        env["WINE_CPU_TOPOLOGY"] = "4:2"

        // Enhanced DirectX/Graphics Configuration
        env["DXVK_HUD"] = "0"
        env["DXVK_LOG_LEVEL"] = "none"
        env["DXVK_STATE_CACHE_PATH"] = (base["WINEPREFIX"] ?? defaultBottlePath) + "/dxvk_cache"
        env["DXVK_CONFIG_FILE"] = (base["WINEPREFIX"] ?? defaultBottlePath) + "/dxvk.conf"
        env["VKD3D_DEBUG"] = "none"
        env["VKD3D_SHADER_DEBUG"] = "none"
        env["MESA_NO_ERROR"] = "1"

        // Critical MoltenVK/Vulkan Configuration for macOS
        let moltenVKPaths = [
            "/opt/homebrew/share/vulkan/icd.d/MoltenVK_icd.json",
            "/usr/local/share/vulkan/icd.d/MoltenVK_icd.json",
            "/Library/Frameworks/VMwareVM.framework/Resources/vulkan/icd.d/MoltenVK_icd.json",
            "/System/Library/Frameworks/MoltenVK.framework/Resources/vulkan/icd.d/MoltenVK_icd.json",
        ]

        if let validPath = moltenVKPaths.first(where: { fileManager.fileExists(atPath: $0) }) {
            env["VK_ICD_FILENAMES"] = validPath
        } else {
            // Fallback - create symlink if needed
            env["VK_ICD_FILENAMES"] = "/opt/homebrew/share/vulkan/icd.d/MoltenVK_icd.json"
        }

        // Additional Metal/macOS Graphics Settings
        env["MTL_HUD_ENABLED"] = "0"
        env["MTL_SHADER_VALIDATION"] = "0"
        env["MTL_DEBUG_LAYER"] = "0"
        env["MTL_CAPTURE_ENABLED"] = "0"
        env["METAL_DEVICE_WRAPPER_TYPE"] = "1"
        env["MTL_FORCE_VALIDATION"] = "0"

        // DirectX Override Settings
        env["WINEDLLOVERRIDES"] = "d3d11=n,b;dxgi=n,b;d3d10core=n,b;d3d9=n,b;winemenubuilder.exe=d"

        // Display and Renderer Settings
        env["DISPLAY"] = ":0.0"
        env["LIBGL_ALWAYS_SOFTWARE"] = "0"
        env["__GL_SHADER_DISK_CACHE"] = "1"
        env["__GL_THREADED_OPTIMIZATIONS"] = "1"

        if !env.keys.contains("WINE_AUDIO_DRIVER") {
            env["WINE_AUDIO_DRIVER"] = "null"
        }

        // TMPDIR setup
        let appSupportDir = (NSHomeDirectory() as NSString).appendingPathComponent(
            "Library/Application Support/kimiz")
        let tmpDir = (appSupportDir as NSString).appendingPathComponent("tmp")
        if !fileManager.fileExists(atPath: tmpDir) {
            try? fileManager.createDirectory(
                atPath: tmpDir, withIntermediateDirectories: true, attributes: nil)
        }
        env["TMPDIR"] = tmpDir
        return env
    }

    // MARK: - Static Optimized Environment (for BottleManager and others)
    static func staticOptimizedWineEnvironment(base: [String: String], useRAMDisk: Bool = false)
        -> [String: String]
    {
        var env = base
        env["WINEDEBUG"] = "-all"
        env["WINE_LARGE_ADDRESS_AWARE"] = "1"
        env["WINE_DISABLE_LAYER_COMPOSITOR"] = "1"
        env["WINE_CPU_TOPOLOGY"] = "4:2"

        // Enhanced DirectX/Graphics Configuration
        env["DXVK_HUD"] = "0"
        env["DXVK_LOG_LEVEL"] = "none"
        env["DXVK_STATE_CACHE_PATH"] = (base["WINEPREFIX"] ?? "") + "/dxvk_cache"
        env["DXVK_CONFIG_FILE"] = (base["WINEPREFIX"] ?? "") + "/dxvk.conf"
        env["VKD3D_DEBUG"] = "none"
        env["VKD3D_SHADER_DEBUG"] = "none"
        env["MESA_NO_ERROR"] = "1"

        // Critical MoltenVK/Vulkan Configuration for macOS
        let moltenVKPaths = [
            "/opt/homebrew/share/vulkan/icd.d/MoltenVK_icd.json",
            "/usr/local/share/vulkan/icd.d/MoltenVK_icd.json",
            "/Library/Frameworks/VMwareVM.framework/Resources/vulkan/icd.d/MoltenVK_icd.json",
            "/System/Library/Frameworks/MoltenVK.framework/Resources/vulkan/icd.d/MoltenVK_icd.json",
        ]

        if let validPath = moltenVKPaths.first(where: { FileManager.default.fileExists(atPath: $0) }
        ) {
            env["VK_ICD_FILENAMES"] = validPath
        } else {
            // Fallback - create symlink if needed
            env["VK_ICD_FILENAMES"] = "/opt/homebrew/share/vulkan/icd.d/MoltenVK_icd.json"
        }

        // Additional Metal/macOS Graphics Settings
        env["MTL_HUD_ENABLED"] = "0"
        env["MTL_SHADER_VALIDATION"] = "0"
        env["MTL_DEBUG_LAYER"] = "0"
        env["MTL_CAPTURE_ENABLED"] = "0"
        env["METAL_DEVICE_WRAPPER_TYPE"] = "1"
        env["MTL_FORCE_VALIDATION"] = "0"

        // DirectX Override Settings
        env["WINEDLLOVERRIDES"] = "d3d11=n,b;dxgi=n,b;d3d10core=n,b;d3d9=n,b;winemenubuilder.exe=d"

        // Display and Renderer Settings
        env["DISPLAY"] = ":0.0"
        env["LIBGL_ALWAYS_SOFTWARE"] = "0"
        env["__GL_SHADER_DISK_CACHE"] = "1"
        env["__GL_THREADED_OPTIMIZATIONS"] = "1"

        if !env.keys.contains("WINE_AUDIO_DRIVER") {
            env["WINE_AUDIO_DRIVER"] = "null"
        }

        if useRAMDisk {
            let ramDiskPath = "/Volumes/kimiz_ramdisk"
            env["TMPDIR"] = ramDiskPath
        } else {
            let appSupportDir = (NSHomeDirectory() as NSString).appendingPathComponent(
                "Library/Application Support/kimiz")
            let tmpDir = (appSupportDir as NSString).appendingPathComponent("tmp")
            env["TMPDIR"] = tmpDir
        }
        return env
    }

    // MARK: - CPU Usage

    private func getCurrentCPUUsage() async -> Double {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/top"
            task.arguments = ["-l", "1", "-n", "0"]
            let pipe = Pipe()
            task.standardOutput = pipe
            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if line.contains("CPU usage:") {
                            let components = line.components(separatedBy: ",")
                            if let userComponent = components.first(where: { $0.contains("user") })
                            {
                                let numbers = userComponent.components(separatedBy: .whitespaces)
                                    .compactMap {
                                        Double($0.replacingOccurrences(of: "%", with: ""))
                                    }
                                if let userCPU = numbers.first {
                                    continuation.resume(returning: userCPU)
                                    return
                                }
                            }
                        }
                    }
                }
                continuation.resume(returning: 0.0)
            } catch {
                continuation.resume(returning: 0.0)
            }
        }
    }

    // MARK: - Graphics Diagnostics & Fixes

    /// Diagnose and attempt to fix graphics initialization issues
    func diagnoseGraphicsIssues(bottlePath: String) async -> [String] {
        var issues: [String] = []
        var fixes: [String] = []

        // Check MoltenVK installation
        let moltenVKPaths = [
            "/opt/homebrew/share/vulkan/icd.d/MoltenVK_icd.json",
            "/usr/local/share/vulkan/icd.d/MoltenVK_icd.json",
            "/Library/Frameworks/VMwareVM.framework/Resources/vulkan/icd.d/MoltenVK_icd.json",
        ]

        let moltenVKInstalled = moltenVKPaths.contains { fileManager.fileExists(atPath: $0) }
        if !moltenVKInstalled {
            issues.append("❌ MoltenVK not found - required for Vulkan/DXVK support")
            fixes.append("💡 Install MoltenVK: brew install molten-vk")
        }

        // Check DXVK DLLs in wine prefix
        let dxvkDLLs = ["d3d11.dll", "dxgi.dll", "d3d10core.dll", "d3d9.dll"]
        let system32Path = "\(bottlePath)/drive_c/windows/system32"

        for dll in dxvkDLLs {
            let dllPath = "\(system32Path)/\(dll)"
            if !fileManager.fileExists(atPath: dllPath) {
                issues.append("❌ Missing DXVK DLL: \(dll)")
                fixes.append("💡 Install DXVK in this bottle using winetricks")
            }
        }

        // Check for GPU compatibility
        let metalCheck = await checkMetalSupport()
        if !metalCheck {
            issues.append("❌ Metal support not available or disabled")
            fixes.append("💡 Ensure your Mac supports Metal and it's enabled in System Settings")
        }

        return issues + fixes
    }

    /// Check if Metal is available on this system
    private func checkMetalSupport() async -> Bool {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/system_profiler"
            task.arguments = ["SPDisplaysDataType"]
            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let hasMetalSupport = output.contains("Metal") && output.contains("Supported")
                    continuation.resume(returning: hasMetalSupport)
                } else {
                    continuation.resume(returning: false)
                }
            } catch {
                continuation.resume(returning: false)
            }
        }
    }

    // MARK: - DirectX/Graphics Initialization Fixes

    /// Automatically fix common DirectX/graphics initialization issues
    func fixGraphicsInitialization(bottlePath: String) async throws {
        print("[WineManager] Attempting to fix graphics initialization issues...")

        // 1. Ensure MoltenVK is properly installed and linked
        try await setupMoltenVK()

        // 2. Install/reinstall DXVK in the bottle
        try await installDXVKInBottle(bottlePath: bottlePath)

        // 3. Configure DirectX registry settings
        try await configureDirectXRegistry(bottlePath: bottlePath)

        print("[WineManager] Graphics fixes applied. Try running your application again.")
    }

    private func setupMoltenVK() async throws {
        // Check if MoltenVK is installed via Homebrew
        let brewPath =
            fileManager.fileExists(atPath: "/opt/homebrew/bin/brew")
            ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"

        if fileManager.fileExists(atPath: brewPath) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "molten-vk"]

            try process.run()
            process.waitUntilExit()

            // Create symlinks for ICD files if needed
            let sources = ["/opt/homebrew/share/vulkan/icd.d/MoltenVK_icd.json"]
            let targets = ["/usr/local/share/vulkan/icd.d/MoltenVK_icd.json"]

            for (source, target) in zip(sources, targets) {
                if fileManager.fileExists(atPath: source) && !fileManager.fileExists(atPath: target)
                {
                    let targetDir = (target as NSString).deletingLastPathComponent
                    try? fileManager.createDirectory(
                        atPath: targetDir, withIntermediateDirectories: true, attributes: nil)
                    try? fileManager.createSymbolicLink(atPath: target, withDestinationPath: source)
                }
            }
        }
    }

    private func installDXVKInBottle(bottlePath: String) async throws {
        let winetricksPath =
            fileManager.fileExists(atPath: "/opt/homebrew/bin/winetricks")
            ? "/opt/homebrew/bin/winetricks" : "/usr/local/bin/winetricks"

        guard fileManager.fileExists(atPath: winetricksPath) else {
            throw WineError.initializationFailed
        }

        let winePath = [
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
        ].first { fileManager.fileExists(atPath: $0) }

        guard let validWinePath = winePath else {
            throw WineError.gptkNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: winetricksPath)
        process.arguments = ["-q", "dxvk"]
        process.environment = [
            "WINEPREFIX": bottlePath,
            "WINE": validWinePath,
            "WINEDEBUG": "-all",
            "DISPLAY": ":0.0",
        ]
        process.currentDirectoryURL = URL(fileURLWithPath: bottlePath)

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw WineError.initializationFailed
        }
    }

    private func configureDirectXRegistry(bottlePath: String) async throws {
        let regContent = """
            Windows Registry Editor Version 5.00

            [HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
            "DirectDrawRenderer"="opengl"
            "OffscreenRenderingMode"="fbo"
            "UseGLSL"="enabled"
            "VertexShaderMode"="hardware"
            "PixelShaderMode"="hardware"
            "Multisampling"="enabled"

            [HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
            "d3d11"="native,builtin"
            "dxgi"="native,builtin"
            "d3d10core"="native,builtin"
            "d3d9"="native,builtin"
            """

        let regFilePath = "\(bottlePath)/graphics_fix.reg"
        try regContent.write(
            to: URL(fileURLWithPath: regFilePath), atomically: true, encoding: .utf8)

        let winePath = [
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64",
        ].first { fileManager.fileExists(atPath: $0) }

        guard let validWinePath = winePath else {
            throw WineError.gptkNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: validWinePath)
        process.arguments = ["regedit", regFilePath]
        process.environment = [
            "WINEPREFIX": bottlePath,
            "WINEDEBUG": "-all",
        ]
        process.currentDirectoryURL = URL(fileURLWithPath: bottlePath)

        try process.run()
        process.waitUntilExit()

        // Clean up temporary reg file
        try? fileManager.removeItem(atPath: regFilePath)
    }

    // MARK: - Game Launch Optimization
    
    /// Create optimized environment for game launches to prevent black screens
    private func createGameLaunchEnvironment(base: [String: String]) -> [String: String] {
        var environment = base
        
        // Graphics optimization settings
        environment["DXVK_ASYNC"] = "1"
        environment["DXVK_STATE_CACHE"] = "1"
        environment["DXVK_SHADER_CACHE"] = "1"
        environment["DXVK_HUD"] = "0"  // Disable HUD overlay
        environment["DXVK_FILTER_DEVICE_NAME"] = "0"
        
        // Wine graphics settings
        environment["WINE_LARGE_ADDRESS_AWARE"] = "1"
        environment["WINE_CPU_TOPOLOGY"] = "4:2"
        environment["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d;mscoree=d;mshtml=d"
        
        // OpenGL/Metal optimization
        environment["__GL_SHADER_DISK_CACHE"] = "1"
        environment["__GL_SHADER_DISK_CACHE_PATH"] = defaultBottlePath + "/shader_cache"
        environment["MESA_GLSL_CACHE_DISABLE"] = "false"
        environment["MESA_GLSL_CACHE_MAX_SIZE"] = "1G"
        
        // Display settings to prevent black screen
        environment["DISPLAY"] = ":0"
        environment["WINE_DISABLE_LAYER_COMPOSITOR"] = "0"  // Enable compositor for better compatibility
        environment["WINE_SYNCHRONOUS"] = "0"  // Disable synchronous mode for better performance
        
        // Memory optimization
        environment["WINE_HEAP_SIZE"] = "2G"
        environment["WINEDEBUG"] = "-all"  // Disable debug output for performance
        
        // Disable problematic Windows services
        environment["WINE_DISABLE_SVCHOST"] = "1"
        environment["WINE_DISABLE_EXPLORER"] = "1"
        
        return environment
    }
}
