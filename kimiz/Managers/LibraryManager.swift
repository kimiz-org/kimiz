//
//  LibraryManager.swift
//  kimiz
//
//  Created by temidaradev on 7.06.2025.
//

import Foundation
import SwiftUI

// Known important executables and their typical locations
struct ExecutableInfo {
    let name: String
    let patterns: [String]
    let searchPaths: [String]
    let category: ExecutableCategory
}

enum ExecutableCategory {
    case launcher
    case game
    case tool
}

@MainActor
internal class LibraryManager: ObservableObject {
    internal static let shared = LibraryManager()

    @Published var discoveredGames: [Game] = []
    @Published var isScanning: Bool = false
    @Published var lastScanDate: Date?

    private let fileManager = FileManager.default

    // Known important executables and their typical locations
    private let importantExecutables = [
        ExecutableInfo(
            name: "Steam",
            patterns: [
                "steam.exe",
                "Steam.exe",
            ],
            searchPaths: [
                "Program Files (x86)/Steam",
                "Program Files/Steam",
            ],
            category: .launcher
        ),
        ExecutableInfo(
            name: "Epic Games Launcher",
            patterns: [
                "EpicGamesLauncher.exe",
                "UnrealEngineLauncher.exe",
            ],
            searchPaths: [
                "Program Files (x86)/Epic Games/Launcher/Portal/Binaries/Win32",
                "Program Files (x86)/Epic Games/Launcher/Portal/Binaries/Win64",
                "Program Files/Epic Games/Launcher/Portal/Binaries/Win32",
                "Program Files/Epic Games/Launcher/Portal/Binaries/Win64",
                "Program Files (x86)/Epic Games/Launcher/Engine/Binaries/Win32",
                "Program Files (x86)/Epic Games/Launcher/Engine/Binaries/Win64",
                "Program Files/Epic Games/Launcher/Engine/Binaries/Win32",
                "Program Files/Epic Games/Launcher/Engine/Binaries/Win64",
                "Program Files (x86)/Epic Games/Launcher",
                "Program Files/Epic Games/Launcher",
            ],
            category: .launcher
        ),
        ExecutableInfo(
            name: "Battle.net",
            patterns: [
                "Battle.net.exe",
                "Battle.net Launcher.exe",
            ],
            searchPaths: [
                "Program Files (x86)/Battle.net",
                "Program Files/Battle.net",
            ],
            category: .launcher
        ),
        ExecutableInfo(
            name: "Origin",
            patterns: [
                "Origin.exe",
                "OriginClient.exe",
            ],
            searchPaths: [
                "Program Files (x86)/Origin",
                "Program Files/Origin",
            ],
            category: .launcher
        ),
        ExecutableInfo(
            name: "Ubisoft Connect",
            patterns: [
                "UbisoftConnect.exe",
                "Uplay.exe",
            ],
            searchPaths: [
                "Program Files (x86)/Ubisoft/Ubisoft Game Launcher",
                "Program Files/Ubisoft/Ubisoft Game Launcher",
            ],
            category: .launcher
        ),
        ExecutableInfo(
            name: "GOG Galaxy",
            patterns: [
                "GalaxyClient.exe",
                "GOG Galaxy.exe",
            ],
            searchPaths: [
                "Program Files (x86)/GOG Galaxy",
                "Program Files/GOG Galaxy",
            ],
            category: .launcher
        ),
    ]

    private init() {
        Task {
            await scanForImportantExecutables()
        }
    }

    // MARK: - Scanning Methods

    func scanForImportantExecutables() async {
        await MainActor.run {
            isScanning = true
        }

        var foundGames: [Game] = []

        // Get default bottle path
        let defaultBottlePath = NSString(
            string: "~/Library/Application Support/kimiz/gptk-bottles/default"
        ).expandingTildeInPath

        if fileManager.fileExists(atPath: defaultBottlePath) {
            await scanBottleForExecutables(
                bottlePath: defaultBottlePath, bottleName: "default", foundGames: &foundGames)
        }

        // Also scan user-added games
        let userGames = loadUserGames()
        foundGames.append(contentsOf: userGames)

        await MainActor.run {
            // Remove duplicates based on executable path
            var seenPaths = Set<String>()
            self.discoveredGames = foundGames.filter { game in
                if seenPaths.contains(game.executablePath) {
                    return false
                }
                seenPaths.insert(game.executablePath)
                return true
            }
            self.isScanning = false
            self.lastScanDate = Date()
        }
    }

    private func scanBottleForExecutables(
        bottlePath: String, bottleName: String, foundGames: inout [Game]
    ) async {
        let driveCPath = "\(bottlePath)/drive_c"

        guard fileManager.fileExists(atPath: driveCPath) else {
            print("Drive C not found for bottle: \(bottleName)")
            return
        }

        // Scan for important executables
        for executableInfo in importantExecutables {
            if let game = findExecutableInBottle(
                driveCPath: driveCPath,
                executableInfo: executableInfo,
                bottleName: bottleName
            ) {
                foundGames.append(game)
                print("Found \(executableInfo.name) in bottle \(bottleName)")
            }
        }

        // Scan for Steam games if Steam is installed
        await scanForSteamGamesInBottle(
            driveCPath: driveCPath, bottleName: bottleName, foundGames: &foundGames)

        // Scan for Epic Games if Epic Games Launcher is installed
        await scanForEpicGamesInBottle(
            driveCPath: driveCPath, bottleName: bottleName, foundGames: &foundGames)

        // Scan for other common game directories
        await scanCommonGameDirectories(
            driveCPath: driveCPath, bottleName: bottleName, foundGames: &foundGames)
    }

    private func findExecutableInBottle(
        driveCPath: String,
        executableInfo: ExecutableInfo,
        bottleName: String
    ) -> Game? {
        for searchPath in executableInfo.searchPaths {
            let fullPath = "\(driveCPath)/\(searchPath)"

            for pattern in executableInfo.patterns {
                let executablePath = "\(fullPath)/\(pattern)"

                if fileManager.fileExists(atPath: executablePath) {
                    return Game(
                        name: executableInfo.name,
                        executablePath: executablePath,
                        installPath: fullPath,
                        isInstalled: true
                    )
                }
            }
        }
        return nil
    }

    private func scanForSteamGamesInBottle(
        driveCPath: String,
        bottleName: String,
        foundGames: inout [Game]
    ) async {
        let steamAppsPath = "\(driveCPath)/Program Files (x86)/Steam/steamapps/common"

        guard fileManager.fileExists(atPath: steamAppsPath) else { return }

        do {
            let gameDirectories = try fileManager.contentsOfDirectory(atPath: steamAppsPath)

            for gameDir in gameDirectories {
                let gamePath = "\(steamAppsPath)/\(gameDir)"

                // Look for executable files in the game directory
                if let executable = findExecutableInDirectory(gamePath) {
                    let game = Game(
                        name: gameDir,
                        executablePath: executable,
                        installPath: gamePath,
                        isInstalled: true
                    )
                    foundGames.append(game)
                }
            }
        } catch {
            print("Error scanning Steam games in bottle \(bottleName): \(error)")
        }
    }

    private func scanForEpicGamesInBottle(
        driveCPath: String,
        bottleName: String,
        foundGames: inout [Game]
    ) async {
        // Epic Games stores games in various locations
        let epicGamesPaths = [
            "\(driveCPath)/Program Files/Epic Games",
            "\(driveCPath)/Program Files (x86)/Epic Games",
        ]

        for epicPath in epicGamesPaths {
            guard fileManager.fileExists(atPath: epicPath) else { continue }

            do {
                let contents = try fileManager.contentsOfDirectory(atPath: epicPath)

                for item in contents {
                    // Skip the Launcher directory itself
                    guard item != "Launcher" else { continue }

                    let gamePath = "\(epicPath)/\(item)"
                    var isDirectory: ObjCBool = false

                    if fileManager.fileExists(atPath: gamePath, isDirectory: &isDirectory),
                        isDirectory.boolValue
                    {

                        // Look for executable files in the game directory
                        if let executable = findExecutableInDirectory(gamePath) {
                            let game = Game(
                                name: item,
                                executablePath: executable,
                                installPath: gamePath,
                                isInstalled: true
                            )
                            foundGames.append(game)
                        }
                    }
                }
            } catch {
                print("Error scanning Epic Games in bottle \(bottleName): \(error)")
            }
        }
    }

    private func scanCommonGameDirectories(
        driveCPath: String,
        bottleName: String,
        foundGames: inout [Game]
    ) async {
        let commonGamePaths = [
            "\(driveCPath)/Program Files/Games",
            "\(driveCPath)/Program Files (x86)/Games",
            "\(driveCPath)/Games",
        ]

        for gamePath in commonGamePaths {
            guard fileManager.fileExists(atPath: gamePath) else { continue }

            do {
                let contents = try fileManager.contentsOfDirectory(atPath: gamePath)

                for item in contents {
                    let itemPath = "\(gamePath)/\(item)"
                    var isDirectory: ObjCBool = false

                    if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory),
                        isDirectory.boolValue
                    {

                        if let executable = findExecutableInDirectory(itemPath) {
                            let game = Game(
                                name: item,
                                executablePath: executable,
                                installPath: itemPath,
                                isInstalled: true
                            )
                            foundGames.append(game)
                        }
                    }
                }
            } catch {
                print("Error scanning common game directories in bottle \(bottleName): \(error)")
            }
        }
    }

    private func findExecutableInDirectory(_ directory: String) -> String? {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)

            // Look for .exe files, prioritizing certain patterns
            let priorityPatterns = ["launcher", "main", "game", "start"]
            let exeFiles = contents.filter { $0.lowercased().hasSuffix(".exe") }

            // First, try to find priority executables
            for pattern in priorityPatterns {
                if let found = exeFiles.first(where: { $0.lowercased().contains(pattern) }) {
                    return "\(directory)/\(found)"
                }
            }

            // If no priority executable found, return the first .exe file
            if let firstExe = exeFiles.first {
                return "\(directory)/\(firstExe)"
            }

            // Recursively search subdirectories (limited depth)
            for item in contents {
                let itemPath = "\(directory)/\(item)"
                var isDirectory: ObjCBool = false

                if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory),
                    isDirectory.boolValue,
                    !item.hasPrefix(".")
                {  // Skip hidden directories

                    if let executable = findExecutableInDirectory(itemPath) {
                        return executable
                    }
                }
            }

        } catch {
            print("Error searching directory \(directory): \(error)")
        }

        return nil
    }

    // MARK: - User Games Management

    func addUserGame(_ game: Game) async {
        var userGames = loadUserGames()
        userGames.append(game)
        saveUserGames(userGames)

        await scanForImportantExecutables()  // Refresh the list
    }

    func removeUserGame(_ game: Game) async {
        print("[LibraryManager] Starting removal of game: \(game.name) (ID: \(game.id))")
        var userGames = loadUserGames()
        print("[LibraryManager] Loaded \(userGames.count) user games")

        let originalCount = userGames.count
        userGames.removeAll { $0.id == game.id }
        let newCount = userGames.count

        print("[LibraryManager] Removed \(originalCount - newCount) games from user games list")
        saveUserGames(userGames)
        print("[LibraryManager] Saved updated user games list")

        await scanForImportantExecutables()  // Refresh the list
        print("[LibraryManager] Rescanned and refreshed game list")
    }

    private func loadUserGames() -> [Game] {
        let userGamesPath = NSHomeDirectory() + "/Library/Application Support/kimiz/userGames.json"

        guard fileManager.fileExists(atPath: userGamesPath),
            let data = try? Data(contentsOf: URL(fileURLWithPath: userGamesPath))
        else {
            return []
        }

        do {
            return try JSONDecoder().decode([Game].self, from: data)
        } catch {
            print("Error loading user games: \(error)")
            return []
        }
    }

    private func saveUserGames(_ games: [Game]) {
        let supportDir = NSHomeDirectory() + "/Library/Application Support/kimiz"
        let userGamesPath = supportDir + "/userGames.json"

        // Create directory if needed
        try? fileManager.createDirectory(
            atPath: supportDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        do {
            let data = try JSONEncoder().encode(games)
            try data.write(to: URL(fileURLWithPath: userGamesPath))
        } catch {
            print("Error saving user games: \(error)")
        }
    }
}

// MARK: - Extensions

extension Array {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
