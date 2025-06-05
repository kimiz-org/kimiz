import Foundation
import os.log

// Wine-specific error types
enum WineError: LocalizedError {
    case resourceLimitExceeded
    case highCPUUsage(Double)
    case processTimeout
    case initializationFailed

    var errorDescription: String? {
        switch self {
        case .resourceLimitExceeded:
            return "Too many Wine processes running simultaneously"
        case .highCPUUsage(let usage):
            return "System CPU usage too high (\(String(format: "%.1f", usage))%)"
        case .processTimeout:
            return "Wine process timed out"
        case .initializationFailed:
            return "Failed to initialize Wine process"
        }
    }
}

actor WineManager {
    static let shared = WineManager()
    private let fileManager = FileManager.default
    private let defaultBottlePath: String = NSString(
        string: "~/Library/Application Support/kimiz/gptk-bottles/default"
    ).expandingTildeInPath

    // Performance monitoring
    private let logger = Logger(subsystem: "dev.kimiz.winemanager", category: "performance")
    private var activeProcesses: Set<Int32> = []
    private let processQueue = DispatchQueue(label: "wine.process.management", qos: .userInitiated)

    // Process timeout and resource limits
    private let processTimeout: TimeInterval = 300.0  // 5 minutes max
    private let maxConcurrentProcesses = 3
    private let cpuThrottleThreshold: Double = 80.0  // CPU percentage

    // Cache compiled regexes for performance - moved to class level
    private static let cachedPatterns: [(NSRegularExpression, String)] = {
        let errorPatterns = [
            // DirectX error patterns - look for actual errors, not just mentions
            ("failed to create d3d11", "directx11"),
            ("d3d11 device creation failed", "directx11"),
            ("dxgi error", "directx11"),
            ("directx.*not found", "directx11"),
            ("directx.*missing", "directx11"),
            ("d3d12.*failed", "directx12"),

            // Visual C++ Runtime error patterns
            ("vcruntime140.*not found", "vcrun2015"),
            ("msvcp140.*missing", "vcrun2015"),
            ("api-ms-win.*not found", "vcrun2015"),
            ("runtime library.*missing", "vcrun2015"),

            // D3D Compiler error patterns
            ("d3dcompiler.*not found", "d3dcompiler_47"),
            ("d3dcompiler.*missing", "d3dcompiler_47"),
            ("shader compilation failed", "d3dcompiler_47"),

            // .NET Framework error patterns
            ("dotnet.*not installed", "dotnet48"),
            (".net framework.*missing", "dotnet48"),
            ("mscorlib.*not found", "dotnet48"),

            // Vulkan error patterns - only real errors, not info messages
            ("vulkan.*not found", "vulkan"),
            ("vulkan.*missing", "vulkan"),
            ("vulkan.*failed", "vulkan"),
            ("vk_.*error", "vulkan"),
            ("vulkan driver.*not", "vulkan"),

            // DXVK error patterns
            ("dxvk.*error", "dxvk"),
            ("dxvk.*failed", "dxvk"),

            // General DLL missing patterns
            (".*\\.dll.*not found", "vcrun2015"),
            (".*\\.dll.*missing", "vcrun2015"),
        ]

        return errorPatterns.compactMap { pattern, component in
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                return (regex, component)
            } catch {
                return nil
            }
        }
    }()

    // Helper to detect missing component from Wine output
    func detectMissingComponent(from output: String) -> String? {
        let lowercaseOutput = output.lowercased()

        // Skip MoltenVK informational messages - these are not errors
        if lowercaseOutput.contains("[mvk-info]") || lowercaseOutput.contains("created vkinstance")
            || lowercaseOutput.contains("moltenvk")
        {
            return nil
        }

        // Skip successful Vulkan initialization messages
        if lowercaseOutput.contains("vulkan version") && lowercaseOutput.contains("enabled") {
            return nil
        }

        // Use the static cached patterns
        for (regex, component) in Self.cachedPatterns {
            let range = NSRange(location: 0, length: lowercaseOutput.count)
            if regex.firstMatch(in: lowercaseOutput, options: [], range: range) != nil {
                return component
            }
        }
        return nil
    }

    // Check system resources before launching process
    private func checkSystemResources() async throws {
        // Check if we're exceeding concurrent process limit
        if activeProcesses.count >= maxConcurrentProcesses {
            logger.warning(
                "Maximum concurrent Wine processes reached (\(self.maxConcurrentProcesses))")
            throw WineError.resourceLimitExceeded
        }

        // Check CPU usage
        let cpuUsage = await getCurrentCPUUsage()
        if cpuUsage > cpuThrottleThreshold {
            logger.warning("High CPU usage detected (\(cpuUsage)%), throttling Wine process")
            throw WineError.highCPUUsage(cpuUsage)
        }
    }

    // Monitor CPU usage
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
                    // Parse CPU usage from top output
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if line.contains("CPU usage:") {
                            // Extract CPU percentage from line like "CPU usage: 12.34% user, 5.67% sys, 81.99% idle"
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

    // Helper method to safely remove process from active set
    private func removeActiveProcess(_ pid: Int32) {
        activeProcesses.remove(pid)
        logger.info("Wine process PID \(pid) completed")
    }

    // Cleanup stale Wine processes
    private func cleanupStaleProcesses() async {
        await withCheckedContinuation { continuation in
            processQueue.async {
                let task = Process()
                task.launchPath = "/usr/bin/pgrep"
                task.arguments = ["-f", "wine"]

                let pipe = Pipe()
                task.standardOutput = pipe

                do {
                    try task.run()
                    task.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                        let pids = output.trimmingCharacters(in: .whitespacesAndNewlines)
                            .components(separatedBy: .newlines)
                            .compactMap { Int32($0) }

                        // Check each process and kill if it's consuming too much CPU
                        for pid in pids {
                            Task {
                                await self.checkAndKillHighCPUProcess(pid: pid)
                            }
                        }
                    }
                } catch {
                    // Silent fail - cleanup is best effort
                }
                continuation.resume()
            }
        }
    }

    // Kill process if it's using too much CPU
    private func checkAndKillHighCPUProcess(pid: Int32) async {
        await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/ps"
            task.arguments = ["-p", "\(pid)", "-o", "pid,pcpu"]

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    if lines.count > 1,
                        let dataLine = lines.last?.trimmingCharacters(in: .whitespaces)
                    {
                        let components = dataLine.components(separatedBy: .whitespaces)
                        if components.count >= 2, let cpuUsage = Double(components[1]),
                            cpuUsage > 50.0
                        {
                            self.logger.warning(
                                "Killing high CPU Wine process PID \(pid) with \(cpuUsage)% CPU usage"
                            )
                            kill(pid, SIGTERM)
                            // If SIGTERM doesn't work, force kill after 2 seconds
                            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                                kill(pid, SIGKILL)
                            }
                        }
                    }
                }
            } catch {
                // Silent fail
            }
            continuation.resume()
        }
    }

    // Async real-time output reading for Wine process
    func runWineProcess(
        winePath: String,
        executablePath: String,
        arguments: [String] = [],
        environment: [String: String],
        workingDirectory: String? = nil,
        defaultBottlePath: String
    ) async throws {
        // Check system resources before starting
        try await checkSystemResources()

        // Clean up any stale processes first
        await cleanupStaleProcesses()

        // Single execution - no automatic retries to prevent infinite loops
        // If components are missing, user will be notified but game won't auto-retry
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = [executablePath] + arguments

        // Use the game's directory as working directory if provided, otherwise use default bottle path
        let currentWorkingDirectory = workingDirectory ?? defaultBottlePath
        process.currentDirectoryURL = URL(fileURLWithPath: currentWorkingDirectory)

        // Set up user-writable directories for Wine (like CrossOver)
        let appSupportDir = (NSHomeDirectory() as NSString).appendingPathComponent(
            "Library/Application Support/kimiz")
        let winePrefix = (appSupportDir as NSString).appendingPathComponent(
            "gptk-bottles/default")
        let tmpDir = (appSupportDir as NSString).appendingPathComponent("tmp")
        if !fileManager.fileExists(atPath: winePrefix) {
            try? fileManager.createDirectory(
                atPath: winePrefix, withIntermediateDirectories: true, attributes: nil)
        }
        if !fileManager.fileExists(atPath: tmpDir) {
            try? fileManager.createDirectory(
                atPath: tmpDir, withIntermediateDirectories: true, attributes: nil)
        }
        var wineEnv = environment
        wineEnv["WINEPREFIX"] = winePrefix
        wineEnv["TMPDIR"] = tmpDir
        process.environment = wineEnv
        print("[WineManager] Environment for Wine: \(wineEnv)")
        print("[WineManager] Executing: \(winePath) \(executablePath)")
        print("[WineManager] Working directory: \(defaultBottlePath)")

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe

        let fileHandle = pipe.fileHandleForReading

        // Use a serial queue to synchronize continuation resume
        let resumeQueue = DispatchQueue(label: "runWineProcess.resumeQueue")
        var hasResumed = false

        try await withCheckedThrowingContinuation { continuation in
            @Sendable func safeResume(_ block: @escaping @Sendable () -> Void) {
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
                // Track active process
                let pid = process.processIdentifier
                activeProcesses.insert(pid)
                logger.info("Started Wine process PID \(pid)")

                // Set up process timeout
                Task { [weak self] in
                    guard let self = self else { return }
                    try await Task.sleep(nanoseconds: UInt64(self.processTimeout * 1_000_000_000))
                    if process.isRunning {
                        self.logger.warning(
                            "Wine process PID \(pid) timed out after \(self.processTimeout) seconds, terminating"
                        )
                        process.terminate()
                    }
                }
            } catch {
                fileHandle.readabilityHandler = nil
                safeResume { continuation.resume(throwing: error) }
                return
            }
            DispatchQueue.global().async {
                process.waitUntilExit()
                fileHandle.readabilityHandler = nil

                // Remove from active processes safely using Task
                let pid = process.processIdentifier
                Task {
                    await self.removeActiveProcess(pid)
                }

                // Log the process exit status for debugging
                let exitCode = process.terminationStatus
                print("[WineManager] Process exited with code: \(exitCode)")

                if exitCode != 0 {
                    print(
                        "[WineManager] Non-zero exit code indicates the game may have failed to start or crashed"
                    )
                    print(
                        "[WineManager] Common causes: missing dependencies, corrupted executable, or incompatible game"
                    )
                }

                safeResume { continuation.resume() }
            }
        }

        // Log completion
        let exitCode = process.terminationStatus
        if exitCode != 0 {
            print("[WineManager] Game failed with exit code \(exitCode)")
            print(
                "[WineManager] This likely indicates a Wine configuration or game compatibility issue"
            )
        } else {
            print("[WineManager] Game completed successfully")
        }
    }

    // MARK: - Performance Optimization Methods

    /// Start real-time performance monitoring to prevent CPU overload
    func startPerformanceMonitoring() async {
        logger.info("Starting performance monitoring for Wine processes")

        // Start continuous monitoring task
        Task {
            while true {
                await monitorAndOptimizeProcesses()
                try await Task.sleep(nanoseconds: 5_000_000_000)  // Check every 5 seconds
            }
        }
    }

    /// Monitor and optimize running Wine processes
    private func monitorAndOptimizeProcesses() async {
        // Get all Wine-related processes
        let wineProcesses = await getWineProcesses()

        for process in wineProcesses {
            let cpuUsage = await getProcessCPUUsage(pid: process.pid)

            // Kill processes consuming excessive CPU
            if cpuUsage > 95.0 {
                logger.warning(
                    "Terminating runaway Wine process PID \(process.pid) with \(cpuUsage)% CPU usage"
                )
                await terminateProcess(pid: process.pid, processName: process.name)
            }
            // Throttle processes with high but not excessive CPU usage
            else if cpuUsage > 70.0 {
                logger.info(
                    "Throttling Wine process PID \(process.pid) with \(cpuUsage)% CPU usage")
                await throttleProcess(pid: process.pid)
            }
        }

        // Steam-specific optimizations
        await optimizeSteamProcesses()
    }

    /// Apply Steam-specific performance optimizations
    private func optimizeSteamProcesses() async {
        let steamProcesses = await getSteamProcesses()

        for steamProcess in steamProcesses {
            // Steam has known CPU intensive background tasks that can be optimized
            switch steamProcess.name.lowercased() {
            case let name where name.contains("steamwebhelper"):
                // SteamWebHelper often causes high CPU usage
                await limitProcessCPU(pid: steamProcess.pid, maxCPU: 30.0)

            case let name where name.contains("steam.exe"):
                // Main Steam client - limit background tasks
                await configureSteamClient(pid: steamProcess.pid)

            case let name where name.contains("steamservice"):
                // Steam service processes
                await limitProcessCPU(pid: steamProcess.pid, maxCPU: 20.0)

            default:
                // Generic Steam process optimization
                let cpuUsage = await getProcessCPUUsage(pid: steamProcess.pid)
                if cpuUsage > 50.0 {
                    await limitProcessCPU(pid: steamProcess.pid, maxCPU: 40.0)
                }
            }
        }
    }

    /// Configure Steam client for optimal performance
    private func configureSteamClient(pid: Int32) async {
        logger.info("Optimizing Steam client performance for PID \(pid)")

        // Send signals to Steam to reduce background activity
        // Note: These are safe signals that don't terminate the process
        await withCheckedContinuation { continuation in
            processQueue.async {
                // Use SIGUSR1 to signal Steam to reduce background processing
                kill(pid, SIGUSR1)
                continuation.resume()
            }
        }
    }

    /// Limit process CPU usage using nice and ionice
    private func limitProcessCPU(pid: Int32, maxCPU: Double) async {
        await withCheckedContinuation { continuation in
            processQueue.async {
                // Reduce process priority to limit CPU usage
                let task = Process()
                task.launchPath = "/usr/bin/renice"
                task.arguments = ["10", "\(pid)"]  // Set to lower priority

                do {
                    try task.run()
                    task.waitUntilExit()
                    self.logger.info("Applied CPU limiting to process PID \(pid)")
                } catch {
                    self.logger.error("Failed to limit CPU for process PID \(pid): \(error)")
                }

                continuation.resume()
            }
        }
    }

    /// Throttle a process by briefly suspending and resuming it
    private func throttleProcess(pid: Int32) async {
        await withCheckedContinuation { continuation in
            processQueue.async {
                // Suspend process briefly to reduce CPU usage
                kill(pid, SIGSTOP)

                // Resume after a short delay
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    kill(pid, SIGCONT)
                    self.logger.info("Throttled process PID \(pid)")
                    continuation.resume()
                }
            }
        }
    }

    /// Safely terminate a runaway process
    private func terminateProcess(pid: Int32, processName: String) async {
        logger.warning("Terminating runaway process: \(processName) (PID: \(pid))")

        await withCheckedContinuation { continuation in
            processQueue.async {
                // Try graceful termination first
                kill(pid, SIGTERM)

                // Force kill after 3 seconds if still running
                DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                    kill(pid, SIGKILL)
                    self.logger.info("Force terminated process PID \(pid)")
                    continuation.resume()
                }
            }
        }

        // Remove from active processes if it was tracked
        if activeProcesses.contains(pid) {
            removeActiveProcess(pid)
        }
    }

    /// Get CPU usage for a specific process
    private func getProcessCPUUsage(pid: Int32) async -> Double {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/ps"
            task.arguments = ["-p", "\(pid)", "-o", "pcpu="]

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8),
                    let cpuUsage = Double(output.trimmingCharacters(in: .whitespacesAndNewlines))
                {
                    continuation.resume(returning: cpuUsage)
                } else {
                    continuation.resume(returning: 0.0)
                }
            } catch {
                continuation.resume(returning: 0.0)
            }
        }
    }

    /// Get all Wine-related processes
    private func getWineProcesses() async -> [(pid: Int32, name: String)] {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/pgrep"
            task.arguments = ["-f", "wine"]

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let pids = output.components(separatedBy: .newlines)
                        .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

                    var processes: [(pid: Int32, name: String)] = []
                    for pid in pids {
                        if let name = self.getProcessName(pid: pid) {
                            processes.append((pid: pid, name: name))
                        }
                    }
                    continuation.resume(returning: processes)
                } else {
                    continuation.resume(returning: [])
                }
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    /// Get Steam-specific processes
    private func getSteamProcesses() async -> [(pid: Int32, name: String)] {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/pgrep"
            task.arguments = ["-f", "steam"]

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let pids = output.components(separatedBy: .newlines)
                        .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

                    var processes: [(pid: Int32, name: String)] = []
                    for pid in pids {
                        if let name = self.getProcessName(pid: pid) {
                            processes.append((pid: pid, name: name))
                        }
                    }
                    continuation.resume(returning: processes)
                } else {
                    continuation.resume(returning: [])
                }
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    /// Get process name from PID
    private func getProcessName(pid: Int32) -> String? {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-p", "\(pid)", "-o", "comm="]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return nil
        }

        return nil
    }

    /// Emergency cleanup of all Wine processes
    func emergencyCleanup() async {
        logger.warning("Performing emergency cleanup of all Wine processes")

        let allWineProcesses = await getWineProcesses()
        for process in allWineProcesses {
            await terminateProcess(pid: process.pid, processName: process.name)
        }

        // Clear active processes set
        activeProcesses.removeAll()
        logger.info("Emergency cleanup completed - terminated \(allWineProcesses.count) processes")
    }

    /// Get comprehensive system performance stats
    func getPerformanceStats() async -> (
        cpuUsage: Double, wineProcessCount: Int, activeProcessCount: Int
    ) {
        let cpuUsage = await getCurrentCPUUsage()
        let wineProcesses = await getWineProcesses()

        return (
            cpuUsage: cpuUsage,
            wineProcessCount: wineProcesses.count,
            activeProcessCount: activeProcesses.count
        )
    }
}
