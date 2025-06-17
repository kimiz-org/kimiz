//
//  PerformanceMonitor.swift
//  kimiz
//
//  Created by System on June 10, 2025.
//
//  Real-time performance monitoring for GPTK processes
//

import Foundation
import SwiftUI
import os.log

@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    // MARK: - Published Properties
    @Published var isMonitoring = false
    @Published var systemCPU: Double = 0.0
    @Published var systemMemory: Double = 0.0
    @Published var gpuUsage: Double = 0.0
    @Published var activeProcesses: [ProcessInfo] = []
    @Published var performanceHistory: [PerformanceSnapshot] = []
    @Published var alerts: [PerformanceAlert] = []

    // MARK: - Configuration
    @Published var cpuThreshold: Double = 95.0  // Increased from 80%
    @Published var memoryThreshold: Double = 90.0  // Increased from 85%
    @Published var enableAutoOptimization = true
    @Published var enableAlerts = true
    @Published var monitoringInterval: TimeInterval = 2.0

    private let logger = Logger(subsystem: "dev.kimiz.performance", category: "monitor")
    private var monitoringTimer: Timer?
    private let maxHistorySize = 300  // 10 minutes at 2-second intervals

    struct ProcessInfo: Identifiable {
        let id = UUID()
        let pid: Int32
        let name: String
        let cpuUsage: Double
        let memoryUsage: Int64  // in bytes
        let isWineProcess: Bool
        let isGPTKProcess: Bool
    }

    struct PerformanceSnapshot: Identifiable {
        let id = UUID()
        let timestamp: Date
        let systemCPU: Double
        let systemMemory: Double
        let gpuUsage: Double
        let activeProcessCount: Int
        let wineProcessCount: Int
    }

    struct PerformanceAlert: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: AlertType
        let message: String
        let severity: Severity

        enum AlertType {
            case highCPU, highMemory, processLimit, processCrash, optimization
        }

        enum Severity {
            case info, warning, critical

            var color: Color {
                switch self {
                case .info: return .blue
                case .warning: return .orange
                case .critical: return .red
                }
            }
        }
    }

    private init() {}

    // MARK: - Monitoring Control

    func startMonitoring() {
        guard !isMonitoring else { return }

        logger.info("Starting performance monitoring")
        isMonitoring = true

        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true)
        { _ in
            Task { @MainActor in
                await self.updatePerformanceMetrics()
            }
        }

        // Initial update
        Task {
            await updatePerformanceMetrics()
        }
    }

    func stopMonitoring() {
        logger.info("Stopping performance monitoring")
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    func clearHistory() {
        performanceHistory.removeAll()
        alerts.removeAll()
    }

    // MARK: - Performance Metrics Collection

    private func updatePerformanceMetrics() async {
        let snapshot = await collectPerformanceSnapshot()

        // Update published properties
        systemCPU = snapshot.systemCPU
        systemMemory = snapshot.systemMemory
        gpuUsage = snapshot.gpuUsage
        activeProcesses = await getActiveProcesses()

        // Add to history
        performanceHistory.append(snapshot)
        if performanceHistory.count > maxHistorySize {
            performanceHistory.removeFirst()
        }

        // Check for alerts
        if enableAlerts {
            await checkPerformanceAlerts(snapshot: snapshot)
        }

        // Auto-optimization
        if enableAutoOptimization {
            await performAutoOptimization(snapshot: snapshot)
        }
    }

    private func collectPerformanceSnapshot() async -> PerformanceSnapshot {
        let cpu = await getCurrentCPUUsage()
        let memory = await getCurrentMemoryUsage()
        let gpu = await getCurrentGPUUsage()
        let processes = await getActiveProcesses()
        let wineProcesses = processes.filter { $0.isWineProcess || $0.isGPTKProcess }

        return PerformanceSnapshot(
            timestamp: Date(),
            systemCPU: cpu,
            systemMemory: memory,
            gpuUsage: gpu,
            activeProcessCount: processes.count,
            wineProcessCount: wineProcesses.count
        )
    }

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
                            // Parse CPU usage from line like "CPU usage: 12.34% user, 5.67% sys, 81.99% idle"
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

    private func getCurrentMemoryUsage() async -> Double {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/vm_stat"

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    var pageSize: Double = 4096  // Default page size
                    var freePages: Double = 0
                    var inactivePages: Double = 0
                    var wirePages: Double = 0
                    var activePages: Double = 0

                    for line in lines {
                        if line.contains("page size of") {
                            let components = line.components(separatedBy: .whitespaces)
                            if let pageSizeIndex = components.firstIndex(of: "of"),
                                pageSizeIndex + 1 < components.count
                            {
                                pageSize = Double(components[pageSizeIndex + 1]) ?? 4096
                            }
                        } else if line.contains("Pages free:") {
                            let numbers = line.components(separatedBy: .whitespaces)
                                .compactMap { Double($0.replacingOccurrences(of: ".", with: "")) }
                            freePages = numbers.first ?? 0
                        } else if line.contains("Pages inactive:") {
                            let numbers = line.components(separatedBy: .whitespaces)
                                .compactMap { Double($0.replacingOccurrences(of: ".", with: "")) }
                            inactivePages = numbers.first ?? 0
                        } else if line.contains("Pages wired down:") {
                            let numbers = line.components(separatedBy: .whitespaces)
                                .compactMap { Double($0.replacingOccurrences(of: ".", with: "")) }
                            wirePages = numbers.first ?? 0
                        } else if line.contains("Pages active:") {
                            let numbers = line.components(separatedBy: .whitespaces)
                                .compactMap { Double($0.replacingOccurrences(of: ".", with: "")) }
                            activePages = numbers.first ?? 0
                        }
                    }

                    let totalPages = freePages + inactivePages + wirePages + activePages
                    let usedPages = wirePages + activePages
                    let memoryUsage = totalPages > 0 ? (usedPages / totalPages) * 100 : 0

                    continuation.resume(returning: memoryUsage)
                } else {
                    continuation.resume(returning: 0.0)
                }
            } catch {
                continuation.resume(returning: 0.0)
            }
        }
    }

    private func getCurrentGPUUsage() async -> Double {
        // GPU usage monitoring on macOS is complex and requires Metal Performance Shaders
        // For now, return a placeholder value
        // In a real implementation, you'd use Metal or IOKit to get GPU metrics
        return 0.0
    }

    private func getActiveProcesses() async -> [ProcessInfo] {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/ps"
            task.arguments = ["-ax", "-o", "pid,pcpu,rss,comm"]

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    var processes: [ProcessInfo] = []

                    for line in lines.dropFirst() {  // Skip header
                        let components = line.trimmingCharacters(in: .whitespaces)
                            .components(separatedBy: .whitespaces)

                        if components.count >= 4,
                            let pid = Int32(components[0]),
                            let cpu = Double(components[1]),
                            let memoryKB = Int64(components[2])
                        {

                            let processName = components[3...].joined(separator: " ")
                            let isWine = processName.lowercased().contains("wine")
                            let isGPTK =
                                processName.lowercased().contains("gptk")
                                || processName.lowercased().contains("game-porting-toolkit")

                            // Only track processes with significant resource usage or Wine/GPTK processes
                            if cpu > 1.0 || memoryKB > 50000 || isWine || isGPTK {
                                let process = ProcessInfo(
                                    pid: pid,
                                    name: processName,
                                    cpuUsage: cpu,
                                    memoryUsage: memoryKB * 1024,  // Convert to bytes
                                    isWineProcess: isWine,
                                    isGPTKProcess: isGPTK
                                )
                                processes.append(process)
                            }
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

    // MARK: - Performance Alerts

    private func checkPerformanceAlerts(snapshot: PerformanceSnapshot) async {
        // CPU threshold alert
        if snapshot.systemCPU > cpuThreshold {
            addAlert(
                type: .highCPU,
                message: "High CPU usage detected: \(String(format: "%.1f", snapshot.systemCPU))%",
                severity: snapshot.systemCPU > 90 ? .critical : .warning
            )
        }

        // Memory threshold alert
        if snapshot.systemMemory > memoryThreshold {
            addAlert(
                type: .highMemory,
                message:
                    "High memory usage detected: \(String(format: "%.1f", snapshot.systemMemory))%",
                severity: snapshot.systemMemory > 95 ? .critical : .warning
            )
        }

        // Too many Wine processes
        if snapshot.wineProcessCount > 10 {
            addAlert(
                type: .processLimit,
                message: "High number of Wine processes: \(snapshot.wineProcessCount)",
                severity: .warning
            )
        }
    }

    private func addAlert(
        type: PerformanceAlert.AlertType, message: String, severity: PerformanceAlert.Severity
    ) {
        let alert = PerformanceAlert(
            timestamp: Date(),
            type: type,
            message: message,
            severity: severity
        )

        alerts.insert(alert, at: 0)  // Add to beginning

        // Limit alert history
        if alerts.count > 50 {
            alerts.removeLast()
        }

        logger.log(level: severity == .critical ? .error : .info, "\(message)")
    }

    // MARK: - Auto-Optimization

    private func performAutoOptimization(snapshot: PerformanceSnapshot) async {
        // High CPU usage optimization
        if snapshot.systemCPU > cpuThreshold {
            await optimizeHighCPUUsage()
        }

        // High memory usage optimization
        if snapshot.systemMemory > memoryThreshold {
            await optimizeHighMemoryUsage()
        }

        // Too many processes optimization
        if snapshot.wineProcessCount > 8 {
            await optimizeProcessCount()
        }
    }

    private func optimizeHighCPUUsage() async {
        logger.info("Performing CPU optimization")

        // Find high CPU Wine processes and throttle them
        let highCPUProcesses = activeProcesses.filter {
            ($0.isWineProcess || $0.isGPTKProcess) && $0.cpuUsage > 50.0
        }

        for process in highCPUProcesses {
            await throttleProcess(pid: process.pid)
        }

        if !highCPUProcesses.isEmpty {
            addAlert(
                type: .optimization,
                message: "Automatically throttled \(highCPUProcesses.count) high-CPU processes",
                severity: .info
            )
        }
    }

    private func optimizeHighMemoryUsage() async {
        logger.info("Performing memory optimization")

        // Clear system caches
        let task = Process()
        task.launchPath = "/usr/bin/purge"

        do {
            try task.run()
            task.waitUntilExit()

            addAlert(
                type: .optimization,
                message: "Cleared system memory caches",
                severity: .info
            )
        } catch {
            logger.error("Failed to purge memory: \(error.localizedDescription)")
        }
    }

    private func optimizeProcessCount() async {
        logger.info("Performing process count optimization")

        // Find non-essential Wine processes and terminate them
        let nonEssentialProcesses = activeProcesses.filter { process in
            let name = process.name.lowercased()
            return (process.isWineProcess || process.isGPTKProcess)
                && (name.contains("winedevice") || name.contains("plugplay")
                    || name.contains("services"))
        }

        for process in nonEssentialProcesses {
            await terminateProcess(pid: process.pid)
        }

        if !nonEssentialProcesses.isEmpty {
            addAlert(
                type: .optimization,
                message: "Terminated \(nonEssentialProcesses.count) non-essential processes",
                severity: .info
            )
        }
    }

    private func throttleProcess(pid: Int32) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                // Use nice to reduce process priority
                let task = Process()
                task.launchPath = "/usr/bin/renice"
                task.arguments = ["10", "\(pid)"]

                do {
                    try task.run()
                    task.waitUntilExit()
                } catch {
                    // Silent failure
                }

                continuation.resume()
            }
        }
    }

    private func terminateProcess(pid: Int32) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                kill(pid, SIGTERM)
                continuation.resume()
            }
        }
    }

    // MARK: - Performance Statistics

    func getPerformanceStats() -> PerformanceStats {
        let recentSnapshots = Array(performanceHistory.suffix(30))  // Last minute

        let avgCPU =
            recentSnapshots.isEmpty
            ? 0 : recentSnapshots.map(\.systemCPU).reduce(0, +) / Double(recentSnapshots.count)
        let avgMemory =
            recentSnapshots.isEmpty
            ? 0 : recentSnapshots.map(\.systemMemory).reduce(0, +) / Double(recentSnapshots.count)
        let maxCPU = recentSnapshots.map(\.systemCPU).max() ?? 0
        let maxMemory = recentSnapshots.map(\.systemMemory).max() ?? 0

        return PerformanceStats(
            averageCPU: avgCPU,
            averageMemory: avgMemory,
            maxCPU: maxCPU,
            maxMemory: maxMemory,
            totalAlerts: alerts.count,
            criticalAlerts: alerts.filter { $0.severity == .critical }.count,
            activeProcessCount: activeProcesses.count,
            wineProcessCount: activeProcesses.filter { $0.isWineProcess || $0.isGPTKProcess }.count
        )
    }

    struct PerformanceStats {
        let averageCPU: Double
        let averageMemory: Double
        let maxCPU: Double
        let maxMemory: Double
        let totalAlerts: Int
        let criticalAlerts: Int
        let activeProcessCount: Int
        let wineProcessCount: Int
    }
}
