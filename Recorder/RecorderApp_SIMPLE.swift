//
//  RecorderApp.swift
//  Recorder
//
//  Simple working version
//

import SwiftUI
import CoreData

@main
struct RecorderApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
