//
//  RecordingViewModel.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import Combine
import OSLog
import AVFoundation

@MainActor
final class RecordingViewModel: ObservableObject {

    @Published var isRecording: Bool = false
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var isTranscribing: Bool = false
    @Published var transcriptionProgress: Double = 0
    @Published var error: RecorderError?

    private let audioRecorder: AudioRecorderService
    private let transcriptionService: TranscriptionService
    private let storageService: NotesStorageService
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.app.recorder", category: "recording")

    private var cancellables = Set<AnyCancellable>()
    private var currentRecordingFileName: String?
    private var transcriptionTask: Task<Void, Never>?

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

    func startRecording() async {
        logger.info("Starting recording")

        let hasPermission = await audioRecorder.requestPermission()
        guard hasPermission else {
            error = .microphonePermissionDenied
            logger.warning("Microphone permission denied")
            return
        }

        let requiredBytes: Int64 = 50 * 1024 * 1024
        guard StorageUtility.hasSufficientStorage(requiredBytes: requiredBytes) else {
            error = .insufficientStorage
            logger.warning("Insufficient storage available")
            return
        }

        let fileName = UUID().uuidString
        currentRecordingFileName = fileName

        do {
            try await audioRecorder.startRecording(fileName: fileName)
            logger.info("Recording started successfully")
        } catch {
            currentRecordingFileName = nil
            self.error = error as? RecorderError ?? .recordingFailed(error)
            logger.error("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() async {
        logger.info("Stopping recording")

        guard let fileName = currentRecordingFileName else {
            logger.error("No active recording to stop")
            return
        }

        do {
            let audioURL = try await audioRecorder.stopRecording()
            logger.info("Recording stopped, file: \(audioURL.lastPathComponent)")

            let title = DateFormatter.noteTitle.string(from: Date())
            let duration = self.duration
            let languageCode = settings.localeIdentifier ?? "ru"

            // audioURL already includes .m4a extension
            let audioFileName = audioURL.lastPathComponent
            let note = try storageService.createNote(
                title: title,
                audioFileName: audioFileName,
                duration: duration,
                languageCode: languageCode
            )

            logger.info("Created note: \(note.id)")

            startTranscription(
                audioURL: audioURL,
                noteID: note.id,
                languageCode: languageCode
            )

            currentRecordingFileName = nil

        } catch {
            currentRecordingFileName = nil
            self.error = error as? RecorderError ?? .recordingFailed(error)
            logger.error("Failed to stop recording: \(error.localizedDescription)")
        }
    }

    func cancelRecording() async {
        logger.info("Cancelling recording")
        await audioRecorder.cancelRecording()
        currentRecordingFileName = nil
        logger.info("Recording cancelled")
    }

    private func setupBindings() {
        audioRecorder.$isRecording
            .assign(to: &$isRecording)

        audioRecorder.$currentDuration
            .assign(to: &$duration)

        audioRecorder.$audioLevel
            .assign(to: &$audioLevel)
    }

    private func startTranscription(
        audioURL: URL,
        noteID: UUID,
        languageCode: String
    ) {
        logger.info("Starting transcription for note: \(noteID)")

        isTranscribing = true
        transcriptionProgress = 0

        transcriptionTask?.cancel()

        transcriptionTask = Task { @MainActor in
            let mode = settings.transcriptionModeEnum

            let progressStream = await transcriptionService.transcribe(
                audioURL: audioURL,
                noteID: noteID,
                languageCode: languageCode,
                mode: mode
            )

            for await progress in progressStream {
                guard !Task.isCancelled else {
                    logger.info("Transcription task cancelled")
                    break
                }

                transcriptionProgress = progress
                logger.debug("Transcription progress: \(Int(progress * 100))%")
            }

            isTranscribing = false
            transcriptionProgress = 0
            logger.info("Transcription completed for note: \(noteID)")
        }
    }

    deinit {
        transcriptionTask?.cancel()
        logger.debug("RecordingViewModel deinitialized")
    }
}
