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

            VStack(spacing: 0) {
                // Modern header
                modernHeaderView

                Divider()

                // Content
                ScrollView {
                    VStack(spacing: 28) {
                        // Create New Bottle Section
                        createBottleSection

                        // Existing Bottles
                        existingBottlesSection
                    }
                    .padding(28)
                }

                Divider()

                // Modern footer
                modernFooterView
            }
        }
        .frame(width: 800, height: 700)
        .background(.regularMaterial)
        .onAppear {
            loadBottleConfigurations()
        }
    }

    private var modernHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bottle Manager")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Create and manage isolated GPTK environments for different applications")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial.opacity(0.8))
    }

    private var createBottleSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Create New Bottle")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 20) {
                // Bottle name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bottle Name")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("Enter bottle name (e.g., MyGameBottle)", text: $newBottleName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14))
                }

                // Template selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    Picker("Template", selection: $selectedBottle) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                            Text("Gaming (GPTK + DirectX, DXVK)")
                        }.tag("gaming")

                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Office (GPTK Default)")
                        }.tag("office")

                        HStack {
                            Image(systemName: "hammer.fill")
                            Text("Development (GPTK + Visual C++)")
                        }.tag("development")

                        HStack {
                            Image(systemName: "cube")
                            Text("Minimal (Clean GPTK)")
                        }.tag("minimal")
                    }
                    .pickerStyle(.menu)
                }

                // Create button
                HStack {
                    Spacer()

                    if isCreatingBottle {
                        HStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Creating bottle...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        createNewBottle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("Create Bottle")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newBottleName.isEmpty || isCreatingBottle)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private var existingBottlesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "tray.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Existing Bottles")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    loadBottleConfigurations()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        Text("Refresh")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if bottleConfigurations.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.1), .gray.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "tray")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 8) {
                        Text("No bottles found")
                            .font(.system(size: 18, weight: .semibold))

                        Text(
                            "Create your first bottle to get started with isolated GPTK environments"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(bottleConfigurations.values), id: \.name) { config in
                        ModernBottleCard(config: config) {
                            deleteBottle(config.name)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private var modernFooterView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)

                Text("Bottles are isolated GPTK environments that don't interfere with each other")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }

            HStack {
                Spacer()

                Button {
                    isPresented = false
                } label: {
                    HStack(spacing: 8) {
                        Text("Done")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(0.8))
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

// MARK: - Modern Bottle Card Component

struct ModernBottleCard: View {
    let config: BottleManagerView.BottleConfig
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Bottle icon and status
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "cube.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }

            // Bottle information
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(config.name)
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Text(config.winVersion)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundColor(.blue)
                }

                HStack(spacing: 16) {
                    Label("\(config.gamesCount) games", systemImage: "gamecontroller.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Label(config.architecture, systemImage: "cpu")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Label(
                        "Created \(config.dateCreated, formatter: relativeDateFormatter)",
                        systemImage: "calendar"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                }

                // Components
                if !config.components.isEmpty {
                    HStack {
                        Text("Components:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        ForEach(config.components.prefix(3), id: \.self) { component in
                            Text(component)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Color.gray.opacity(0.5),
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                                .foregroundColor(.secondary)
                        }

                        if config.components.count > 3 {
                            Text("+\(config.components.count - 3)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 8) {
                Button {
                    // Open bottle action
                } label: {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(isHovered ? 0.3 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

#Preview {
    BottleManagerView(
        isPresented: Binding.constant(true),
        availableBottles: Binding.constant(["Default", "Gaming"])
    )
    .environmentObject(GamePortingToolkitManager.shared)
}
