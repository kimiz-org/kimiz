//
//  GameLaunchOptionsView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct GameLaunchOptionsView: View {
    let game: Game
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var launchArguments: String = ""
    @State private var enableDXVK = true
    @State private var enableEsync = true
    @State private var showHUD = false
    @State private var windowMode: WindowMode = .windowed
    @Binding var isPresented: Bool

    @AppStorage("defaultWindowMode") private var defaultWindowMode = WindowMode.windowed.rawValue
    @AppStorage("defaultDXVK") private var defaultDXVK = true
    @AppStorage("defaultEsync") private var defaultEsync = true

    enum WindowMode: String, CaseIterable, Identifiable {
        case windowed = "Windowed"
        case fullscreen = "Fullscreen"
        case borderless = "Borderless"

        var id: String { self.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Launch Options: \(game.name)")
                    .font(.headline)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Launch Arguments
                    Group {
                        Text("Launch Arguments")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Optional command-line arguments", text: $launchArguments)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Display Mode
                    Group {
                        Text("Display Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Picker("Window Mode", selection: $windowMode) {
                            ForEach(WindowMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    // Graphics & Performance Options
                    Group {
                        Text("Graphics & Performance")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Toggle("Enable DXVK (DirectX to Vulkan)", isOn: $enableDXVK)

                        Toggle("Enable Esync (Event Synchronization)", isOn: $enableEsync)

                        Toggle("Show Performance HUD", isOn: $showHUD)
                    }

                    if let recommendation = performanceRecommendation {
                        Text(recommendation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    Divider()

                    Button("Save as Default") {
                        saveAsDefault()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
            }

            Divider()

            // Footer with action buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Launch Game") {
                    launchGameWithOptions()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .onAppear {
            loadSavedSettings()
        }
    }

    private var performanceRecommendation: String? {
        if game.name.lowercased().contains("cyberpunk") {
            return "Recommendation: DXVK and Esync recommended for Cyberpunk 2077"
        } else if game.name.lowercased().contains("witcher") {
            return "Recommendation: DXVK recommended for The Witcher series"
        }
        return nil
    }

    private func loadSavedSettings() {
        windowMode = WindowMode(rawValue: defaultWindowMode) ?? .windowed
        enableDXVK = defaultDXVK
        enableEsync = defaultEsync
    }

    private func saveAsDefault() {
        defaultWindowMode = windowMode.rawValue
        defaultDXVK = enableDXVK
        defaultEsync = enableEsync
    }

    private func launchGameWithOptions() {
        Task {
            do {
                // Close the options sheet
                isPresented = false

                // Launch the game using GPTK manager
                try await gamePortingToolkitManager.launchGame(game)
            } catch {
                print("Failed to launch game: \(error)")
            }
        }
    }
}

struct GameLaunchOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        let game = Game(
            name: "Sample Game",
            executablePath: "/path/to/game.exe",
            installPath: "/path/to/game"
        )

        GameLaunchOptionsView(game: game, isPresented: .constant(true))
            .environmentObject(GamePortingToolkitManager.shared)
    }
}
