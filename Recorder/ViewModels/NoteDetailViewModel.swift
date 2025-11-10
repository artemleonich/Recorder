//
//  NoteDetailViewModel.swift
//  Recorder
//
//  ViewModel for managing note details, playback, and editing
//

import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
import OSLog

/// ViewModel for the note detail screen
@MainActor
final class NoteDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current note being displayed
    @Published var note: AudioNote
    
    /// Indicates whether audio is currently playing
    @Published var isPlaying: Bool = false
    
    /// Current playback time in seconds
    @Published var currentTime: TimeInterval = 0
    
    /// Total duration of the audio in seconds
    @Published var duration: TimeInterval = 0
    
    /// Current error, if any
    @Published var error: RecorderError?
    
    // MARK: - Private Properties
    
    private let audioPlayer: AudioPlayerService
    private let storageService: NotesStorageService
    private let fileStorageService: FileStorageService
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.app.recorder", category: "noteDetail")
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        note: AudioNote,
        audioPlayer: AudioPlayerService,
        storageService: NotesStorageService,
        fileStorageService: FileStorageService,
        settings: AppSettings
    ) {
        self.note = note
        self.audioPlayer = audioPlayer
        self.storageService = storageService
        self.fileStorageService = fileStorageService
        self.settings = settings
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Loads the audio file for playback
    func loadAudio() async {
        logger.info("Loading audio for note: \(self.note.id)")
        
        do {
            // Get audio file URL
            let audioURL = try fileStorageService.getAudioFileURL(fileName: self.note.audioFileName)
            
            // Load audio into player
            try await audioPlayer.loadAudio(url: audioURL)
            
            logger.info("Audio loaded successfully")
            
        } catch {
            self.error = error as? RecorderError ?? .audioFileNotFound
            logger.error("Failed to load audio: \(error.localizedDescription)")
        }
    }
    
    /// Toggles between play and pause states
    func togglePlayPause() async {
        if isPlaying {
            audioPlayer.pause()
            logger.debug("Playback paused")
        } else {
            do {
                try await audioPlayer.play()
                logger.debug("Playback started")
            } catch {
                self.error = error as? RecorderError ?? .generic(error)
                logger.error("Failed to start playback: \(error.localizedDescription)")
            }
        }
    }
    
    /// Seeks to a specific time in the audio
    /// - Parameter time: Time position in seconds
    func seek(to time: TimeInterval) {
        audioPlayer.seek(to: time)
        logger.debug("Seeked to \(time)s")
    }
    
    /// Skips forward by 10 seconds
    func skipForward() {
        audioPlayer.skipForward(seconds: 10)
        logger.debug("Skipped forward 10s")
    }
    
    /// Skips backward by 10 seconds
    func skipBackward() {
        audioPlayer.skipBackward(seconds: 10)
        logger.debug("Skipped backward 10s")
    }
    
    /// Updates the note's title
    /// - Parameter newTitle: The new title for the note
    func updateTitle(_ newTitle: String) async {
        logger.info("Updating title for note: \(self.note.id)")
        
        guard newTitle != self.note.title else {
            logger.debug("Title unchanged, skipping update")
            return
        }
        
        do {
            try storageService.updateNoteTitle(self.note.id, title: newTitle)
            self.note.title = newTitle
            logger.info("Title updated successfully")
        } catch {
            self.error = error as? RecorderError ?? .generic(error)
            logger.error("Failed to update title: \(error.localizedDescription)")
        }
    }
    
    /// Updates the note's transcript
    /// - Parameter newTranscript: The new transcript text
    func updateTranscript(_ newTranscript: String) async {
        logger.info("Updating transcript for note: \(self.note.id)")
        
        guard newTranscript != self.note.transcript else {
            logger.debug("Transcript unchanged, skipping update")
            return
        }
        
        do {
            try storageService.updateNoteTranscript(self.note.id, transcript: newTranscript)
            self.note.transcript = newTranscript
            logger.info("Transcript updated successfully")
        } catch {
            self.error = error as? RecorderError ?? .generic(error)
            logger.error("Failed to update transcript: \(error.localizedDescription)")
        }
    }
    
    /// Shares the transcript text using UIActivityViewController
    /// - Returns: The formatted text to share
    func shareTranscript() -> String {
        logger.info("Sharing transcript for note: \(self.note.id)")
        
        // Format text: "{title}\n{date}\n\n{transcript}"
        let dateString = DateFormatter.noteDate.string(from: self.note.createdAt)
        let shareText = """
        \(self.note.title)
        \(dateString)
        
        \(self.note.transcript)
        """
        
        // If autoBackup is enabled, copy to clipboard
        if settings.autoBackup {
            #if canImport(UIKit)
            UIPasteboard.general.string = shareText
            logger.info("Transcript copied to clipboard (autoBackup enabled)")
            #endif
        }
        
        return shareText
    }
    
    // MARK: - Private Methods
    
    /// Sets up bindings to audio player properties
    private func setupBindings() {
        // Bind playing state
        audioPlayer.$isPlaying
            .assign(to: &$isPlaying)
        
        // Bind current time
        audioPlayer.$currentTime
            .assign(to: &$currentTime)
        
        // Bind duration
        audioPlayer.$duration
            .assign(to: &$duration)
        
        // Subscribe to note updates from storage service
        let noteID = self.note.id
        storageService.$notes
            .compactMap { (notes: [AudioNote]) -> AudioNote? in
                return notes.first(where: { $0.id == noteID })
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (updatedNote: AudioNote) in
                guard let self = self else { return }
                let transcriptChanged = self.note.transcript != updatedNote.transcript
                let titleChanged = self.note.title != updatedNote.title
                let statusChanged = self.note.isTranscriptionCompleted != updatedNote.isTranscriptionCompleted
                
                if transcriptChanged || titleChanged || statusChanged {
                    self.note = updatedNote
                    self.logger.debug("Note updated from storage: \(updatedNote.id)")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Deinitialization
    
    deinit {
        // Stop playback when view model is deallocated
        Task { @MainActor in
            audioPlayer.stop()
        }
        logger.debug("NoteDetailViewModel deinitialized")
    }
}
