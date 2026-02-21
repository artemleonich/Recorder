//
//  FileStorageService.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import Combine
import OSLog

final class FileStorageService: ObservableObject {

    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.app.recorder", category: "storage")

    func getRecordingsDirectory() throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDirectory = documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)

        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            do {
                try fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
            } catch {
                logger.error("Failed to create Recordings directory: \(error.localizedDescription)")
                throw RecorderError.generic(error)
            }
        }

        return recordingsDirectory
    }

    func saveAudioFile(from sourceURL: URL, withName fileName: String) throws -> URL {
        let recordingsDirectory = try getRecordingsDirectory()
        let destinationURL = recordingsDirectory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            logger.info("Saved audio file: \(fileName)")
            return destinationURL
        } catch {
            logger.error("Failed to save audio file \(fileName): \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }

    func deleteAudioFile(fileName: String) throws {
        let recordingsDirectory = try getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            try fileManager.removeItem(at: fileURL)
            logger.info("Deleted audio file: \(fileName)")
        } catch {
            logger.error("Failed to delete audio file \(fileName): \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }

    func audioFileExists(fileName: String) -> Bool {
        guard let recordingsDirectory = try? getRecordingsDirectory() else { return false }
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    func getAudioFileURL(fileName: String) throws -> URL {
        let recordingsDirectory = try getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw RecorderError.audioFileNotFound
        }

        return fileURL
    }
}
