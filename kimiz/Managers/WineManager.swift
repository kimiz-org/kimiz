import Foundation

actor WineManager {
    static let shared = WineManager()
    private let fileManager = FileManager.default
    private let defaultBottlePath: String = NSString(
        string: "~/Library/Application Support/kimiz/gptk-bottles/default"
    ).expandingTildeInPath

    // Helper to detect missing component from Wine output
    func detectMissingComponent(from output: String) -> String? {
        let patterns = [
            ("directx 11", "directx11"),
            ("directx 12", "directx12"),
            ("vcruntime140", "vcrun2015"),
            ("vcruntime", "vcrun2015"),
            ("d3dcompiler", "d3dcompiler_47"),
            ("dotnet", "dotnet48"),
            ("dxgi", "dxvk"),
            ("vulkan", "vulkan"),
        ]
        for (pattern, component) in patterns {
            if output.localizedCaseInsensitiveContains(pattern) {
                return component
            }
        }
        return nil
    }

    // Async real-time output reading for Wine process
    func runWineProcess(
        winePath: String,
        executablePath: String,
        environment: [String: String],
        defaultBottlePath: String,
        onMissingComponent: @escaping (String) -> Void
    ) async throws {
        var shouldRetry = true
        while shouldRetry {
            shouldRetry = false
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winePath)
            process.arguments = [executablePath]
            process.currentDirectoryURL = URL(fileURLWithPath: defaultBottlePath)

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

            let pipe = Pipe()
            process.standardError = pipe
            process.standardOutput = pipe

            let fileHandle = pipe.fileHandleForReading
            // Use an actor to safely store detectedComponent in concurrent context
            actor DetectedComponentBox {
                var value: String? = nil
                func set(_ newValue: String) async {
                    value = newValue
                }
                func get() async -> String? {
                    return value
                }
            }
            let detectedComponentBox = DetectedComponentBox()

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
                        Task {
                            let current = await detectedComponentBox.get()
                            if current == nil,
                                let component = await self.detectMissingComponent(from: str)
                            {
                                await detectedComponentBox.set(component)
                                onMissingComponent(component)
                            }
                        }
                    }
                }
                do {
                    try process.run()
                } catch {
                    fileHandle.readabilityHandler = nil
                    safeResume { continuation.resume(throwing: error) }
                    return
                }
                DispatchQueue.global().async {
                    process.waitUntilExit()
                    fileHandle.readabilityHandler = nil
                    safeResume { continuation.resume() }
                }
            }
            // After process finishes, check if a missing component was detected
            let missingComponent = await detectedComponentBox.get()
            if missingComponent != nil {
                shouldRetry = true
            }
        }
    }
}
