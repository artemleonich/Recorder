//
//  NotesListViewModel.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import Combine
import AVFoundation
import OSLog

@MainActor
final class NotesListViewModel: ObservableObject {

    @Published var notes: [AudioNote] = []
    @Published var searchQuery: String = ""
    @Published var filteredNotes: [AudioNote] = []
    @Published var isLoading: Bool = false
    @Published var error: RecorderError?
    @Published var showImportPicker: Bool = false

    private let storageService: NotesStorageService
    private let fileStorageService: FileStorageService
    private let transcriptionService: TranscriptionService
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.app.recorder", category: "notes")

    private var cancellables = Set<AnyCancellable>()

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

    func importAudioFile(_ url: URL) async {
        logger.info("Importing audio file: \(url.lastPathComponent)")

        guard settings.allowAudioImport else {
            error = .importFailed(NSError(
                domain: "NotesListViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Audio import is disabled in settings"]
            ))
            logger.warning("Audio import is disabled in settings")
            return
        }

        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

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
            let fileName = "\(UUID().uuidString).\(fileExtension)"

            let destinationURL = try fileStorageService.saveAudioFile(from: url, withName: fileName)
            logger.info("Copied audio file to: \(destinationURL.path)")

            let asset = AVAsset(url: destinationURL)
            let duration = try await asset.load(.duration)
            let durationInSeconds = CMTimeGetSeconds(duration)

            logger.debug("Audio duration: \(durationInSeconds)s")

            let title = DateFormatter.noteTitle.string(from: Date())
            let languageCode = settings.localeIdentifier ?? "ru"

            let note = try storageService.createNote(
                title: title,
                audioFileName: fileName,
                duration: durationInSeconds,
                languageCode: languageCode
            )

            logger.info("Created note from imported file: \(note.id)")

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

    private func setupBindings() {
        storageService.$notes
            .assign(to: &$notes)

        Publishers.CombineLatest($searchQuery, $notes)
            .map { [weak self] query, notes in
                guard let self = self else { return [] }
                return self.storageService.searchNotes(query: query)
            }
            .assign(to: &$filteredNotes)
    }

    private func startTranscription(
        audioURL: URL,
        noteID: UUID,
        languageCode: String
    ) {
        logger.info("Starting transcription for imported note: \(noteID)")

        Task {
            let mode = await MainActor.run { settings.transcriptionModeEnum }

            let progressStream = await transcriptionService.transcribe(
                audioURL: audioURL,
                noteID: noteID,
                languageCode: languageCode,
                mode: mode
            )

            for await progress in progressStream {
                logger.debug("Import transcription progress: \(Int(progress * 100))%")
            }

            logger.info("Transcription completed for imported note: \(noteID)")
        }
    }
}
