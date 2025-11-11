//
//  RecordingViewModel.swift
//  Recorder
//
//  ViewModel for managing recording state and transcription
//

import Foundation
import Combine
import OSLog
import AVFoundation

/// ViewModel for the recording screen
@MainActor
final class RecordingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates whether recording is currently active
    @Published var isRecording: Bool = false
    
    /// Current duration of the recording in seconds
    @Published var duration: TimeInterval = 0
    
    /// Current audio level in decibels
    @Published var audioLevel: Float = 0
    
    /// Indicates whether transcription is in progress
    @Published var isTranscribing: Bool = false
    
    /// Progress of transcription (0.0 to 1.0)
    @Published var transcriptionProgress: Double = 0
    
    /// Current error, if any
    @Published var error: RecorderError?
    
    // MARK: - Private Properties
    
    private let audioRecorder: AudioRecorderService
    private let transcriptionService: TranscriptionService
    private let storageService: NotesStorageService
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.app.recorder", category: "recording")
    
    private var cancellables = Set<AnyCancellable>()
    private var currentRecordingFileName: String?
    private var transcriptionTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(
        audioRecorder: AudioRecorderService,
        transcriptionService: TranscriptionService,
        storageService: NotesStorageService,
        settings: AppSettings
    ) {
        self.audioRecorder = audioRecorder
        self.transcriptionService = transcriptionService
        self.storageService = storageService
        self.settings = settings
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Starts recording audio
    func startRecording() async {
        logger.info("Starting recording")
        
        // Check microphone permission
        let hasPermission = await audioRecorder.requestPermission()
        guard hasPermission else {
            error = .microphonePermissionDenied
            logger.warning("Microphone permission denied")
            return
        }
        
        // Check available storage (require at least 50 MB)
        let requiredBytes: Int64 = 50 * 1024 * 1024 // 50 MB
        guard StorageUtility.hasSufficientStorage(requiredBytes: requiredBytes) else {
            error = .insufficientStorage
            logger.warning("Insufficient storage available")
            return
        }
        
        // Generate unique filename
        let fileName = UUID().uuidString
        currentRecordingFileName = fileName
        
        do {
            // Start recording
            try await audioRecorder.startRecording(fileName: fileName)
            logger.info("Recording started successfully")
        } catch {
            currentRecordingFileName = nil
            self.error = error as? RecorderError ?? .recordingFailed(error)
            logger.error("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    /// Stops recording and initiates transcription
    func stopRecording() async {
        logger.info("Stopping recording")
        
        guard let fileName = currentRecordingFileName else {
            logger.error("No active recording to stop")
            return
        }
        
        do {
            // Stop recording and get file URL
            let audioURL = try await audioRecorder.stopRecording()
            logger.info("Recording stopped, file: \(audioURL.lastPathComponent)")
            
            // Generate title in format "DD.MM.YYYY HH:MM"
            let title = DateFormatter.noteTitle.string(from: Date())
            
            // Get audio duration
            let duration = self.duration
            
            // Get language code from settings
            let languageCode = settings.localeIdentifier ?? "ru"
            
            // Create note in storage
            // Note: audioURL already includes .m4a extension
            let audioFileName = audioURL.lastPathComponent
            let note = try storageService.createNote(
                title: title,
                audioFileName: audioFileName,
                duration: duration,
                languageCode: languageCode
            )
            
            logger.info("Created note: \(note.id)")
            
            // Start transcription in background
            startTranscription(
                audioURL: audioURL,
                noteID: note.id,
                languageCode: languageCode
            )
            
            // Reset recording state
            currentRecordingFileName = nil

        } catch {
            currentRecordingFileName = nil
            self.error = error as? RecorderError ?? .recordingFailed(error)
            logger.error("Failed to stop recording: \(error.localizedDescription)")
        }
    }
    
    /// Cancels the current recording
    func cancelRecording() async {
        logger.info("Cancelling recording")
        
        await audioRecorder.cancelRecording()
        currentRecordingFileName = nil
        
        logger.info("Recording cancelled")
    }
    
    // MARK: - Private Methods
    
    /// Sets up bindings to audio recorder properties
    private func setupBindings() {
        // Bind recording state
        audioRecorder.$isRecording
            .assign(to: &$isRecording)
        
        // Bind duration
        audioRecorder.$currentDuration
            .assign(to: &$duration)
        
        // Bind audio level
        audioRecorder.$audioLevel
            .assign(to: &$audioLevel)
    }
    
    /// Starts transcription for a recorded audio file
    private func startTranscription(
        audioURL: URL,
        noteID: UUID,
        languageCode: String
    ) {
        logger.info("Starting transcription for note: \(noteID)")
        
        isTranscribing = true
        transcriptionProgress = 0
        
        // Cancel any existing transcription task
        transcriptionTask?.cancel()
        
        // Create new transcription task
        transcriptionTask = Task { @MainActor in
            // Get transcription mode from settings
            let mode = settings.transcriptionModeEnum
            
            // Start transcription with progress updates
            let progressStream = await transcriptionService.transcribe(
                audioURL: audioURL,
                noteID: noteID,
                languageCode: languageCode,
                mode: mode
            )
            
            // Consume progress updates
            for await progress in progressStream {
                guard !Task.isCancelled else {
                    logger.info("Transcription task cancelled")
                    break
                }
                
                transcriptionProgress = progress
                logger.debug("Transcription progress: \(Int(progress * 100))%")
            }
            
            // Transcription complete
            isTranscribing = false
            transcriptionProgress = 0
            logger.info("Transcription completed for note: \(noteID)")
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        transcriptionTask?.cancel()
        logger.debug("RecordingViewModel deinitialized")
    }
}
