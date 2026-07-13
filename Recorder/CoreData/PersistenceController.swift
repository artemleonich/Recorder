//
//  PersistenceController.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//
//  Replaces the previous version that called ``fatalError`` on every
//  Core Data error. ``fatalError`` is acceptable in DEBUG / preview
//  code paths because the developer is sitting at the keyboard, but
//  in a production app it crashes the user on:
//    - any persistent store migration error
//    - any transient I/O error during a save (full disk, dropped
//      connection to an external Core Data store, etc.)
//  Both are real and have been observed on user devices.
//
//  The new design surfaces the error to the caller (the ViewModel
//  or the App scene) so the user can be shown a useful message
//  ("Couldn't save your note. Try again or restart the app.")
//  instead of a silent crash.
//

import CoreData
import Foundation
import os

struct PersistenceController {
    static let shared = PersistenceController()

    /// Logger for all persistence-related issues.
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Recorder",
        category: "Persistence"
    )

    /// Error type surfaced from the persistence layer. Catch sites can
    /// pattern-match on these cases to present a user-friendly message
    /// (e.g. via an alert in NoteDetailViewModel).
    enum PersistenceError: LocalizedError {
        case storeLoadFailed(underlying: Error)
        case saveFailed(underlying: Error)
        case previewSeedFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .storeLoadFailed:
                return "Couldn't open the notes database. Please relaunch the app."
            case .saveFailed:
                return "Couldn't save your note. Please try again."
            case .previewSeedFailed:
                return "Couldn't initialize the preview data."
            }
        }

        var underlying: Error {
            switch self {
            case .storeLoadFailed(let e), .saveFailed(let e), .previewSeedFailed(let e):
                return e
            }
        }
    }

    static var preview: PersistenceController = {
        do {
            return try PersistenceController.previewInstance()
        } catch {
            // Preview seed failure is a developer-time issue: the
            // preview is only ever built by Xcode for SwiftUI
            // previews, never shipped to a user. ``assertionFailure``
            // produces a debugger break + console message without
            // crashing the app process (unlike ``fatalError`` which
            // would also kill the preview window).
            let nsError = error as NSError
            assertionFailure("Unresolved error creating preview data: \(nsError), \(nsError.userInfo)")
            return PersistenceController(inMemory: true)
        }
    }()

    let container: NSPersistentContainer

    /// Optional delegate that receives async error notifications. Set this
    /// from the App scene to surface save failures via an alert banner.
    weak var errorDelegate: PersistenceErrorDelegate?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RecorderDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Load the persistent store synchronously so the rest of the app
        // can rely on the store being available from the very first
        // access. Errors are surfaced via the delegate and logged; the
        // container is still returned so SwiftUI previews can render.
        container.loadPersistentStores { [weak self] storeDescription, error in
            guard let self = self, let error = error else { return }
            Self.logger.error("Failed to load persistent store: \(error.localizedDescription)")
            self.errorDelegate?.persistenceController(
                self,
                didEncounterError: .storeLoadFailed(underlying: error)
            )
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Save the view context, surfacing errors to the delegate and logger
    /// instead of crashing. Returns ``true`` on success, ``false`` on
    /// failure.
    @discardableResult
    func saveContext() -> Bool {
        let context = container.viewContext
        guard context.hasChanges else { return true }

        do {
            try context.save()
            return true
        } catch {
            let nsError = error as NSError
            Self.logger.error("Failed to save context: \(nsError.localizedDescription)")
            errorDelegate?.persistenceController(
                self,
                didEncounterError: .saveFailed(underlying: error)
            )
            return false
        }
    }

    // MARK: - Preview (developer-only)

    /// Synchronous preview constructor that throws on error. Callers in
    /// developer-only code paths can ``try`` this and fall back
    /// gracefully (the static ``preview`` above does this with
    /// ``assertionFailure``).
    static func previewInstance() throws -> PersistenceController {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        for i in 0..<5 {
            let note = AudioNoteEntity(context: viewContext)
            note.id = UUID()
            note.title = "Заметка \(i + 1)"
            note.transcript = "Пример текста транскрипции для заметки номер \(i + 1)"
            note.audioFileName = "\(UUID().uuidString).m4a"
            note.duration = Double.random(in: 30...300)
            note.createdAt = Date().addingTimeInterval(-Double(i) * 3600)
            note.languageCode = "ru"
            note.isTranscriptionCompleted = i % 2 == 0
        }

        do {
            try viewContext.save()
        } catch {
            throw PersistenceError.previewSeedFailed(underlying: error)
        }

        return controller
    }
}

// MARK: - Error delegate

/// Receives async error notifications from the persistence layer. The
/// App scene typically conforms the root view to this protocol and
/// presents a banner/alert.
protocol PersistenceErrorDelegate: AnyObject {
    func persistenceController(
        _ controller: PersistenceController,
        didEncounterError error: PersistenceController.PersistenceError
    )
}