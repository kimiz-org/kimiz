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
