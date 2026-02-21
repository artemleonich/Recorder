//
//  PersistenceController.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
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
            let nsError = error as NSError
            fatalError("Unresolved error creating preview data: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RecorderDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error loading persistent store: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
