//
//  StorageUtility.swift
//  Recorder
//
//  Created by Kiro on 10.11.2025.
//

import Foundation
import OSLog

/// Utility for checking storage availability and usage
struct StorageUtility {
    
    // MARK: - Properties
    
    private static let fileManager = FileManager.default
    private static let logger = Logger(subsystem: "com.app.recorder", category: "storage")
    
    // MARK: - Public Methods
    
    /// Checks if there is sufficient storage available on the device
    /// - Parameter requiredBytes: The number of bytes required
    /// - Returns: true if sufficient storage is available, false otherwise
    static func hasSufficientStorage(requiredBytes: Int64) -> Bool {
        let availableBytes = getAvailableStorage()
        let hasSufficient = availableBytes >= requiredBytes
        
        logger.debug("Storage check: required=\(requiredBytes), available=\(availableBytes), sufficient=\(hasSufficient)")
        
        return hasSufficient
    }
    
    /// Returns the amount of available storage on the device in bytes
    /// - Returns: Available storage in bytes, or 0 if unable to determine
    static func getAvailableStorage() -> Int64 {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Failed to get documents directory URL")
            return 0
        }
        
        do {
            let values = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                logger.debug("Available storage: \(capacity) bytes")
                return capacity
            } else {
                // Fallback to regular available capacity
                let fallbackValues = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
                if let capacity = fallbackValues.volumeAvailableCapacity {
                    logger.debug("Available storage (fallback): \(capacity) bytes")
                    return Int64(capacity)
                }
            }
        } catch {
            logger.error("Failed to get available storage: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    /// Calculates the total storage used by the application
    /// - Returns: Total storage used in bytes
    static func getUsedStorage() -> Int64 {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Failed to get documents directory URL")
            return 0
        }
        
        var totalSize: Int64 = 0
        
        // Calculate size of all files in the documents directory
        if let enumerator = fileManager.enumerator(at: documentsURL, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                    
                    // Skip directories, only count files
                    if let isDirectory = resourceValues.isDirectory, !isDirectory {
                        if let fileSize = resourceValues.fileSize {
                            totalSize += Int64(fileSize)
                        }
                    }
                } catch {
                    logger.warning("Failed to get size for file: \(fileURL.path), error: \(error.localizedDescription)")
                }
            }
        }
        
        logger.debug("Total storage used by app: \(totalSize) bytes")
        
        return totalSize
    }
    
    /// Formats bytes into a human-readable string (e.g., "1.5 MB")
    /// - Parameter bytes: The number of bytes to format
    /// - Returns: Formatted string representation
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
