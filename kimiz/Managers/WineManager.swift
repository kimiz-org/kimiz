//
//  EpicGamesManager.swift
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
    private let maxConcurrentProcesses = 3
    private let cpuThrottleThreshold: Double = 80.0
    private let processTimeout: TimeInterval = 1800.0
    private let gameTimeout: TimeInterval = 3600.0
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
        env["DXVK_HUD"] = "0"
        env["DXVK_LOG_LEVEL"] = "none"
        env["VKD3D_DEBUG"] = "none"
        env["MESA_NO_ERROR"] = "1"
        env["VK_ICD_FILENAMES"] =
            "/Library/Frameworks/VMwareVM.framework/Resources/vulkan/icd.d/MoltenVK_icd.json"
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
        env["DXVK_HUD"] = "0"
        env["DXVK_LOG_LEVEL"] = "none"
        env["VKD3D_DEBUG"] = "none"
        env["MESA_NO_ERROR"] = "1"
        env["VK_ICD_FILENAMES"] =
            "/Library/Frameworks/VMwareVM.framework/Resources/vulkan/icd.d/MoltenVK_icd.json"
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
}
