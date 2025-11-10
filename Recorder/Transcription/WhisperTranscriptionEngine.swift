//
//  WhisperTranscriptionEngine.swift
//  Recorder
//
//  Implementation of TranscriptionEngine using WhisperKit
//

import Foundation
import WhisperKit
import OSLog

/// Actor-based transcription engine using WhisperKit for local speech-to-text
actor WhisperTranscriptionEngine: TranscriptionEngine {
    
    // MARK: - Properties
    
    /// WhisperKit instance for transcription
    private var whisperKit: WhisperKit?
    
    /// Current transcription task that can be cancelled
    private var currentTask: Task<TranscriptionResult, Error>?
    
    /// Logger for transcription events
    private nonisolated let logger = Logger.transcription
    
    /// Flag to track if model is prepared
    private var isModelPrepared = false
    
    /// Current transcription mode
    private var currentMode: TranscriptionMode?
    
    // MARK: - Initialization
    
    init() {
        logger.debug("WhisperTranscriptionEngine initialized")
    }
    
    // MARK: - TranscriptionEngine Protocol
    
    func prepareModel(mode: TranscriptionMode, languageCode: String) async throws {
        // If already prepared with the same mode, skip
        if isModelPrepared, currentMode == mode {
            logger.debug("Model already prepared for mode: \(mode.rawValue)")
            return
        }
        
        // Get model name (nonisolated access)
        let modelName: String
        switch mode {
        case .fast:
            modelName = "openai_whisper-base"
        case .accurate:
            modelName = "openai_whisper-small"
        }
        
        logger.info("Preparing Whisper model: \(modelName) for language: \(languageCode)")
        
        do {
            // Initialize WhisperKit with the specified model
            whisperKit = try await WhisperKit(model: modelName)
            isModelPrepared = true
            currentMode = mode
            logger.info("Successfully loaded Whisper model: \(modelName)")
        } catch {
            logger.error("Failed to load Whisper model: \(error.localizedDescription)")
            throw RecorderError.modelNotFound
        }
    }
    
    func transcribe(
        audioURL: URL,
        languageCode: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> TranscriptionResult {
        guard let whisperKit = whisperKit else {
            logger.error("WhisperKit not initialized. Call prepareModel() first.")
            throw RecorderError.modelNotFound
        }
        
        logger.info("Starting transcription for file: \(audioURL.lastPathComponent)")
        
        // Create a new task for transcription
        let task = Task<TranscriptionResult, Error> {
            do {
                // Configure decoding options
                let decodingOptions = DecodingOptions(
                    task: .transcribe,
                    language: languageCode,
                    temperature: 0.0,
                    temperatureIncrementOnFallback: 0.2,
                    temperatureFallbackCount: 5,
                    sampleLength: 224,
                    topK: 5,
                    usePrefillPrompt: true,
                    usePrefillCache: true,
                    skipSpecialTokens: true,
                    withoutTimestamps: false,
                    clipTimestamps: [],
                    chunkingStrategy: nil
                )
                
                // Track progress
                var progressCount = 0
                
                // Perform transcription
                let result = try await whisperKit.transcribe(
                    audioPath: audioURL.path,
                    decodeOptions: decodingOptions
                ) { progress in
                    // Report progress based on callback frequency
                    // Estimate progress as we don't have exact percentage from WhisperKit
                    progressCount += 1
                    let estimatedProgress = min(Double(progressCount) * 0.05, 0.95)
                    progressHandler(estimatedProgress)
                    self.logger.debug("Transcription progress callback: \(progressCount)")
                    return true // Continue transcription
                }
                
                // Check if task was cancelled
                try Task.checkCancellation()
                
                // WhisperKit returns an array of TranscriptionResult
                // Combine all results into one
                let allText = result.map { $0.text }.joined(separator: " ")
                var allSegments: [TranscriptionSegment] = []
                for whisperResult in result {
                    let segments = whisperResult.segments.map { segment in
                        TranscriptionSegment(
                            text: segment.text,
                            start: TimeInterval(segment.start),
                            end: TimeInterval(segment.end)
                        )
                    }
                    allSegments.append(contentsOf: segments)
                }
                
                let transcriptionResult = TranscriptionResult(
                    text: allText,
                    segments: allSegments
                )
                
                self.logger.info("Transcription completed successfully. Text length: \(allText.count) characters")
                
                // Report 100% completion
                progressHandler(1.0)
                
                return transcriptionResult
                
            } catch is CancellationError {
                self.logger.info("Transcription was cancelled")
                throw RecorderError.transcriptionFailed(NSError(
                    domain: "TranscriptionEngine",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Transcription was cancelled"]
                ))
            } catch {
                self.logger.error("Transcription failed: \(error.localizedDescription)")
                throw RecorderError.transcriptionFailed(error)
            }
        }
        
        // Store the task so it can be cancelled
        currentTask = task
        
        // Wait for the task to complete
        let result = try await task.value
        
        // Clear the task reference
        currentTask = nil
        
        return result
    }
    
    func cancelTranscription() async {
        if let task = currentTask {
            logger.info("Cancelling transcription task")
            task.cancel()
            currentTask = nil
        } else {
            logger.debug("No active transcription task to cancel")
        }
    }
}
