//
//  NotesStorageService.swift
//  Recorder
//
//  Created by Kiro on 10.11.2025.
//

import Foundation
import CoreData
import Combine
import OSLog

/// Service for managing audio notes in Core Data storage
final class NotesStorageService: ObservableObject {
    
    // MARK: - Properties
    
    /// Published array of all notes
    @Published var notes: [AudioNote] = []
    
    private let persistenceController: PersistenceController
    private let fileStorageService: FileStorageService
    private let logger = Logger(subsystem: "com.app.recorder", category: "storage")
    
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    // MARK: - Initialization
    
    init(
        persistenceController: PersistenceController = .shared,
        fileStorageService: FileStorageService = FileStorageService()
    ) {
        self.persistenceController = persistenceController
        self.fileStorageService = fileStorageService
    }
    
    // MARK: - Public Methods
    
    /// Creates a new audio note
    /// - Parameters:
    ///   - title: The title of the note
    ///   - audioFileName: The filename of the audio file
    ///   - duration: The duration of the audio in seconds
    ///   - languageCode: The language code for transcription
    /// - Returns: The created AudioNote
    /// - Throws: RecorderError if creation fails
    func createNote(
        title: String,
        audioFileName: String,
        duration: TimeInterval,
        languageCode: String
    ) throws -> AudioNote {
        let entity = AudioNoteEntity(context: viewContext)
        entity.id = UUID()
        entity.title = title
        entity.transcript = ""
        entity.audioFileName = audioFileName
        entity.duration = duration
        entity.createdAt = Date()
        entity.languageCode = languageCode
        entity.isTranscriptionCompleted = false
        
        do {
            try viewContext.save()
            let note = entity.toAudioNote()
            logger.info("Created note: \(note.id)")
            
            // Refresh notes list on main actor
            Task { @MainActor in
                try? self.fetchAllNotes()
            }
            
            return note
        } catch {
            logger.error("Failed to create note: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }
    
    /// Updates the title of an existing note
    /// - Parameters:
    ///   - noteID: The ID of the note to update
    ///   - title: The new title
    /// - Throws: RecorderError if update fails
    func updateNoteTitle(_ noteID: UUID, title: String) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                logger.error("Note not found: \(noteID)")
                throw RecorderError.audioFileNotFound
            }
            
            entity.title = title
            try viewContext.save()
            logger.info("Updated note title: \(noteID)")
            
            // Refresh notes list on main actor
            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to update note title: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }
    
    /// Updates the transcript of an existing note
    /// - Parameters:
    ///   - noteID: The ID of the note to update
    ///   - transcript: The new transcript text
    /// - Throws: RecorderError if update fails
    func updateNoteTranscript(_ noteID: UUID, transcript: String) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                logger.error("Note not found: \(noteID)")
                throw RecorderError.audioFileNotFound
            }
            
            entity.transcript = transcript
            try viewContext.save()
            logger.info("Updated note transcript: \(noteID)")
            
            // Refresh notes list on main actor
            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to update note transcript: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }
    
    /// Updates the transcription completion status of a note
    /// - Parameters:
    ///   - noteID: The ID of the note to update
    ///   - isCompleted: Whether transcription is completed
    /// - Throws: RecorderError if update fails
    func updateTranscriptionStatus(_ noteID: UUID, isCompleted: Bool) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                logger.error("Note not found: \(noteID)")
                throw RecorderError.audioFileNotFound
            }
            
            entity.isTranscriptionCompleted = isCompleted
            try viewContext.save()
            logger.info("Updated transcription status for note: \(noteID), completed: \(isCompleted)")
            
            // Refresh notes list on main actor
            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to update transcription status: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }
    
    /// Deletes a note and its associated audio file
    /// - Parameter noteID: The ID of the note to delete
    /// - Throws: RecorderError if deletion fails
    func deleteNote(_ noteID: UUID) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                logger.error("Note not found: \(noteID)")
                throw RecorderError.audioFileNotFound
            }
            
            let audioFileName = entity.audioFileName ?? ""
            
            // Delete the audio file first
            if !audioFileName.isEmpty {
                try? fileStorageService.deleteAudioFile(fileName: audioFileName)
            }
            
            // Delete the Core Data entity
            viewContext.delete(entity)
            try viewContext.save()
            logger.info("Deleted note: \(noteID)")
            
            // Refresh notes list on main actor
            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to delete note: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }
    
    /// Fetches all notes from Core Data, sorted by creation date (newest first)
    /// Optimized for performance with batch fetching
    /// - Throws: RecorderError if fetch fails
    @discardableResult
    @MainActor
    func fetchAllNotes() throws -> [AudioNote] {
        return try PerformanceMonitor.shared.measure(
            PerformanceMonitor.Operation.notesListLoad,
            threshold: PerformanceMonitor.Threshold.notesListLoad
        ) {
            let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            // Optimize fetch performance
            fetchRequest.fetchBatchSize = 20 // Load in batches for better memory usage
            fetchRequest.returnsObjectsAsFaults = false // Prefetch all properties
            
            do {
                let entities = try viewContext.fetch(fetchRequest)
                notes = entities.map { $0.toAudioNote() }
                logger.debug("Fetched \(self.notes.count) notes")
                return notes
            } catch {
                logger.error("Failed to fetch notes: \(error.localizedDescription)")
                throw RecorderError.generic(error)
            }
        }
    }
    
    /// Searches notes by filtering title and transcript
    /// Optimized for fast in-memory search
    /// - Parameter query: The search query string
    /// - Returns: Array of matching AudioNote objects
    @MainActor
    func searchNotes(query: String) -> [AudioNote] {
        return PerformanceMonitor.shared.measure(
            PerformanceMonitor.Operation.noteSearch,
            threshold: PerformanceMonitor.Threshold.noteSearch
        ) {
            guard !query.isEmpty else {
                return notes
            }
            
            let lowercasedQuery = query.lowercased()
            let filtered = notes.filter { note in
                note.title.lowercased().contains(lowercasedQuery) ||
                note.transcript.lowercased().contains(lowercasedQuery)
            }
            
            logger.debug("Search query '\(query)' returned \(filtered.count) results")
            return filtered
        }
    }
}
