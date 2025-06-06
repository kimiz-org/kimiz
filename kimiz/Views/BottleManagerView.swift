//
//  BottleManagerView.swift
//  kimiz
//
//  Created by temidaradev on 6.06.2025.
//

import Foundation
import SwiftUI

struct BottleManagerView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @Binding var isPresented: Bool
    @Binding var availableBottles: [String]

    @State private var newBottleName = ""
    @State private var selectedBottle = ""
    @State private var showingCreateBottle = false
    @State private var isCreatingBottle = false
    @State private var bottleConfigurations: [String: BottleConfig] = [:]

    struct BottleConfig {
        let name: String
        let winVersion: String
        let architecture: String
        let components: [String]
        let dateCreated: Date
        let gamesCount: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Create New Bottle Section
                    createBottleSection

                    // Existing Bottles
                    existingBottlesSection
                }
                .padding(24)
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 700, height: 600)
        .background(.regularMaterial)
        .onAppear {
            loadBottleConfigurations()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game Porting Toolkit Bottle Manager")
                    .font(.headline)

                Text("Create and manage isolated GPTK environments for different applications")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Close") {
                isPresented = false
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var createBottleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Bottle")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                HStack {
                    Text("Bottle Name:")
                        .frame(width: 100, alignment: .leading)

                    TextField("Enter bottle name", text: $newBottleName)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Template:")
                        .frame(width: 100, alignment: .leading)

                    Picker("Template", selection: $selectedBottle) {
                        Text("Gaming (GPTK + DirectX, DXVK)").tag("gaming")
                        Text("Office (GPTK Default)").tag("office")
                        Text("Development (GPTK + Visual C++)").tag("development")
                        Text("Minimal (Clean GPTK)").tag("minimal")
                    }
                    .pickerStyle(.menu)

                    Spacer()
                }

                HStack {
                    Spacer()

                    Button("Create Bottle") {
                        createNewBottle()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newBottleName.isEmpty || isCreatingBottle)

                    if isCreatingBottle {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }

    private var existingBottlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Existing Bottles")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Refresh") {
                    loadBottleConfigurations()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if bottleConfigurations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No bottles found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Create your first bottle to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(bottleConfigurations.values), id: \.name) { config in
                        BottleCardView(config: config) {
                            deleteBottle(config.name)
                        }
                    }
                }
            }
        }
    }

    private var footerView: some View {
        HStack {
            Text("Bottles are isolated GPTK environments that don't interfere with each other")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func createNewBottle() {
        guard !newBottleName.isEmpty else { return }

        isCreatingBottle = true

        Task {
            await gamePortingToolkitManager.createBottle(name: newBottleName)

            await MainActor.run {
                // Add to available bottles
                if !availableBottles.contains(newBottleName) {
                    availableBottles.append(newBottleName)
                }

                // Reset form
                newBottleName = ""
                selectedBottle = ""
                isCreatingBottle = false  // Reload configurations
                loadBottleConfigurations()
            }
        }
    }

    private func loadBottleConfigurations() {
        // Mock data for now - in a real implementation, this would query GPTK bottles
        bottleConfigurations = [
            "Default": BottleConfig(
                name: "Default",
                winVersion: "Windows 10",
                architecture: "x86_64",
                components: ["vcrun2019", "d3d11", "gptk"],
                dateCreated: Date().addingTimeInterval(-86400 * 7),
                gamesCount: 3
            ),
            "Gaming": BottleConfig(
                name: "Gaming",
                winVersion: "Windows 10",
                architecture: "x86_64",
                components: ["dxvk", "vcrun2019", "d3d11", "vulkan", "gptk"],
                dateCreated: Date().addingTimeInterval(-86400 * 3),
                gamesCount: 8
            ),
        ]
    }

    private func deleteBottle(_ name: String) {
        bottleConfigurations.removeValue(forKey: name)
        availableBottles.removeAll { $0 == name }
    }
}

struct BottleCardView: View {
    let config: BottleManagerView.BottleConfig
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Bottle Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)

                Image(systemName: "tray.full.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            // Bottle Info
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.headline)

                Text("\(config.winVersion) • \(config.architecture)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("\(config.gamesCount) games")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Created \(config.dateCreated, formatter: relativeDateFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button("Configure") {
                    // Configure bottle action
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if isHovered {
                    Button("Delete") {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    private var relativeDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    BottleManagerView(
        isPresented: Binding.constant(true),
        availableBottles: Binding.constant(["Default", "Gaming"])
    )
    .environmentObject(GamePortingToolkitManager.shared)
}
