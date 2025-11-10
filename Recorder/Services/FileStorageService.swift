//
//  FileStorageService.swift
//  Recorder
//
//  Created by Kiro on 10.11.2025.
//

import Foundation
import Combine
import OSLog

/// Service for managing audio file storage in the file system
final class FileStorageService: ObservableObject {
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.app.recorder", category: "storage")
    
    // MARK: - Public Methods
    
    /// Returns the URL for the Recordings directory, creating it if necessary
    /// - Returns: URL to the Recordings directory
    /// - Throws: RecorderError if directory creation fails
    func getRecordingsDirectory() throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDirectory = documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            do {
                try fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
                logger.info("Created Recordings directory at: \(recordingsDirectory.path)")
            } catch {
                logger.error("Failed to create Recordings directory: \(error.localizedDescription)")
                throw RecorderError.generic(error)
            }
        }
        
        return recordingsDirectory
    }
    
    /// Saves an audio file by copying it to the Recordings directory
    /// - Parameters:
    ///   - sourceURL: The source URL of the audio file to copy
    ///   - fileName: The name for the saved file (including extension)
    /// - Returns: URL of the saved file
    /// - Throws: RecorderError if the copy operation fails
    func saveAudioFile(from sourceURL: URL, withName fileName: String) throws -> URL {
        let recordingsDirectory = try getRecordingsDirectory()
        let destinationURL = recordingsDirectory.appendingPathComponent(fileName)
        
        // Remove existing file if present
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
    
    /// Deletes an audio file from the Recordings directory
    /// - Parameter fileName: The name of the file to delete (including extension)
    /// - Throws: RecorderError if the deletion fails
    func deleteAudioFile(fileName: String) throws {
        let recordingsDirectory = try getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.warning("Attempted to delete non-existent file: \(fileName)")
            return
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            logger.info("Deleted audio file: \(fileName)")
        } catch {
            logger.error("Failed to delete audio file \(fileName): \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }
    
    /// Checks if an audio file exists in the Recordings directory
    /// - Parameter fileName: The name of the file to check (including extension)
    /// - Returns: true if the file exists, false otherwise
    func audioFileExists(fileName: String) -> Bool {
        guard let recordingsDirectory = try? getRecordingsDirectory() else {
            return false
        }
        
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Returns the URL for a specific audio file in the Recordings directory
    /// - Parameter fileName: The name of the file (including extension)
    /// - Returns: URL to the audio file
    /// - Throws: RecorderError if the directory cannot be accessed or file doesn't exist
    func getAudioFileURL(fileName: String) throws -> URL {
        let recordingsDirectory = try getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.error("Audio file not found: \(fileName)")
            throw RecorderError.audioFileNotFound
        }
        
        return fileURL
    }
}
