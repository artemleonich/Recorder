//
//  WhisperTranscriptionEngine.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import WhisperKit
import OSLog

actor WhisperTranscriptionEngine: TranscriptionEngine {

    private var whisperKit: WhisperKit?
    private var currentTask: Task<TranscriptionResult, Error>?
    private nonisolated let logger = Logger.transcription
    private var isModelPrepared = false
    private var currentMode: TranscriptionMode?

    func prepareModel(mode: TranscriptionMode, languageCode: String) async throws {
        if isModelPrepared, currentMode == mode { return }

        let modelName: String
        switch mode {
        case .fast:
            modelName = "openai_whisper-base"
        case .accurate:
            modelName = "openai_whisper-small"
        }

        logger.info("Preparing Whisper model: \(modelName)")

        do {
            whisperKit = try await WhisperKit(model: modelName)
            isModelPrepared = true
            currentMode = mode
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
            throw RecorderError.modelNotFound
        }

        logger.info("Starting transcription for file: \(audioURL.lastPathComponent)")

        let task = Task<TranscriptionResult, Error> {
            do {
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

                var progressCount = 0

                let result = try await whisperKit.transcribe(
                    audioPath: audioURL.path,
                    decodeOptions: decodingOptions
                ) { progress in
                    progressCount += 1
                    let estimatedProgress = min(Double(progressCount) * 0.05, 0.95)
                    progressHandler(estimatedProgress)
                    return true
                }

                try Task.checkCancellation()

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

                progressHandler(1.0)

                return TranscriptionResult(text: allText, segments: allSegments)

            } catch is CancellationError {
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

        currentTask = task
        let result = try await task.value
        currentTask = nil
        return result
    }

    func cancelTranscription() async {
        currentTask?.cancel()
        currentTask = nil
    }
}
