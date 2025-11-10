//
//  RecordingIntegrationTests.swift
//  RecorderTests
//
//  Integration tests for the complete recording and transcription flow
//

import XCTest
import AVFoundation
@testable import Recorder

@MainActor
final class RecordingIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var audioRecorderService: AudioRecorderService!
    var transcriptionService: TranscriptionService!
    var notesStorageService: NotesStorageService!
    var fileStorageService: FileStorageService!
    var persistenceController: PersistenceController!
    var mockEngine: MockTranscriptionEngine!
    var testNoteIDs: [UUID] = []
    var testFileURLs: [URL] = []
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        persistenceController = PersistenceController(inMemory: true)
        
        // Create file storage service
        fileStorageService = FileStorageService()
        
        // Create notes storage service
        notesStorageService = NotesStorageService(
            persistenceController: persistenceController,
            fileStorageService: fileStorageService
        )
        
        // Create mock transcription engine
        mockEngine = MockTranscriptionEngine()
        
        // Create transcription service with mock engine
        transcriptionService = TranscriptionService(
            engine: mockEngine,
            storageService: notesStorageService
        )
        
        // Create audio recorder service
        audioRecorderService = AudioRecorderService(fileStorageService: fileStorageService)
        
        testNoteIDs = []
        testFileURLs = []
    }
    
    override func tearDown() async throws {
        // Clean up test notes
        for noteID in testNoteIDs {
            try? notesStorageService.deleteNote(noteID)
        }
        
        // Clean up test files
        for fileURL in testFileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        testNoteIDs = []
        testFileURLs = []
        audioRecorderService = nil
        transcriptionService = nil
        notesStorageService = nil
        fileStorageService = nil
        persistenceController = nil
        mockEngine = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test audio file for testing
    private func createTestAudioFile(fileName: String) throws -> URL {
        let recordingsDirectory = try fileStorageService.getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent("\(fileName).m4a")
        
        // Create a minimal valid M4A file
        // This is a minimal AAC/M4A header that AVAudioPlayer can recognize
        let testData = Data([
            0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70,
            0x4D, 0x34, 0x41, 0x20, 0x00, 0x00, 0x00, 0x00,
            0x4D, 0x34, 0x41, 0x20, 0x6D, 0x70, 0x34, 0x32,
            0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x00, 0x00
        ])
        
        try testData.write(to: fileURL)
        testFileURLs.append(fileURL)
        
        return fileURL
    }
    
    /// Simulates a recording by creating a test audio file
    private func simulateRecording(fileName: String) throws -> URL {
        return try createTestAudioFile(fileName: fileName)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteRecordingFlow_CreatesNoteAndTranscribes() async throws {
        // Given: A simulated recording
        let fileName = UUID().uuidString
        let audioURL = try simulateRecording(fileName: fileName)
        
        // Configure mock engine with expected result
        let expectedTranscript = "This is a test transcription from the recording"
        await mockEngine.setMockResult(TranscriptionResult(
            text: expectedTranscript,
            segments: [
                TranscriptionSegment(text: "This is a test", start: 0.0, end: 1.5),
                TranscriptionSegment(text: "transcription from the recording", start: 1.5, end: 3.0)
            ]
        ))
        
        // When: We create a note from the recording
        let note = try notesStorageService.createNote(
            title: "Test Recording",
            audioFileName: fileName,
            duration: 3.0,
            languageCode: "en"
        )
        testNoteIDs.append(note.id)
        
        // Then: Note should be created with correct initial state
        XCTAssertEqual(note.title, "Test Recording")
        XCTAssertEqual(note.audioFileName, fileName)
        XCTAssertEqual(note.duration, 3.0, accuracy: 0.01)
        XCTAssertEqual(note.languageCode, "en")
        XCTAssertEqual(note.transcript, "")
        XCTAssertFalse(note.isTranscriptionCompleted)
        
        // When: We start transcription
        let stream = await transcriptionService.transcribe(
            audioURL: audioURL,
            noteID: note.id,
            languageCode: "en",
            mode: .fast
        )
        
        // Consume the progress stream
        var progressUpdates: [Double] = []
        for await progress in stream {
            progressUpdates.append(progress)
        }
        
        // Wait for transcription to complete and update the note
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Then: Progress updates should be received
        XCTAssertFalse(progressUpdates.isEmpty, "Should receive progress updates")
        
        // Then: Note should be updated with transcription
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote, "Note should exist in storage")
        XCTAssertEqual(updatedNote?.transcript, expectedTranscript, "Transcript should be updated")
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false, "Transcription should be marked as completed")
        
        // Then: Audio file should exist on disk
        let audioFileExists = fileStorageService.audioFileExists(fileName: "\(fileName).m4a")
        XCTAssertTrue(audioFileExists, "Audio file should exist on disk")
    }
    
    func testCompleteRecordingFlow_WithMultipleNotes() async throws {
        // Given: Multiple simulated recordings
        let recordings = [
            (fileName: UUID().uuidString, title: "First Recording", transcript: "First transcription"),
            (fileName: UUID().uuidString, title: "Second Recording", transcript: "Second transcription"),
            (fileName: UUID().uuidString, title: "Third Recording", transcript: "Third transcription")
        ]
        
        var createdNotes: [AudioNote] = []
        
        // When: We create notes and transcribe them
        for recording in recordings {
            // Create audio file
            let audioURL = try simulateRecording(fileName: recording.fileName)
            
            // Configure mock engine
            await mockEngine.reset()
            await mockEngine.setMockResult(TranscriptionResult(
                text: recording.transcript,
                segments: []
            ))
            
            // Create note
            let note = try notesStorageService.createNote(
                title: recording.title,
                audioFileName: recording.fileName,
                duration: 60.0,
                languageCode: "ru"
            )
            testNoteIDs.append(note.id)
            createdNotes.append(note)
            
            // Start transcription
            let stream = await transcriptionService.transcribe(
                audioURL: audioURL,
                noteID: note.id,
                languageCode: "ru",
                mode: .fast
            )
            
            // Consume stream
            for await _ in stream { }
            
            // Wait for update
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        
        // Then: All notes should be created and transcribed
        XCTAssertEqual(createdNotes.count, 3, "Should create 3 notes")
        
        for (index, recording) in recordings.enumerated() {
            let note = notesStorageService.notes.first(where: { $0.id == createdNotes[index].id })
            XCTAssertNotNil(note, "Note \(index + 1) should exist")
            XCTAssertEqual(note?.title, recording.title, "Note \(index + 1) title should match")
            XCTAssertEqual(note?.transcript, recording.transcript, "Note \(index + 1) transcript should match")
            XCTAssertTrue(note?.isTranscriptionCompleted ?? false, "Note \(index + 1) should be completed")
            
            // Verify audio file exists
            let fileExists = fileStorageService.audioFileExists(fileName: "\(recording.fileName).m4a")
            XCTAssertTrue(fileExists, "Audio file \(index + 1) should exist")
        }
    }
    
    func testCompleteRecordingFlow_WithTranscriptionError() async throws {
        // Given: A simulated recording and mock engine that will fail
        let fileName = UUID().uuidString
        let audioURL = try simulateRecording(fileName: fileName)
        
        await mockEngine.reset()
        await mockEngine.setShouldThrowError(true)
        
        // When: We create a note and attempt transcription
        let note = try notesStorageService.createNote(
            title: "Test Recording",
            audioFileName: fileName,
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        let stream = await transcriptionService.transcribe(
            audioURL: audioURL,
            noteID: note.id,
            languageCode: "ru",
            mode: .fast
        )
        
        // Consume stream
        for await _ in stream { }
        
        // Wait for update
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Then: Note should still be marked as completed (even though it failed)
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote)
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false, "Should be marked as completed")
        
        // Transcript should be empty or contain error message
        XCTAssertTrue(
            updatedNote?.transcript.isEmpty ?? true,
            "Transcript should be empty on error"
        )
        
        // Audio file should still exist
        let fileExists = fileStorageService.audioFileExists(fileName: "\(fileName).m4a")
        XCTAssertTrue(fileExists, "Audio file should still exist even if transcription failed")
    }
    
    func testCompleteRecordingFlow_VerifiesDataPersistence() async throws {
        // Given: A simulated recording with transcription
        let fileName = UUID().uuidString
        let audioURL = try simulateRecording(fileName: fileName)
        let expectedTranscript = "Persistent transcription text"
        
        await mockEngine.setMockResult(TranscriptionResult(
            text: expectedTranscript,
            segments: []
        ))
        
        // When: We create and transcribe a note
        let note = try notesStorageService.createNote(
            title: "Persistence Test",
            audioFileName: fileName,
            duration: 45.0,
            languageCode: "en"
        )
        testNoteIDs.append(note.id)
        
        let stream = await transcriptionService.transcribe(
            audioURL: audioURL,
            noteID: note.id,
            languageCode: "en",
            mode: .accurate
        )
        
        for await _ in stream { }
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Then: Fetch all notes to verify persistence
        let allNotes = try notesStorageService.fetchAllNotes()
        let persistedNote = allNotes.first(where: { $0.id == note.id })
        
        XCTAssertNotNil(persistedNote, "Note should be persisted")
        XCTAssertEqual(persistedNote?.title, "Persistence Test")
        XCTAssertEqual(persistedNote?.transcript, expectedTranscript)
        XCTAssertEqual(persistedNote?.duration, 45.0, accuracy: 0.01)
        XCTAssertTrue(persistedNote?.isTranscriptionCompleted ?? false)
        
        // Verify the note is in the published notes array
        XCTAssertTrue(notesStorageService.notes.contains(where: { $0.id == note.id }))
    }
}
