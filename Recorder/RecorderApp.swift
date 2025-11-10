//
//  RecorderApp.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import SwiftUI
import CoreData

// MARK: - Shared Services

private class ServiceContainer {
    static let shared = ServiceContainer()
    
    let fileStorageService: FileStorageService
    let notesStorageService: NotesStorageService
    let audioRecorderService: AudioRecorderService
    let transcriptionService: TranscriptionService
    
    private init() {
        self.fileStorageService = FileStorageService()
        self.audioRecorderService = AudioRecorderService(fileStorageService: fileStorageService)
        self.notesStorageService = NotesStorageService(
            persistenceController: PersistenceController.shared,
            fileStorageService: fileStorageService
        )
        self.transcriptionService = TranscriptionService(storageService: notesStorageService)
    }
}

@main
struct RecorderApp: App {
    // MARK: - Persistence
    
    let persistenceController = PersistenceController.shared
    
    // MARK: - Settings
    
    @StateObject private var appSettings = AppSettings.shared
    
    // MARK: - ViewModels
    
    @StateObject private var recordingViewModel: RecordingViewModel
    @StateObject private var notesListViewModel: NotesListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    // MARK: - Initialization
    
    init() {
        let services = ServiceContainer.shared
        
        _recordingViewModel = StateObject(wrappedValue: RecordingViewModel(
            audioRecorder: services.audioRecorderService,
            transcriptionService: services.transcriptionService,
            storageService: services.notesStorageService,
            settings: AppSettings.shared
        ))
        
        _notesListViewModel = StateObject(wrappedValue: NotesListViewModel(
            storageService: services.notesStorageService,
            fileStorageService: services.fileStorageService,
            transcriptionService: services.transcriptionService,
            settings: AppSettings.shared
        ))
        
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(
            settings: AppSettings.shared,
            notesStorageService: services.notesStorageService
        ))
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView(
                recordingViewModel: recordingViewModel,
                notesListViewModel: notesListViewModel,
                settingsViewModel: settingsViewModel
            )
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(appSettings)
            .preferredColorScheme(appSettings.colorScheme)
            .environment(\.locale, appSettings.localeIdentifier != nil ? Locale(identifier: appSettings.localeIdentifier!) : .current)
            .id(appSettings.appLanguage + appSettings.appAppearance)
        }
    }
}
