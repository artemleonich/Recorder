//
//  NotesStorageService.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import CoreData
import Combine
import OSLog

final class NotesStorageService: ObservableObject {

    @Published var notes: [AudioNote] = []

    private let persistenceController: PersistenceController
    private let fileStorageService: FileStorageService
    private let logger = Logger(subsystem: "com.app.recorder", category: "storage")

    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    init(
        persistenceController: PersistenceController = .shared,
        fileStorageService: FileStorageService = FileStorageService()
    ) {
        self.persistenceController = persistenceController
        self.fileStorageService = fileStorageService
    }

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

            Task { @MainActor in
                try? self.fetchAllNotes()
            }

            return note
        } catch {
            logger.error("Failed to create note: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }

    func updateNoteTitle(_ noteID: UUID, title: String) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)

        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                throw RecorderError.audioFileNotFound
            }

            entity.title = title
            try viewContext.save()

            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to update note title: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }

    func updateNoteTranscript(_ noteID: UUID, transcript: String) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)

        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                throw RecorderError.audioFileNotFound
            }

            entity.transcript = transcript
            try viewContext.save()

            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to update note transcript: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }

    func updateTranscriptionStatus(_ noteID: UUID, isCompleted: Bool) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)

        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                throw RecorderError.audioFileNotFound
            }

            entity.isTranscriptionCompleted = isCompleted
            try viewContext.save()

            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to update transcription status: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }

    func deleteNote(_ noteID: UUID) throws {
        let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteID as CVarArg)

        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else {
                throw RecorderError.audioFileNotFound
            }

            let audioFileName = entity.audioFileName ?? ""
            if !audioFileName.isEmpty {
                try? fileStorageService.deleteAudioFile(fileName: audioFileName)
            }

            viewContext.delete(entity)
            try viewContext.save()

            Task { @MainActor in
                try? self.fetchAllNotes()
            }
        } catch {
            logger.error("Failed to delete note: \(error.localizedDescription)")
            throw RecorderError.generic(error)
        }
    }

    @discardableResult
    @MainActor
    func fetchAllNotes() throws -> [AudioNote] {
        return try PerformanceMonitor.shared.measure(
            PerformanceMonitor.Operation.notesListLoad,
            threshold: PerformanceMonitor.Threshold.notesListLoad
        ) {
            let fetchRequest: NSFetchRequest<AudioNoteEntity> = AudioNoteEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            fetchRequest.fetchBatchSize = 20
            fetchRequest.returnsObjectsAsFaults = false

            do {
                let entities = try viewContext.fetch(fetchRequest)
                notes = entities.map { $0.toAudioNote() }
                return notes
            } catch {
                logger.error("Failed to fetch notes: \(error.localizedDescription)")
                throw RecorderError.generic(error)
            }
        }
    }

    @MainActor
    func searchNotes(query: String) -> [AudioNote] {
        return PerformanceMonitor.shared.measure(
            PerformanceMonitor.Operation.noteSearch,
            threshold: PerformanceMonitor.Threshold.noteSearch
        ) {
            guard !query.isEmpty else { return notes }

            let lowercasedQuery = query.lowercased()
            return notes.filter { note in
                note.title.lowercased().contains(lowercasedQuery) ||
                note.transcript.lowercased().contains(lowercasedQuery)
            }
        }
    }
}
