//
//  InstallationView.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 4.06.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct InstallationView: View {
    @EnvironmentObject var gamePortingToolkitManager: GamePortingToolkitManager
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "gear.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text("Installation & Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Advanced installation features coming soon!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Install Game Porting Toolkit") {
                    installGPTK()
                }
                .buttonStyle(.borderedProminent)
                .disabled(gamePortingToolkitManager.isGPTKInstalled)

                if gamePortingToolkitManager.isGPTKInstalled {
                    Text("✓ Game Porting Toolkit is installed")
                        .foregroundColor(.green)
                }

                Spacer()
            }
            .padding()
            .alert("Installation", isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
        .navigationTitle("Installation")
    }

    private func installGPTK() {
        Task {
            do {
                try await gamePortingToolkitManager.installGamePortingToolkit()
                await MainActor.run {
                    alertMessage = "Game Porting Toolkit installed successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Installation failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    InstallationView()
        .environmentObject(GamePortingToolkitManager.shared)
}
