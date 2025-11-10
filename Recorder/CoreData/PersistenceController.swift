//
//  PersistenceController.swift
//  Recorder
//
//  Core Data stack controller with singleton instance and preview context
//

import CoreData

struct PersistenceController {
    // MARK: - Singleton Instance
    
    /// Shared singleton instance for production use
    static let shared = PersistenceController()
    
    /// Preview instance for SwiftUI previews with in-memory store
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample data for previews
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
    
    // MARK: - Core Data Stack
    
    let container: NSPersistentContainer
    
    // MARK: - Initialization
    
    /// Initialize the persistence controller
    /// - Parameter inMemory: If true, uses in-memory store (for testing/previews)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RecorderDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                // For now, we'll use fatalError for development
                fatalError("Unresolved error loading persistent store: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Save Context
    
    /// Save the view context if there are changes
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                // In production, handle this error appropriately
                fatalError("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
