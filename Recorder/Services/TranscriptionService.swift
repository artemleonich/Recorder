//
//  TranscriptionService.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import OSLog

actor TranscriptionService {

    private let engine: TranscriptionEngine
    private let storageService: NotesStorageService
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    private nonisolated let logger = Logger.transcription
    private var isModelPrepared = false
    private var currentMode: TranscriptionMode?

    init(
        engine: TranscriptionEngine = WhisperTranscriptionEngine(),
        storageService: NotesStorageService
    ) {
        self.engine = engine
        self.storageService = storageService
    }

    func transcribe(
        audioURL: URL,
        noteID: UUID,
        languageCode: String,
        mode: TranscriptionMode
    ) -> AsyncStream<Double> {
        logger.info("Starting transcription for note: \(noteID), mode: \(mode.rawValue)")

        return AsyncStream { continuation in
            let task = Task {
                do {
                    // Загрузка модели при первом использовании или смене режима
                    if !isModelPrepared || currentMode != mode {
                        let loadStartTime = CFAbsoluteTimeGetCurrent()
                        try await engine.prepareModel(mode: mode, languageCode: languageCode)
                        await self.setModelPrepared(mode: mode)
                        let loadTime = CFAbsoluteTimeGetCurrent() - loadStartTime
                        logger.info("Model loaded in \(String(format: "%.2f", loadTime))s")
                    }

                    let result = try await engine.transcribe(
                        audioURL: audioURL,
                        languageCode: languageCode
                    ) { progress in
                        continuation.yield(progress)
                    }

                    Task { @MainActor in
                        do {
                            try storageService.updateNoteTranscript(noteID, transcript: result.text)
                            try storageService.updateTranscriptionStatus(noteID, isCompleted: true)
                        } catch {
                            logger.error("Failed to update note with transcription: \(error.localizedDescription)")
                        }
                    }

                    continuation.finish()
                } catch {
                    logger.error("Transcription failed for note \(noteID): \(error.localizedDescription)")

                    Task { @MainActor in
                        do {
                            // The transcription itself failed, so the
                            // note is NOT marked as completed — flipping
                            // this flag to true would let the UI show
                            // a misleading "Done" badge for a note that
                            // has no usable transcript. The previous
                            // version of this code wrote isCompleted:
                            // true in the catch block, which surfaced
                            // in the Notes list as a permanent
                            // "completed" badge on notes whose
                            // transcripts were missing or empty.
                            try storageService.updateTranscriptionStatus(noteID, isCompleted: false)
                        } catch {
                            logger.error("Failed to update transcription status: \(error.localizedDescription)")
                        }
                    }

                    continuation.finish()
                }

                await self.removeActiveTask(noteID: noteID)
            }

            Task {
                await self.storeActiveTask(noteID: noteID, task: task)
            }
        }
    }

    func retryTranscription(
        noteID: UUID,
        audioURL: URL,
        languageCode: String,
        mode: TranscriptionMode
    ) -> AsyncStream<Double> {
        Task {
            await cancelTranscription(noteID: noteID)
        }

        return transcribe(
            audioURL: audioURL,
            noteID: noteID,
            languageCode: languageCode,
            mode: mode
        )
    }

    func cancelTranscription(noteID: UUID) async {
        if let task = activeTasks[noteID] {
            task.cancel()
            activeTasks.removeValue(forKey: noteID)
            await engine.cancelTranscription()
        }
    }

    func cancelAllTranscriptions() async {
        for (_, task) in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        await engine.cancelTranscription()
    }

    // MARK: - Private

    private func setModelPrepared(mode: TranscriptionMode) {
        isModelPrepared = true
        currentMode = mode
    }

    private func storeActiveTask(noteID: UUID, task: Task<Void, Never>) {
        activeTasks[noteID] = task
    }

    private func removeActiveTask(noteID: UUID) {
        activeTasks.removeValue(forKey: noteID)
    }
}
