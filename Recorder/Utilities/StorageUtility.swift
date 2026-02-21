//
//  StorageUtility.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import OSLog

struct StorageUtility {

    private static let fileManager = FileManager.default
    private static let logger = Logger(subsystem: "com.app.recorder", category: "storage")

    static func hasSufficientStorage(requiredBytes: Int64) -> Bool {
        getAvailableStorage() >= requiredBytes
    }

    static func getAvailableStorage() -> Int64 {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }

        do {
            let values = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }

            let fallbackValues = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = fallbackValues.volumeAvailableCapacity {
                return Int64(capacity)
            }
        } catch {
            logger.error("Failed to get available storage: \(error.localizedDescription)")
        }

        return 0
    }

    static func getUsedStorage() -> Int64 {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: documentsURL, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                    if let isDirectory = resourceValues.isDirectory, !isDirectory,
                       let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                } catch {
                    logger.warning("Failed to get size for file: \(fileURL.path)")
                }
            }
        }

        return totalSize
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
