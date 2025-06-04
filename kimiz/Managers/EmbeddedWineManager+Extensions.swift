//
//  EmbeddedWineManager+Extensions.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import Foundation

// Simple extension to add the winetricks check
extension EmbeddedWineManager {

    // Check if Winetricks is already installed
    func isWinetricksInstalled() -> Bool {
        let winetricksPaths = [
            "/usr/local/bin/winetricks",  // Homebrew
            "/opt/homebrew/bin/winetricks",  // Apple Silicon Homebrew
            "/usr/bin/winetricks",  // System package manager
        ]

        for path in winetricksPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
}
