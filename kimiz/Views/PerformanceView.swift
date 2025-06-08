//
//  PerformanceView.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
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
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Modern header
                    modernHeaderView

                    // Performance Dashboard
                    performanceDashboard

                    // Real-time Charts
                    chartsSection

                    // Process Management
                    modernProcessSection

                    // Optimization Tools
                    modernOptimizationSection

                    // System Information
                    modernSystemInfoSection
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
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

    private var modernHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
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

                    Text("Monitor Wine processes and system performance in real-time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Control buttons
                HStack(spacing: 12) {
                    Button {
                        showingPerformanceSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        if isMonitoring {
                            stopMonitoring()
                        } else {
                            startMonitoring()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(
                                systemName: isMonitoring ? "pause.circle.fill" : "play.circle.fill"
                            )
                            .font(.system(size: 14, weight: .medium))
                            Text(isMonitoring ? "Pause" : "Start")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isMonitoring ? .orange : .green)
                }
            }

            // Status indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(isMonitoring ? .green : .gray)
                    .frame(width: 8, height: 8)

                Text(isMonitoring ? "Monitoring Active" : "Monitoring Paused")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                if isMonitoring {
                    Text("• \(performanceHistory.count)/\(maxHistoryPoints) data points")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var performanceDashboard: some View {
        ModernSectionView(title: "System Overview", icon: "speedometer") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 20
            ) {
                ModernStatisticsCard(
                    title: "CPU Usage",
                    value: "\(Int(cpuUsage))%",
                    subtitle: cpuUsage > 80 ? "High usage detected" : "Normal operation",
                    icon: "cpu",
                    trend: cpuUsage > 80 ? .up : cpuUsage < 30 ? .down : .neutral,
                    accentColor: .blue
                )

                ModernStatisticsCard(
                    title: "Memory Usage",
                    value: "\(Int(memoryUsage))%",
                    subtitle: memoryUsage > 80 ? "Consider closing apps" : "Memory available",
                    icon: "memorychip",
                    trend: memoryUsage > 80 ? .up : memoryUsage < 50 ? .down : .neutral,
                    accentColor: .green
                )

                ModernStatisticsCard(
                    title: "Wine Processes",
                    value: "\(wineProcessCount)",
                    subtitle: wineProcessCount > 0 ? "Wine is active" : "No Wine processes",
                    icon: "gearshape.2.fill",
                    accentColor: .orange
                )

                ModernStatisticsCard(
                    title: "Active Games",
                    value: "\(activeProcessCount)",
                    subtitle: activeProcessCount > 0 ? "Games running" : "No active games",
                    icon: "gamecontroller.fill",
                    accentColor: .purple
                )
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

    // MARK: - Missing Sections

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Charts")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Real-time system metrics and performance history")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 16) {
                // Chart view with glassmorphism background
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        ChartView(data: performanceHistory)
                            .padding(20)
                    )
                    .frame(height: 240)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    )

                // Chart legend
                HStack(spacing: 24) {
                    ChartLegendItem(color: .blue, label: "CPU Usage")
                    ChartLegendItem(color: .green, label: "Memory")
                    ChartLegendItem(color: .orange, label: "Processes")

                    Spacer()

                    Text("\(performanceHistory.count) data points")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary.opacity(0.2), lineWidth: 1)
        )
    }

    private var modernProcessSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Process Management")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Monitor and control Wine and GPTK processes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 16) {
                ModernProcessActionCard(
                    title: "Kill All GPTK Processes",
                    description: "Terminate all running Game Porting Toolkit processes",
                    icon: "stop.circle.fill",
                    color: .red,
                    action: killAllGPTKProcesses
                )

                ModernProcessActionCard(
                    title: "Restart Wine Services",
                    description: "Restart Game Porting Toolkit background services",
                    icon: "arrow.clockwise.circle.fill",
                    color: .blue,
                    action: restartWineServices
                )

                ModernProcessActionCard(
                    title: "Clean Zombie Processes",
                    description: "Remove stale and unresponsive Wine processes",
                    icon: "trash.circle.fill",
                    color: .orange,
                    action: cleanZombieProcesses
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary.opacity(0.2), lineWidth: 1)
        )
    }

    private var modernOptimizationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Optimization")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Configure system optimizations for better gaming performance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ModernOptimizationToggle(
                    title: "CPU Throttling",
                    description: "Limit CPU usage for Wine processes",
                    icon: "cpu",
                    isEnabled: true,
                    action: toggleCPUThrottling
                )

                ModernOptimizationToggle(
                    title: "Memory Optimization",
                    description: "Optimize memory usage for games",
                    icon: "memorychip",
                    isEnabled: false,
                    action: toggleMemoryOptimization
                )

                ModernOptimizationToggle(
                    title: "Process Priority",
                    description: "Adjust process priorities for better performance",
                    icon: "arrow.up.circle",
                    isEnabled: true,
                    action: adjustProcessPriority
                )

                ModernOptimizationToggle(
                    title: "Background Cleanup",
                    description: "Automatically clean up idle processes",
                    icon: "trash",
                    isEnabled: false,
                    action: toggleBackgroundCleanup
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary.opacity(0.2), lineWidth: 1)
        )
    }

    private var modernSystemInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Information")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Current system status and configuration details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 12) {
                ModernSystemInfoRow(
                    label: "macOS Version",
                    value: ProcessInfo.processInfo.operatingSystemVersionString,
                    icon: "apple.logo"
                )

                ModernSystemInfoRow(
                    label: "Processor",
                    value: getProcessorName(),
                    icon: "cpu"
                )

                ModernSystemInfoRow(
                    label: "Total Memory",
                    value: getTotalMemory(),
                    icon: "memorychip"
                )

                ModernSystemInfoRow(
                    label: "Wine Version",
                    value: getWineVersion(),
                    icon: "wineglass"
                )

                ModernSystemInfoRow(
                    label: "GPTK Status",
                    value: gamePortingToolkitManager.isGPTKInstalled
                        ? "Installed" : "Not Installed",
                    icon: "gamecontroller"
                )

                ModernSystemInfoRow(
                    label: "Active Bottles",
                    value: "\(gamePortingToolkitManager.bottles.count)",
                    icon: "server.rack"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Helper Functions

    private func startInitialDataCollection() {
        collectPerformanceData()
    }

    private func startMonitoring() {
        isMonitoring = true
        startPerformanceMonitoring()
    }

    private func calculateTrend(for keyPath: KeyPath<PerformanceData, Double>)
        -> PerformanceMetricCard.TrendDirection
    {
        guard performanceHistory.count >= 2 else { return .stable }

        let recent = performanceHistory.suffix(5)
        if recent.count < 2 { return .stable }

        let values = recent.map { $0[keyPath: keyPath] }
        let sum = values.reduce(0, +)
        let average = sum / Double(values.count)

        if let lastValue = values.last {
            if lastValue > average * 1.1 {
                return .up
            } else if lastValue < average * 0.9 {
                return .down
            }
        }
        return .stable
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

    private func killAllGPTKProcesses() {
        Task {
            // Implementation placeholder - remove WineManager reference for now
            print("Emergency cleanup requested")
            collectPerformanceData()
        }
    }

    private func restartWineServices() {
        Task {
            // Implementation placeholder - remove WineManager reference for now
            print("Restarting Wine services...")
        }
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

// MARK: - Performance Metric Card Component

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection

    enum TrendDirection {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)

                Spacer()

                Image(systemName: trend.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(trend.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Components

struct ChartLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct ModernProcessActionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // Action button
            Button(action: action) {
                Text("Execute")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ModernOptimizationToggle: View {
    let title: String
    let description: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isEnabled ? .green : .gray)

                    Spacer()

                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(isEnabled ? .green : .gray)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isEnabled ? Color.green.opacity(0.3) : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModernSystemInfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    PerformanceView()
        .environmentObject(GamePortingToolkitManager.shared)
}
