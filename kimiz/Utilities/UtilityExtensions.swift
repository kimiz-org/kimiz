//
//  UtilityExtensions.swift
//  kimiz
//
//  Created by temidaradev on 4.06.2025.
//

import Foundation
import SwiftUI

// MARK: - String Extensions

extension String {
    var expandingTildeInPath: String {
        return NSString(string: self).expandingTildeInPath
    }

    func sanitizedForFileName() -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return self.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - URL Extensions

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var fileSize: Int64 {
        return (try? resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init) ?? 0
    }
}

// MARK: - Process Extensions

extension Process {
    @discardableResult
    static func run(
        _ executablePath: String, arguments: [String] = [], environment: [String: String]? = nil
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        if let environment = environment {
            process.environment = environment
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw ProcessError.executionFailed(output)
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ProcessError: LocalizedError {
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .executionFailed(let output):
            return "Process execution failed: \(output)"
        }
    }
}

// MARK: - View Extensions

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: {
            if let error = error.wrappedValue {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - FileManager Extensions

extension FileManager {
    func sizeOfDirectory(at url: URL) -> Int64 {
        guard url.isDirectory else { return 0 }

        var totalSize: Int64 = 0

        if let enumerator = enumerator(
            at: url, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
        {
            for case let fileURL as URL in enumerator {
                totalSize += fileURL.fileSize
            }
        }

        return totalSize
    }

    func createDirectoryIfNeeded(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
