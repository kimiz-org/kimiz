//
//  WinePrefixesView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct WinePrefixesView: View {
    @EnvironmentObject var wineManager: WineManager
    @EnvironmentObject var embeddedWineManager: EmbeddedWineManager
    @State private var showingCreatePrefix = false
    @State private var selectedPrefix: WinePrefix?
    @State private var showingWineStatus = false

    var body: some View {
        NavigationView {
            VStack {
                if !embeddedWineManager.isWineReady {
                    wineStatusBanner
                }

                List {
                    defaultPrefixSection

                    customPrefixesSection
                }
            }
            .navigationTitle("Wine Prefixes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Create New Prefix") {
                            showingCreatePrefix = true
                        }
                        .disabled(!embeddedWineManager.isWineReady)

                        Divider()

                        Button("Check Wine Status") {
                            showingWineStatus = true
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePrefix) {
                CreateWinePrefixView()
            }
            .sheet(item: $selectedPrefix) { prefix in
                WinePrefixDetailsView(prefix: prefix)
            }
            .sheet(isPresented: $showingWineStatus) {
                VStack {
                    Text("Wine Runtime Status")
                        .font(.title2)
                        .padding(.top)

                    WineStatusView()
                        .padding()

                    Button("Close") {
                        showingWineStatus = false
                    }
                    .padding(.bottom)
                }
                .frame(width: 500, height: 400)
            }
        }
    }

    private var wineStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            Text("Wine runtime is required to create prefixes")
                .foregroundColor(.white)
                .font(.callout)

            Spacer()

            Button("Install Now") {
                showingWineStatus = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.white.opacity(0.3))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.8))
    }

    private var defaultPrefixSection: some View {
        Section("Default Prefix") {
            if let defaultPrefix = wineManager.winePrefixes.first(where: { $0.isDefault }) {
                WinePrefixRow(prefix: defaultPrefix)
                    .onTapGesture {
                        selectedPrefix = defaultPrefix
                    }
                    .contextMenu {
                        Button("Open in Finder") {
                            NSWorkspace.shared.open(URL(fileURLWithPath: defaultPrefix.path))
                        }
                    }
            } else {
                InfoRow(
                    icon: "folder.badge.plus",
                    title: "No Default Prefix",
                    subtitle: "Create a default prefix to get started",
                    action: {
                        showingCreatePrefix = true
                    },
                    actionTitle: "Create"
                )
                .disabled(!embeddedWineManager.isWineReady)
            }
        }
    }

    private var customPrefixesSection: some View {
        Section("Custom Prefixes") {
            let customPrefixes = wineManager.winePrefixes.filter({ !$0.isDefault })
            if !customPrefixes.isEmpty {
                ForEach(customPrefixes, id: \.id) { prefix in
                    WinePrefixRow(prefix: prefix)
                        .onTapGesture {
                            selectedPrefix = prefix
                        }
                        .contextMenu {
                            Button("Open in Finder") {
                                NSWorkspace.shared.open(URL(fileURLWithPath: prefix.path))
                            }

                            Button("Delete", role: .destructive) {
                                deletePrefix(prefix)
                            }
                        }
                }
            } else {
                InfoRow(
                    icon: "folder.badge.questionmark",
                    title: "No Custom Prefixes",
                    subtitle: "Create custom prefixes for different configurations",
                    action: {
                        showingCreatePrefix = true
                    },
                    actionTitle: "Create"
                )
                .disabled(!embeddedWineManager.isWineReady)
            }
        }
    }

    private func deletePrefix(_ prefix: WinePrefix) {
        do {
            try wineManager.deleteWinePrefix(prefix)
        } catch {
            print("Failed to delete prefix: \(error)")
        }
    }
}

struct WinePrefixRow: View {
    let prefix: WinePrefix

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(prefix.name)
                        .font(.headline)

                    Text(prefix.backend.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(prefix.windowsVersion.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)

                    if prefix.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Text("Last used: \(prefix.lastUsed, style: .relative) ago")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct CreateWinePrefixView: View {
    @EnvironmentObject var wineManager: WineManager
    @Environment(\.dismiss) private var dismiss

    @State private var prefixName = ""
    @State private var selectedBackend: WineBackend = .wine
    @State private var windowsVersion = "win10"
    @State private var isCreating = false
    @State private var errorMessage: String?

    let windowsVersions = ["win10", "win11", "win7", "winxp"]

    var body: some View {
        NavigationView {
            Form {
                Section("Prefix Details") {
                    TextField("Prefix Name", text: $prefixName)
                        .textFieldStyle(.roundedBorder)

                    Picker("Wine Backend", selection: $selectedBackend) {
                        ForEach(wineManager.availableBackends, id: \.self) { backend in
                            Text(backend.displayName).tag(backend)
                        }
                    }

                    Picker("Windows Version", selection: $windowsVersion) {
                        ForEach(windowsVersions, id: \.self) { version in
                            Text(version.uppercased()).tag(version)
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Text(
                        "A Wine prefix is an isolated Windows environment where you can install and run Windows applications."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Wine Prefix")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPrefix()
                    }
                    .disabled(prefixName.isEmpty || isCreating)
                }
            }
        }
    }

    private func createPrefix() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await wineManager.createWinePrefix(
                    name: prefixName,
                    backend: selectedBackend,
                    windowsVersion: windowsVersion
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                }
            }
        }
    }
}

struct WinePrefixDetailsView: View {
    let prefix: WinePrefix
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var wineManager: WineManager

    var gamesInPrefix: [GameInstallation] {
        wineManager.gameInstallations.filter { $0.winePrefix.id == prefix.id }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Prefix info
                GroupBox("Prefix Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRowKeyValue(label: "Name", value: prefix.name)
                        InfoRowKeyValue(label: "Backend", value: prefix.backend.displayName)
                        InfoRowKeyValue(
                            label: "Windows Version", value: prefix.windowsVersion.uppercased())
                        InfoRowKeyValue(label: "Architecture", value: prefix.architecture)
                        InfoRowKeyValue(label: "Path", value: prefix.path)
                        InfoRowKeyValue(
                            label: "Created",
                            value: DateFormatter.localizedString(
                                from: prefix.createdDate, dateStyle: .medium, timeStyle: .short))
                        InfoRowKeyValue(
                            label: "Last Used",
                            value: DateFormatter.localizedString(
                                from: prefix.lastUsed, dateStyle: .medium, timeStyle: .short))
                    }
                }

                // Games in this prefix
                GroupBox("Installed Games (\(gamesInPrefix.count))") {
                    if gamesInPrefix.isEmpty {
                        Text("No games installed in this prefix")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(gamesInPrefix, id: \.id) { game in
                                HStack {
                                    Image(systemName: "gamecontroller")
                                        .foregroundColor(.blue)
                                    Text(game.name)
                                    Spacer()
                                    Circle()
                                        .fill(game.isInstalled ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }

                // Actions
                GroupBox("Actions") {
                    VStack(spacing: 12) {
                        Button("Open Wine Configuration") {
                            openWineConfig()
                        }
                        .buttonStyle(.bordered)

                        Button("Open in Finder") {
                            NSWorkspace.shared.open(URL(fileURLWithPath: prefix.path))
                        }
                        .buttonStyle(.bordered)

                        Button("Install Steam") {
                            installSteam()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Prefix Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func openWineConfig() {
        Task {
            do {
                try await wineManager.runWindowsExecutable(
                    path: "winecfg",
                    in: prefix
                )
            } catch {
                print("Failed to open Wine config: \(error)")
            }
        }
    }

    private func installSteam() {
        Task {
            do {
                try await wineManager.installSteam(in: prefix)
            } catch {
                print("Failed to install Steam: \(error)")
            }
        }
    }
}

// MARK: - Helper Views
struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let actionTitle: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(actionTitle) {
                action()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
}

// Original InfoRow for displaying key-value pairs
struct InfoRowKeyValue: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WinePrefixesView()
        .environmentObject(WineManager())
        .environmentObject(EmbeddedWineManager())
}
