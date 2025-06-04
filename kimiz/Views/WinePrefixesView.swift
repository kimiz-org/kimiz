//
//  WinePrefixesView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI

struct WinePrefixesView: View {
    @EnvironmentObject var wineManager: WineManager
    @State private var showingCreatePrefix = false
    @State private var selectedPrefix: WinePrefix?

    var body: some View {
        NavigationView {
            List {
                ForEach(wineManager.winePrefixes, id: \.id) { prefix in
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
            }
            .navigationTitle("Wine Prefixes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Create Prefix") {
                        showingCreatePrefix = true
                    }
                }
            }
            .sheet(isPresented: $showingCreatePrefix) {
                CreateWinePrefixView()
            }
            .sheet(item: $selectedPrefix) { prefix in
                WinePrefixDetailsView(prefix: prefix)
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
                        InfoRow(label: "Name", value: prefix.name)
                        InfoRow(label: "Backend", value: prefix.backend.displayName)
                        InfoRow(label: "Windows Version", value: prefix.windowsVersion.uppercased())
                        InfoRow(label: "Architecture", value: prefix.architecture)
                        InfoRow(label: "Path", value: prefix.path)
                        InfoRow(
                            label: "Created",
                            value: DateFormatter.localizedString(
                                from: prefix.createdDate, dateStyle: .medium, timeStyle: .short))
                        InfoRow(
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

#Preview {
    WinePrefixesView()
        .environmentObject(WineManager())
}
