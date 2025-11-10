//
//  TranscriptionService.swift
//  Recorder
//
//  Service for coordinating audio transcription operations
//

import Foundation
import OSLog

/// Actor-based service for managing transcription operations
actor TranscriptionService {
    
    // MARK: - Properties
    
    /// The transcription engine to use
    private let engine: TranscriptionEngine
    
    /// Storage service for updating notes
    private let storageService: NotesStorageService
    
    /// Dictionary of active transcription tasks by note ID
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    /// Logger for transcription events
    private nonisolated let logger = Logger.transcription
    
    /// Flag to track if model has been prepared
    private var isModelPrepared = false
    
    /// Current transcription mode
    private var currentMode: TranscriptionMode?
    
    // MARK: - Initialization
    
    init(
        engine: TranscriptionEngine = WhisperTranscriptionEngine(),
        storageService: NotesStorageService
    ) {
        self.engine = engine
        self.storageService = storageService
        logger.debug("TranscriptionService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Transcribes an audio file and updates the associated note
    /// Optimized to load Whisper model only once per mode
    /// - Parameters:
    ///   - audioURL: URL to the audio file
    ///   - noteID: ID of the note to update
    ///   - languageCode: Language code for transcription (e.g., "ru", "en")
    ///   - mode: Transcription mode (fast or accurate)
    /// - Returns: AsyncStream of progress updates (0.0 to 1.0)
    func transcribe(
        audioURL: URL,
        noteID: UUID,
        languageCode: String,
        mode: TranscriptionMode
    ) -> AsyncStream<Double> {
        logger.info("Starting transcription for note: \(noteID), mode: \(mode.rawValue)")
        
        return AsyncStream { continuation in
            // Create a task for the transcription
            let task = Task {
                do {
                    // Prepare model if needed (only once per mode)
                    let needsPreparation = await self.needsModelPreparation(mode: mode)
                    if needsPreparation {
                        logger.info("Loading Whisper model for mode: \(mode.rawValue) (one-time operation)")
                        let loadStartTime = CFAbsoluteTimeGetCurrent()
                        
                        try await engine.prepareModel(mode: mode, languageCode: languageCode)
                        await self.setModelPrepared(mode: mode)
                        
                        let loadTime = CFAbsoluteTimeGetCurrent() - loadStartTime
                        logger.info("Model loaded in \(String(format: "%.2f", loadTime))s")
                    } else {
                        logger.debug("Using cached Whisper model for mode: \(mode.rawValue)")
                    }
                    
                    // Perform transcription with progress updates
                    let result = try await engine.transcribe(
                        audioURL: audioURL,
                        languageCode: languageCode
                    ) { progress in
                        continuation.yield(progress)
                    }
                    
                    // Update the note with transcription result
                    Task { @MainActor in
                        do {
                            try storageService.updateNoteTranscript(noteID, transcript: result.text)
                            try storageService.updateTranscriptionStatus(noteID, isCompleted: true)
                            logger.info("Successfully updated note \(noteID) with transcription")
                        } catch {
                            logger.error("Failed to update note with transcription: \(error.localizedDescription)")
                        }
                    }
                    
                    // Complete the stream
                    continuation.finish()
                    
                } catch {
                    logger.error("Transcription failed for note \(noteID): \(error.localizedDescription)")
                    
                    // Mark transcription as failed but completed
                    Task { @MainActor in
                        do {
                            try storageService.updateTranscriptionStatus(noteID, isCompleted: true)
                        } catch {
                            logger.error("Failed to update transcription status: \(error.localizedDescription)")
                        }
                    }
                    
                    continuation.finish()
                }
                
                // Remove task from active tasks
                await self.removeActiveTask(noteID: noteID)
            }
            
            // Store the task
            Task {
                await self.storeActiveTask(noteID: noteID, task: task)
            }
        }
    }
    
    /// Retries transcription for a note
    /// - Parameters:
    ///   - noteID: ID of the note to retry transcription for
    ///   - audioURL: URL to the audio file
    ///   - languageCode: Language code for transcription
    ///   - mode: Transcription mode
    /// - Returns: AsyncStream of progress updates
    func retryTranscription(
        noteID: UUID,
        audioURL: URL,
        languageCode: String,
        mode: TranscriptionMode
    ) -> AsyncStream<Double> {
        logger.info("Retrying transcription for note: \(noteID)")
        
        // Cancel any existing transcription for this note
        Task {
            await cancelTranscription(noteID: noteID)
        }
        
        // Start a new transcription
        return transcribe(
            audioURL: audioURL,
            noteID: noteID,
            languageCode: languageCode,
            mode: mode
        )
    }
    
    /// Cancels transcription for a specific note
    /// - Parameter noteID: ID of the note whose transcription should be cancelled
    func cancelTranscription(noteID: UUID) async {
        logger.info("Cancelling transcription for note: \(noteID)")
        
        if let task = activeTasks[noteID] {
            task.cancel()
            activeTasks.removeValue(forKey: noteID)
            
            // Also cancel the engine's current task
            await engine.cancelTranscription()
            
            logger.debug("Cancelled transcription task for note: \(noteID)")
        } else {
            logger.debug("No active transcription task found for note: \(noteID)")
        }
    }
    
    /// Cancels all active transcriptions
    func cancelAllTranscriptions() async {
        logger.info("Cancelling all active transcriptions")
        
        for (noteID, task) in activeTasks {
            task.cancel()
            logger.debug("Cancelled transcription for note: \(noteID)")
        }
        
        activeTasks.removeAll()
        await engine.cancelTranscription()
    }
    
    // MARK: - Private Methods
    
    private func needsModelPreparation(mode: TranscriptionMode) -> Bool {
        return !isModelPrepared || currentMode != mode
    }
    
    private func setModelPrepared(mode: TranscriptionMode) {
        isModelPrepared = true
        currentMode = mode
    }
    
    private func storeActiveTask(noteID: UUID, task: Task<Void, Never>) {
        activeTasks[noteID] = task
        logger.debug("Stored active task for note: \(noteID). Total active: \(self.activeTasks.count)")
    }
    
    private func removeActiveTask(noteID: UUID) {
        activeTasks.removeValue(forKey: noteID)
        logger.debug("Removed active task for note: \(noteID). Total active: \(self.activeTasks.count)")
    }
}
