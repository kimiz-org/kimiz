//
//  LibraryView.swift
//  kimiz
//
//  Created by temidaradev on 5.06.2025.
//

import AppKit
import Foundation
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @EnvironmentObject var epicGamesManager: EpicGamesManager
    @EnvironmentObject var bottleManager: BottleManager
    @StateObject private var libraryManager = LibraryManager.shared
    @State private var isRefreshing = false
    @State private var showingFilePicker = false
    @State private var selectedApplication: Game?
    @State private var hoveredApplication: Game?
    @State private var searchText = ""

    // Modern grid layout with smaller fixed-size cards
    private let columns = [
        GridItem(.fixed(200), spacing: 16),
        GridItem(.fixed(200), spacing: 16),
        GridItem(.fixed(200), spacing: 16),
        GridItem(.fixed(200), spacing: 16),
        GridItem(.fixed(200), spacing: 16),
    ]

    var filteredApps: [Game] {
        // Use applications from the dedicated LibraryManager
        let allApplications = libraryManager.discoveredGames

        if searchText.isEmpty {
            return allApplications
        } else {
            return allApplications.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack {
            // Modern background
            ModernBackground(style: .primary)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern header with search
                modernHeaderView

                // Remove any "temporarily disabled" message and always show the library UI
                if filteredApps.isEmpty && !searchText.isEmpty {
                    searchEmptyStateView
                } else if filteredApps.isEmpty {
                    modernEmptyStateView
                } else {
                    modernAppsGridView
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            // .exe is not a valid UTType on macOS, so use .data to allow any file
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernHeaderView: some View {
        ModernSectionView(title: "Application Library", icon: "square.grid.2x2.fill") {
            VStack(spacing: 16) {
                // Stats and action buttons
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 16) {
                            Label(
                                "\(libraryManager.discoveredGames.count) applications",
                                systemImage: "square.grid.2x2.fill"
                            )
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                            if isRefreshing || libraryManager.isScanning {
                                Label("Refreshing...", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }

                            if let lastScan = libraryManager.lastScanDate {
                                Label(
                                    "Last scan: \(lastScan, formatter: relativeDateFormatter)",
                                    systemImage: "clock"
                                )
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }

                    Spacer()

                    // Open in Finder button (user bottle only)
                    Button {
                        openUserBottleInFinder()
                    } label: {
                        Label("Show User Bottle in Finder", systemImage: "folder")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                    .help("Open the user bottle in Finder")
                    .disabled(userBottlePath == nil)

                    // Action buttons with modern styling
                    HStack(spacing: 12) {
                        Button {
                            Task { await refreshApplications() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(ModernSecondaryButtonStyle())
                        .disabled(isRefreshing || libraryManager.isScanning)

                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("Add Application", systemImage: "plus")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())
                        .disabled(isRefreshing || libraryManager.isScanning)
                    }
                }

                // Search bar with modern design
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16, weight: .medium))

                    TextField("Search applications...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.white)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 0)
    }

    // Returns the user bottle path (not CrossOver)
    private var userBottlePath: String? {
        // Default user bottle path logic (adjust if needed)
        let defaultPath = NSString(
            string: "~/Library/Application Support/kimiz/gptk-bottles/default"
        ).expandingTildeInPath
        if FileManager.default.fileExists(atPath: defaultPath) {
            return defaultPath
        }
        return nil
    }

    private func openUserBottleInFinder() {
        guard let bottlePath = userBottlePath else { return }
        let url = URL(fileURLWithPath: bottlePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private var modernEmptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                // Beautiful icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 12) {
                    Text("Your Application Library Awaits")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)

                    Text("Add Windows applications and run them on your Mac")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                VStack(spacing: 16) {
                    Button {
                        showingFilePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add Your First Application")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: 280)
                    }
                    .buttonStyle(ModernPrimaryButtonStyle())
                    .controlSize(.large)

                    Button {
                        Task { await refreshApplications() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                            Text("Scan for Applications")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                    .disabled(isRefreshing || libraryManager.isScanning)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    private var searchEmptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 8) {
                Text("No applications found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Try adjusting your search terms")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            Button {
                searchText = ""
            } label: {
                Text("Clear Search")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(ModernSecondaryButtonStyle())

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modernAppsGridView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                LazyVGrid(
                    columns: columns,
                    alignment: .leading,
                    spacing: 24
                ) {
                    ForEach(filteredApps) { application in
                        ModernAppCard(
                            app: application,
                            isHovered: hoveredApplication?.id == application.id,
                            onLaunch: { launchApplication(application) },
                            onDelete: { deleteApplication(application) },
                            onHover: { isHovered in
                                hoveredApplication = isHovered ? application : nil
                            }
                        )
                        .contextMenu {
                            Button("Open", action: { launchApplication(application) })
                            Divider()
                            Button("Remove from Library", role: .destructive) {
                                deleteApplication(application)
                            }
                        }
                    }
                }
                .padding(.leading, 28)
                .padding(.trailing, 0)
                .padding(.top, 20)
                .padding(.bottom, 24)
                Spacer(minLength: 0)
            }
        }
        .background(.clear)
        .refreshable {
            await refreshApplications()
        }
    }

    // MARK: - Actions

    private func refreshApplications() async {
        isRefreshing = true
        await libraryManager.scanForImportantExecutables()
        isRefreshing = false
    }

    private func launchApplication(_ application: Game) {
        Task {
            do {
                // Use the GPTK manager to launch the application
                try await gamePortingToolkitManager.launchGame(application)
            } catch {
                print("Error launching application: \(error)")
                // Could add error alert here
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                installApplication(at: url)
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }

    private func installApplication(at url: URL) {
        Task {
            let application = Game(
                name: url.deletingPathExtension().lastPathComponent,
                executablePath: url.path,
                installPath: url.deletingLastPathComponent().path
            )
            await libraryManager.addUserGame(application)
        }
    }

    private func deleteApplication(_ application: Game) {
        print("[LibraryView] Delete button pressed for application: \(application.name)")
        Task {
            print("[LibraryView] Proceeding to delete application: \(application.name)")
            await libraryManager.removeUserGame(application)
            print("[LibraryView] Delete completed for application: \(application.name)")
        }
    }

    private func openCurrentBottleInFinder() {
        guard let bottlePath = bottleManager.currentBottlePath else { return }
        let url = URL(fileURLWithPath: bottlePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

// MARK: - Application Card Component

struct AppCard: View {
    let app: Game
    let isHovered: Bool
    let onLaunch: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var appIcon: NSImage?

    var body: some View {
        VStack(spacing: 12) {
            // Application Icon/Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 150, height: 150)

                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                }

                // Hover overlay on hover
                if isHovered {
                    HStack {
                        // Delete button
                        ZStack {
                            Circle()
                                .fill(.red.opacity(0.8))
                                .frame(width: 40, height: 40)

                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            onDelete()
                        }

                        Spacer()

                        // Open button
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.7))
                                .frame(width: 60, height: 60)

                            Image(systemName: "arrow.up.forward.app.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            onLaunch()
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }
            .onHover { hovering in
                onHover(hovering)
            }
            .onTapGesture {
                // Launch application when tapping the card (if not hovering over buttons)
                if !isHovered {
                    onLaunch()
                }
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)

            // Application Info
            VStack(spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let lastUsed = app.lastPlayed {
                    Text("Last used: \(lastUsed, formatter: relativeDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Never used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 150)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: isHovered ? 8 : 4, x: 0, y: 2)
        )
        .onAppear {
            loadApplicationIcon()
        }
    }

    private func loadApplicationIcon() {
        // Try to extract icon from executable
        Task {
            if let icon = extractIconFromExecutable(path: app.executablePath) {
                await MainActor.run {
                    self.appIcon = icon
                }
            }
        }
    }

    private func extractIconFromExecutable(path: String) -> NSImage? {
        // Try to get icon from the executable
        let workspace = NSWorkspace.shared
        let icon = workspace.icon(forFile: path)

        // If it's just a generic executable icon, try to find a better one
        if icon.representations.count == 1 && icon.size == NSSize(width: 32, height: 32) {
            // Look for icon files in the same directory
            let directory = (path as NSString).deletingLastPathComponent
            let iconExtensions = ["ico", "png", "jpg", "jpeg", "bmp"]

            for ext in iconExtensions {
                let iconPath = (directory as NSString).appendingPathComponent("icon.\(ext)")
                if FileManager.default.fileExists(atPath: iconPath) {
                    if let foundIcon = NSImage(contentsOfFile: iconPath) {
                        return foundIcon
                    }
                }
            }
        }

        return icon
    }
}

// MARK: - Modern App Card Component

struct ModernAppCard: View {
    let app: Game
    let isHovered: Bool
    let onLaunch: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var appIcon: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            // App icon/artwork section
            ZStack {
                // Modern glassmorphism background with gradient and blur
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.13),
                                Color.purple.opacity(0.13),
                                Color.blue.opacity(0.10),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                    )
                    .blur(radius: 0.8)
                    .frame(width: 180, height: 160)
                    .shadow(
                        color: .black.opacity(isHovered ? 0.18 : 0.08), radius: isHovered ? 16 : 7,
                        x: 0, y: isHovered ? 8 : 3)

                // App icon or placeholder
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.13), radius: 7, x: 0, y: 3)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "app.fill")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.9), .purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                Color.primary
                            )
                        Text(app.name.prefix(1).uppercased())
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                // Hover overlay with glass panel and modern actions
                if isHovered {
                    ZStack {
                        // Background overlay
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial.opacity(0.85))
                            .frame(width: 180, height: 160)
                            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)

                        // Button overlay
                        VStack(alignment: .leading) {
                            HStack {
                                Button(action: onDelete) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(Color.red.opacity(0.88))
                                                .shadow(
                                                    color: .red.opacity(0.18), radius: 8, x: 0, y: 2
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.top, 12)
                            .padding(.leading, 12)

                            Spacer()

                            HStack {
                                Spacer()
                                Button(action: onLaunch) {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(18)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.75))
                                                .shadow(
                                                    color: .black.opacity(0.18), radius: 8, x: 0,
                                                    y: 2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.bottom, 16)
                        }
                        .frame(width: 180, height: 160)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .clipped()

            // App info section
            VStack(spacing: 6) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let lastUsed = app.lastPlayed {
                    Text("Last used \(lastUsed, formatter: relativeDateFormatter)")
                        .lineLimit(1)
                } else {
                    Text("Never used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 70)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: .black.opacity(isHovered ? 0.13 : 0.07), radius: isHovered ? 14 : 6,
                    x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
        )
        .frame(width: 200, height: 255)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            onHover(hovering)
        }
        .onTapGesture {
            if !isHovered { onLaunch() }
        }
        .onAppear {
            loadAppIcon()
        }
    }

    private func loadAppIcon() {
        Task {
            if let icon = extractIconFromExecutable(path: app.executablePath) {
                await MainActor.run {
                    self.appIcon = icon
                }
            }
        }
    }

    private func extractIconFromExecutable(path: String) -> NSImage? {
        let workspace = NSWorkspace.shared
        let icon = workspace.icon(forFile: path)

        // Look for better icons in the application directory
        if icon.representations.count == 1 && icon.size == NSSize(width: 32, height: 32) {
            let directory = (path as NSString).deletingLastPathComponent
            let iconExtensions = ["ico", "png", "jpg", "jpeg", "bmp"]
            for ext in iconExtensions {
                let iconPath = (directory as NSString).appendingPathComponent("icon.\(ext)")
                if FileManager.default.fileExists(atPath: iconPath) {
                    if let foundIcon = NSImage(contentsOfFile: iconPath) {
                        return foundIcon
                    }
                }
            }
        }
        return icon
    }
}

// MARK: - Formatters

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

#Preview {
    LibraryView()
        .environmentObject(GamePortingToolkitManager.shared)
}
