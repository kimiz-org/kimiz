//
//  PerformanceView.swift
//  kimiz
//
//  Created by GitHub Copilot on 6.06.2025.
//

import SwiftUI

struct PerformanceView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var cpuUsage: Double = 0.0
    @State private var memoryUsage: Double = 0.0
    @State private var wineProcessCount: Int = 0
    @State private var activeProcessCount: Int = 0
    @State private var isMonitoring = false
    @State private var performanceHistory: [PerformanceData] = []
    @State private var showingPerformanceSettings = false

    private let maxHistoryPoints = 60  // 1 minute of data at 1s intervals

    struct PerformanceData: Identifiable {
        let id = UUID()
        let timestamp: Date
        let cpuUsage: Double
        let memoryUsage: Double
        let processCount: Int
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView

                // Real-time Metrics
                realTimeMetricsSection

                // Performance Chart
                performanceChartSection

                // Process Management
                processManagementSection

                // Optimization Tools
                optimizationToolsSection

                // System Information
                systemInformationSection
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingPerformanceSettings) {
            PerformanceSettingsView()
        }
        .onAppear {
            startInitialDataCollection()
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Monitor")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Monitor Wine processes and system performance")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Monitoring Status
                HStack(spacing: 12) {
                    Circle()
                        .fill(isMonitoring ? .green : .gray)
                        .frame(width: 12, height: 12)

                    Text(isMonitoring ? "Monitoring" : "Stopped")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(Capsule())
            }
        }
    }

    private var realTimeMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Real-time Metrics")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                MetricCard(
                    title: "CPU Usage",
                    value: "\(Int(cpuUsage))%",
                    subtitle: "System CPU",
                    color: cpuUsage > 80 ? .red : cpuUsage > 60 ? .orange : .green,
                    icon: "cpu"
                )

                MetricCard(
                    title: "Memory Usage",
                    value: "\(Int(memoryUsage))%",
                    subtitle: "System RAM",
                    color: memoryUsage > 80 ? .red : memoryUsage > 60 ? .orange : .green,
                    icon: "memorychip"
                )

                MetricCard(
                    title: "Wine Processes",
                    value: "\(wineProcessCount)",
                    subtitle: "Running",
                    color: wineProcessCount > 5 ? .orange : .blue,
                    icon: "process"
                )

                MetricCard(
                    title: "Active Games",
                    value: "\(activeProcessCount)",
                    subtitle: "Currently playing",
                    color: .purple,
                    icon: "gamecontroller"
                )
            }
        }
    }

    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance History")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Settings") {
                    showingPerformanceSettings = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            VStack(spacing: 12) {
                // Simple chart representation
                ChartView(data: performanceHistory)
                    .frame(height: 200)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Label("CPU", systemImage: "cpu")
                        .foregroundColor(.blue)

                    Spacer()

                    Label("Memory", systemImage: "memorychip")
                        .foregroundColor(.green)

                    Spacer()

                    Label("Processes", systemImage: "process")
                        .foregroundColor(.orange)

                    Spacer()
                }
                .font(.caption)
            }
        }
    }

    private var processManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Process Management")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ProcessManagementCard(
                    title: "Kill All GPTK Processes",
                    description: "Terminate all running Game Porting Toolkit processes",
                    icon: "stop.circle",
                    color: .red,
                    action: "Kill All"
                ) {
                    killAllGPTKProcesses()
                }

                ProcessManagementCard(
                    title: "Restart GPTK Services",
                    description: "Restart Game Porting Toolkit background services",
                    icon: "arrow.clockwise.circle",
                    color: .blue,
                    action: "Restart"
                ) {
                    restartWineServices()
                }

                ProcessManagementCard(
                    title: "Clean Zombie Processes",
                    description: "Remove stale and unresponsive Wine processes",
                    icon: "trash.circle",
                    color: .orange,
                    action: "Clean"
                ) {
                    cleanZombieProcesses()
                }
            }
        }
    }

    private var optimizationToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Optimization")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 12) {
                OptimizationCard(
                    title: "CPU Throttling",
                    description: "Limit CPU usage for Wine processes",
                    icon: "cpu",
                    isEnabled: true
                ) {
                    toggleCPUThrottling()
                }

                OptimizationCard(
                    title: "Memory Optimization",
                    description: "Optimize memory usage for games",
                    icon: "memorychip",
                    isEnabled: false
                ) {
                    toggleMemoryOptimization()
                }

                OptimizationCard(
                    title: "Process Priority",
                    description: "Adjust process priorities for better performance",
                    icon: "arrow.up.circle",
                    isEnabled: true
                ) {
                    adjustProcessPriority()
                }

                OptimizationCard(
                    title: "Background Cleanup",
                    description: "Automatically clean up idle processes",
                    icon: "trash",
                    isEnabled: false
                ) {
                    toggleBackgroundCleanup()
                }
            }
        }
    }

    private var systemInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Information")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                SystemInfoRow(
                    label: "macOS Version",
                    value: ProcessInfo.processInfo.operatingSystemVersionString)
                SystemInfoRow(label: "Processor", value: getProcessorName())
                SystemInfoRow(label: "Total Memory", value: getTotalMemory())
                SystemInfoRow(label: "Wine Version", value: getWineVersion())
                SystemInfoRow(
                    label: "GPTK Status",
                    value: gamePortingToolkitManager.isGPTKInstalled ? "Installed" : "Not Installed"
                )
                SystemInfoRow(
                    label: "Active Bottles", value: "\(gamePortingToolkitManager.bottles.count)")
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helper Functions

    private func startInitialDataCollection() {
        collectPerformanceData()
    }

    private func toggleMonitoring() {
        isMonitoring.toggle()

        if isMonitoring {
            startPerformanceMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard isMonitoring else { return }
            collectPerformanceData()
        }
    }

    private func stopMonitoring() {
        isMonitoring = false
    }

    private func collectPerformanceData() {
        Task {
            // Simulate performance data collection
            let newCPU = Double.random(in: 10...90)
            let newMemory = Double.random(in: 20...80)
            let newProcessCount = Int.random(in: 0...8)
            let newActiveCount = Int.random(in: 0...3)

            await MainActor.run {
                cpuUsage = newCPU
                memoryUsage = newMemory
                wineProcessCount = newProcessCount
                activeProcessCount = newActiveCount

                // Add to history
                let dataPoint = PerformanceData(
                    timestamp: Date(),
                    cpuUsage: newCPU,
                    memoryUsage: newMemory,
                    processCount: newProcessCount
                )

                performanceHistory.append(dataPoint)

                // Keep only recent data
                if performanceHistory.count > maxHistoryPoints {
                    performanceHistory.removeFirst()
                }
            }
        }
    }

    private func killAllWineProcesses() {
        Task {
            await WineManager.shared.emergencyCleanup()
            collectPerformanceData()
        }
    }

    private func killAllGPTKProcesses() {
        Task {
            await WineManager.shared.emergencyCleanup()
            collectPerformanceData()
        }
    }

    private func restartWineServices() {
        print("Restarting Wine services...")
        // Implement Wine service restart
    }

    private func cleanZombieProcesses() {
        print("Cleaning zombie processes...")
        // Implement zombie process cleanup
    }

    private func toggleCPUThrottling() {
        print("Toggling CPU throttling...")
    }

    private func toggleMemoryOptimization() {
        print("Toggling memory optimization...")
    }

    private func adjustProcessPriority() {
        print("Adjusting process priority...")
    }

    private func toggleBackgroundCleanup() {
        print("Toggling background cleanup...")
    }

    private func getProcessorName() -> String {
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    private func getTotalMemory() -> String {
        let memory = ProcessInfo.processInfo.physicalMemory
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memory))
    }

    private func getWineVersion() -> String {
        // Implement Wine version detection
        return "8.0 (Staging)"
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)

                Spacer()

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ChartView: View {
    let data: [PerformanceView.PerformanceData]

    var body: some View {
        ZStack {
            if data.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("No performance data")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Start monitoring to see real-time charts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Simple line chart placeholder
                VStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { index in
                        HStack(spacing: 2) {
                            ForEach(0..<20, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.blue.opacity(Double.random(in: 0.2...0.8)))
                                    .frame(width: 8, height: Double.random(in: 4...40))
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ProcessManagementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action) {
                onAction()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(color)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct OptimizationCard: View {
    let title: String
    let description: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isEnabled ? .green : .gray)

                    Spacer()

                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(isEnabled ? .green : .gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isEnabled ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct SystemInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

struct PerformanceSettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Performance Settings")
                .font(.headline)

            Text("Performance monitoring settings will be available here.")
                .foregroundColor(.secondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    PerformanceView()
        .environmentObject(GamePortingToolkitManager.shared)
}
