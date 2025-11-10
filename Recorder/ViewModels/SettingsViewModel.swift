//
//  SettingsViewModel.swift
//  Recorder
//
//  Created by Kiro on 10.11.2025.
//

import SwiftUI
import Combine
import OSLog
import Foundation
import CoreData

/// ViewModel for managing application settings
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Properties
    
    /// Application settings
    var settings: AppSettings
    
    /// Storage used by the application in bytes
    @Published var storageUsed: Int64 = 0
    
    /// Available storage on the device in bytes
    @Published var storageAvailable: Int64 = 0
    
    private let notesStorageService: NotesStorageService
    private let logger = Logger(subsystem: "com.app.recorder", category: "settings")
    
    // MARK: - Initialization
    
    init(
        settings: AppSettings,
        notesStorageService: NotesStorageService
    ) {
        self.settings = settings
        self.notesStorageService = notesStorageService
    }
    
    // MARK: - Public Methods
    
    /// Calculates current storage usage and available storage
    func calculateStorageUsage() {
        storageUsed = StorageUtility.getUsedStorage()
        storageAvailable = StorageUtility.getAvailableStorage()
        
        logger.info("Storage calculated - Used: \(StorageUtility.formatBytes(self.storageUsed)), Available: \(StorageUtility.formatBytes(self.storageAvailable))")
    }
    
    /// Clears notes older than the configured number of days
    /// - Throws: RecorderError if deletion fails
    func clearOldNotes() async throws {
        guard settings.autoDeleteOldMessages else {
            logger.info("Auto-delete is disabled, skipping clearOldNotes")
            return
        }
        
        let daysThreshold = settings.autoDeleteDays
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -Int(daysThreshold), to: Date()) else {
            logger.error("Failed to calculate cutoff date")
            return
        }
        
        logger.info("Clearing notes older than \(daysThreshold) days (before \(cutoffDate))")
        
        // Fetch all notes
        let allNotes = try notesStorageService.fetchAllNotes()
        
        // Filter notes older than cutoff date
        let oldNotes = allNotes.filter { note in
            note.createdAt < cutoffDate
        }
        
        logger.info("Found \(oldNotes.count) old notes to delete")
        
        // Delete each old note
        var deletedCount = 0
        var failedCount = 0
        
        for note in oldNotes {
            do {
                try notesStorageService.deleteNote(note.id)
                deletedCount += 1
            } catch {
                logger.error("Failed to delete note \(note.id): \(error.localizedDescription)")
                failedCount += 1
            }
        }
        
        logger.info("Deleted \(deletedCount) old notes, \(failedCount) failed")
        
        // Recalculate storage after deletion
        calculateStorageUsage()
    }
    
    /// Applies the current appearance setting to the app
    /// - Returns: ColorScheme to apply, or nil for system default
    func applyAppearance() -> ColorScheme? {
        let colorScheme = settings.colorScheme
        
        logger.info("Applying appearance: \(self.settings.appAppearance)")
        
        return colorScheme
    }
    
    // MARK: - Formatted Properties
    
    /// Formatted string for storage used
    var storageUsedFormatted: String {
        StorageUtility.formatBytes(storageUsed)
    }
    
    /// Formatted string for available storage
    var storageAvailableFormatted: String {
        StorageUtility.formatBytes(storageAvailable)
    }
    
    /// Total storage (used + available)
    var totalStorage: Int64 {
        storageUsed + storageAvailable
    }
    
    /// Formatted string for total storage
    var totalStorageFormatted: String {
        StorageUtility.formatBytes(totalStorage)
    }
    
    /// Storage usage percentage (0.0 to 1.0)
    var storageUsagePercentage: Double {
        guard totalStorage > 0 else { return 0.0 }
        return Double(storageUsed) / Double(totalStorage)
    }
}
