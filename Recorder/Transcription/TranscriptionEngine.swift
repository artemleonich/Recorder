//
//  TranscriptionEngine.swift
//  Recorder
//
//  Protocol defining the interface for transcription engines
//

import Foundation

/// Protocol for transcription engines that convert audio to text
protocol TranscriptionEngine: Actor {
    
    /// Prepares the transcription model for use
    /// - Parameters:
    ///   - mode: The transcription mode (fast or accurate)
    ///   - languageCode: The language code for transcription (e.g., "ru", "en")
    /// - Throws: RecorderError if model preparation fails
    func prepareModel(mode: TranscriptionMode, languageCode: String) async throws
    
    /// Transcribes audio from a file URL
    /// - Parameters:
    ///   - audioURL: URL to the audio file to transcribe
    ///   - languageCode: The language code for transcription (e.g., "ru", "en")
    ///   - progressHandler: Closure called with progress updates (0.0 to 1.0)
    /// - Returns: TranscriptionResult containing the transcribed text and segments
    /// - Throws: RecorderError if transcription fails
    func transcribe(
        audioURL: URL,
        languageCode: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> TranscriptionResult
    
    /// Cancels the current transcription operation
    func cancelTranscription() async
}
