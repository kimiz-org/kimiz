//
//  WineEnvironment.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Foundation

enum WineBackend: String, CaseIterable, Hashable {
    case embedded = "Embedded Wine"
    case wine = "Wine"
    case crossover = "CrossOver"
    case gamePortingToolkit = "Game Porting Toolkit"

    var displayName: String { rawValue }

    var executablePath: String {
        switch self {
        case .embedded:
            // Wine bundled within the app
            let bundlePath = Bundle.main.bundlePath
            return "\(bundlePath)/Contents/Resources/wine/bin/wine"
        case .wine:
            // Check for Wine in multiple locations
            let paths = [
                "/usr/local/bin/wine64",  // Intel Homebrew
                "/opt/homebrew/bin/wine64",  // Apple Silicon Homebrew
                "/usr/local/bin/wine",  // Alternative
                "/opt/homebrew/bin/wine",  // Alternative
            ]
            for path in paths {
                if FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
            return "/usr/local/bin/wine64"  // Default fallback
        case .crossover:
            return "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
        case .gamePortingToolkit:
            return "/usr/local/bin/wine64"
        }
    }

    var prefixPath: String {
        switch self {
        case .embedded:
            return "~/Library/Application Support/kimiz/wine-prefixes"
        case .wine:
            return "~/.wine"
        case .crossover:
            return "~/Library/Application Support/CrossOver/Bottles"
        case .gamePortingToolkit:
            return "~/Library/Application Support/kimiz/gptk-bottles"
        }
    }

    var isEmbedded: Bool {
        return self == .embedded
    }
}

struct WinePrefix: Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let backend: WineBackend
    let windowsVersion: String
    let architecture: String
    let createdDate: Date
    var lastUsed: Date
    var isDefault: Bool

    init(
        name: String, backend: WineBackend, windowsVersion: String = "win10",
        architecture: String = "win64"
    ) {
        self.id = UUID()
        self.name = name
        self.backend = backend
        self.windowsVersion = windowsVersion
        self.architecture = architecture
        self.createdDate = Date()
        self.lastUsed = Date()
        self.isDefault = false

        let expandedPath = NSString(string: backend.prefixPath).expandingTildeInPath
        self.path = "\(expandedPath)/\(name)"
    }
}

struct GameInstallation: Identifiable {
    let id: UUID
    let name: String
    let executablePath: String
    let winePrefix: WinePrefix
    let installPath: String
    let icon: Data?
    var lastPlayed: Date?
    var playTime: TimeInterval
    var isInstalled: Bool

    init(name: String, executablePath: String, winePrefix: WinePrefix, installPath: String) {
        self.id = UUID()
        self.name = name
        self.executablePath = executablePath
        self.winePrefix = winePrefix
        self.installPath = installPath
        self.icon = nil
        self.lastPlayed = nil
        self.playTime = 0
        self.isInstalled = false
    }
}

enum WineError: LocalizedError {
    case prefixCreationFailed(String)
    case executionFailed(String)
    case installationFailed(String)
    case commandFailed(String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .prefixCreationFailed(let message):
            return "Wine Prefix Creation Failed: \(message)"
        case .executionFailed(let message):
            return "Execution Failed: \(message)"
        case .installationFailed(let message):
            return "Installation Failed: \(message)"
        case .commandFailed(let output):
            return "Wine command failed: \(output)"
        case .invalidURL:
            return "Invalid download URL"
        }
    }
}
