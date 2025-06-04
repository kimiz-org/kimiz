# Wine Installation Enhancement Instructions

To make the kimiz app more efficient when you already have Wine/GPTK installed, follow these steps:

1. In EmbeddedWineManager.swift, update the `installRequiredComponents()` method with this code:

```swift
func installRequiredComponents() async throws {
    await MainActor.run {
        isInstallingComponents = true
        initializationProgress = 0.1
    }
    
    // Step 1: Check if Homebrew is already installed
    if isHomebrewInstalled() {
        await MainActor.run {
            installationComponentName = "Homebrew (already installed)"
            initializationProgress = 0.3
        }
    } else {
        await MainActor.run {
            installationComponentName = "Homebrew"
        }
        try await installHomebrew()
    }
    
    // Step 2: Check if Game Porting Toolkit is already installed
    if GamePortingToolkitManager.shared.isGamePortingToolkitInstalled() {
        await MainActor.run {
            installationComponentName = "Game Porting Toolkit (already installed)"
            initializationProgress = 0.6
        }
    } else {
        await MainActor.run {
            installationComponentName = "Game Porting Toolkit"
            initializationProgress = 0.3
        }
        try await GamePortingToolkitManager.shared.installGamePortingToolkit()
    }
    
    // Step 3: Check if Winetricks is already installed
    if isWinetricksInstalled() {
        await MainActor.run {
            installationComponentName = "Winetricks (already installed)"
            initializationProgress = 0.8
        }
    } else {
        await MainActor.run {
            installationComponentName = "Winetricks"
            initializationProgress = 0.6
        }
        try await installWinetricks()
    }
    
    await MainActor.run {
        installationComponentName = "Verifying components"
        initializationProgress = 0.9
    }
    
    // Step 4: Check if installation was successful
    await checkWineInstallation()
    
    await MainActor.run {
        isInstallingComponents = false
        initializationProgress = 1.0
    }
}
```

2. Create a new file called EmbeddedWineManager+Extensions.swift with this content:

```swift
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
```

3. Update the launchGameWithOptions method in GameLaunchOptionsView.swift to include this code for better performance:

```swift
// Build environment variables based on selected options
var environmentVars: [String: String] = [:]

// Graphics settings
if enableDXVK {
    environmentVars["DXVK_ASYNC"] = "1"
    environmentVars["DXVK_STATE_CACHE"] = "1"
}

if enableEsync {
    environmentVars["WINEESYNC"] = "1"
}

if showHUD {
    environmentVars["DXVK_HUD"] = "fps,frametimes"
    environmentVars["MTL_HUD_ENABLED"] = "1"
}

// Window mode
switch windowMode {
case .fullscreen:
    environmentVars["WINE_FULLSCREEN"] = "1"
case .borderless:
    environmentVars["WINE_BORDERLESS"] = "1"
case .windowed:
    break // Default
}
```

These changes will make the app check for existing installations of Homebrew, Wine/Game Porting Toolkit, and Winetricks before trying to install them, saving time and preventing unnecessary installations.
