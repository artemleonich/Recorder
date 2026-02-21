//
//  NoteDetailViewModel.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
import OSLog

@MainActor
final class NoteDetailViewModel: ObservableObject {

    @Published var note: AudioNote
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var error: RecorderError?

    private let audioPlayer: AudioPlayerService
    private let storageService: NotesStorageService
    private let fileStorageService: FileStorageService
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.app.recorder", category: "noteDetail")

    private var cancellables = Set<AnyCancellable>()

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

    func loadAudio() async {
        logger.info("Loading audio for note: \(self.note.id)")

        do {
            let audioURL = try fileStorageService.getAudioFileURL(fileName: self.note.audioFileName)
            try await audioPlayer.loadAudio(url: audioURL)
            logger.info("Audio loaded successfully")
        } catch {
            self.error = error as? RecorderError ?? .audioFileNotFound
            logger.error("Failed to load audio: \(error.localizedDescription)")
        }
    }

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

    func seek(to time: TimeInterval) {
        audioPlayer.seek(to: time)
        logger.debug("Seeked to \(time)s")
    }

    func skipForward() {
        audioPlayer.skipForward(seconds: 10)
        logger.debug("Skipped forward 10s")
    }

    func skipBackward() {
        audioPlayer.skipBackward(seconds: 10)
        logger.debug("Skipped backward 10s")
    }

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

    func shareTranscript() -> String {
        logger.info("Sharing transcript for note: \(self.note.id)")

        let dateString = DateFormatter.noteDate.string(from: self.note.createdAt)
        let shareText = """
        \(self.note.title)
        \(dateString)

        \(self.note.transcript)
        """

        if settings.autoBackup {
            #if canImport(UIKit)
            UIPasteboard.general.string = shareText
            logger.info("Transcript copied to clipboard (autoBackup enabled)")
            #endif
        }

        return shareText
    }

    private func setupBindings() {
        audioPlayer.$isPlaying
            .assign(to: &$isPlaying)

        audioPlayer.$currentTime
            .assign(to: &$currentTime)

        audioPlayer.$duration
            .assign(to: &$duration)

        // Keep note in sync with storage updates
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

    deinit {
        Task { @MainActor in
            audioPlayer.stop()
        }
        logger.debug("NoteDetailViewModel deinitialized")
    }
}
