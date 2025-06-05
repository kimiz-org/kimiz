//
//  Game.swift
//  kimiz
//
//  Created by Ahmet Affan Ebcioğlu on 5.06.2025.
//

import Foundation

struct Game: Identifiable {
    let id = UUID()
    let name: String
    let executablePath: String
    let installPath: String
    var lastPlayed: Date?
    var isInstalled: Bool = false
    var icon: Data?

    init(name: String, executablePath: String, installPath: String) {
        self.name = name
        self.executablePath = executablePath
        self.installPath = installPath
    }
}
