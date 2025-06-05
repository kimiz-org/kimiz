//
//  Game.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 5.06.2025.
//

import Foundation

struct Game: Identifiable, Codable {
    let id: UUID
    let name: String
    let executablePath: String
    let installPath: String
    var lastPlayed: Date?
    var isInstalled: Bool = false
    var icon: Data?

    init(
        id: UUID = UUID(), name: String, executablePath: String, installPath: String,
        lastPlayed: Date? = nil, isInstalled: Bool = false, icon: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.installPath = installPath
        self.lastPlayed = lastPlayed
        self.isInstalled = isInstalled
        self.icon = icon
    }
}
