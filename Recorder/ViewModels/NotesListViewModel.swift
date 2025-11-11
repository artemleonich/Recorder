//
//  NotesListViewModel.swift
//  Recorder
//
//  ViewModel for managing the notes list and search functionality
//

import Foundation
import Combine
import AVFoundation
import OSLog

/// ViewModel for the notes list screen
@MainActor
final class NotesListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All notes from storage
    @Published var notes: [AudioNote] = []
    
    /// Current search query
    @Published var searchQuery: String = ""
    
    /// Filtered notes based on search query
    @Published var filteredNotes: [AudioNote] = []
    
    /// Indicates whether notes are being loaded
    @Published var isLoading: Bool = false
    
    /// Current error, if any
    @Published var error: RecorderError?
    
    /// Shows import file picker
    @Published var showImportPicker: Bool = false
    
    // MARK: - Private Properties
    
    private let storageService: NotesStorageService
    private let fileStorageService: FileStorageService
    private let transcriptionService: TranscriptionService
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.app.recorder", category: "notes")
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        storageService: NotesStorageService,
        fileStorageService: FileStorageService,
        transcriptionService: TranscriptionService,
        settings: AppSettings
    ) {
        self.storageService = storageService
        self.fileStorageService = fileStorageService
        self.transcriptionService = transcriptionService
        self.settings = settings
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Loads all notes from storage
    /// Optimized for fast loading (target: < 0.5s for 100 notes)
    func loadNotes() async {
        logger.info("Loading notes")
        isLoading = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try storageService.fetchAllNotes()
            
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("Loaded \(self.notes.count) notes in \(String(format: "%.3f", loadTime))s")
        } catch {
            self.error = error as? RecorderError ?? .generic(error)
            logger.error("Failed to load notes: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Deletes a note and its associated audio file
    /// - Parameter note: The note to delete
    func deleteNote(_ note: AudioNote) async {
        logger.info("Deleting note: \(note.id)")
        
        do {
            try storageService.deleteNote(note.id)
            logger.info("Successfully deleted note: \(note.id)")
        } catch {
            self.error = error as? RecorderError ?? .generic(error)
            logger.error("Failed to delete note: \(error.localizedDescription)")
        }
    }
    
    /// Creates a NoteDetailView for a given note
    /// - Parameter note: The note to display
    /// - Returns: NoteDetailView configured for the note
    func createNoteDetailView(for note: AudioNote) -> NoteDetailView {
        let audioPlayer = AudioPlayerService()
        let noteDetailViewModel = NoteDetailViewModel(
            note: note,
            audioPlayer: audioPlayer,
            storageService: storageService,
            fileStorageService: fileStorageService,
            settings: settings
        )
        return NoteDetailView(viewModel: noteDetailViewModel)
    }
    
    /// Imports an audio file from an external source
    /// - Parameter url: URL of the audio file to import
    func importAudioFile(_ url: URL) async {
        logger.info("Importing audio file: \(url.lastPathComponent)")
        
        // Check if audio import is allowed in settings
        guard settings.allowAudioImport else {
            error = .importFailed(NSError(
                domain: "NotesListViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Audio import is disabled in settings"]
            ))
            logger.warning("Audio import is disabled in settings")
            return
        }
        
        // Gain access to security-scoped resource if needed
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Validate file extension
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions = ["m4a", "mp3", "wav", "aac", "caf"]

        guard !fileExtension.isEmpty, supportedExtensions.contains(fileExtension) else {
            error = .importFailed(NSError(
                domain: "NotesListViewModel",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Unsupported file format: \(fileExtension.isEmpty ? "unknown" : fileExtension)"]
            ))
            logger.warning("Unsupported file format: \(fileExtension.isEmpty ? "none" : fileExtension)")
            return
        }

        do {
            // Generate unique filename preserving extension
            let fileName = "\(UUID().uuidString).\(fileExtension)"
            
            // Copy file to recordings directory
            let destinationURL = try fileStorageService.saveAudioFile(from: url, withName: fileName)
            logger.info("Copied audio file to: \(destinationURL.path)")
            
            // Determine audio duration using AVAsset
            let asset = AVAsset(url: destinationURL)
            let duration = try await asset.load(.duration)
            let durationInSeconds = CMTimeGetSeconds(duration)
            
            logger.debug("Audio duration: \(durationInSeconds)s")
            
            // Generate title in format "DD.MM.YYYY HH:MM"
            let title = DateFormatter.noteTitle.string(from: Date())
            
            // Get language code from settings
            let languageCode = settings.localeIdentifier ?? "ru"
            
            // Create note in storage
            let note = try storageService.createNote(
                title: title,
                audioFileName: fileName,
                duration: durationInSeconds,
                languageCode: languageCode
            )
            
            logger.info("Created note from imported file: \(note.id)")
            
            // Start transcription in background
            startTranscription(
                audioURL: destinationURL,
                noteID: note.id,
                languageCode: languageCode
            )
            
        } catch {
            self.error = .importFailed(error)
            logger.error("Failed to import audio file: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up bindings for automatic filtering
    private func setupBindings() {
        // Bind notes from storage service
        storageService.$notes
            .assign(to: &$notes)
        
        // Automatically filter notes when search query or notes change
        Publishers.CombineLatest($searchQuery, $notes)
            .map { [weak self] query, notes in
                guard let self = self else { return [] }
                return self.storageService.searchNotes(query: query)
            }
            .assign(to: &$filteredNotes)
    }
    
    /// Starts transcription for an imported audio file
    private func startTranscription(
        audioURL: URL,
        noteID: UUID,
        languageCode: String
    ) {
        logger.info("Starting transcription for imported note: \(noteID)")
        
        Task {
            // Get transcription mode from settings
            let mode = settings.transcriptionModeEnum
            
            // Start transcription with progress updates
            let progressStream = await transcriptionService.transcribe(
                audioURL: audioURL,
                noteID: noteID,
                languageCode: languageCode,
                mode: mode
            )
            
            // Consume progress updates (we don't display them in the list view)
            for await progress in progressStream {
                logger.debug("Import transcription progress: \(Int(progress * 100))%")
            }
            
            logger.info("Transcription completed for imported note: \(noteID)")
        }
    }
}
