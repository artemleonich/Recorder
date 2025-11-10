//
//  TranscriptionServiceTests.swift
//  RecorderTests
//
//  Unit tests for TranscriptionService
//

import XCTest
@testable import Recorder

// MARK: - Mock Transcription Engine

actor MockTranscriptionEngine: TranscriptionEngine {
    var prepareModelCalled = false
    var transcribeCalled = false
    var cancelTranscriptionCalled = false
    
    var shouldThrowError = false
    var mockResult: TranscriptionResult?
    var mockProgressUpdates: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
    var transcriptionDelay: UInt64 = 100_000_000 // 0.1 seconds
    
    func prepareModel(mode: TranscriptionMode, languageCode: String) async throws {
        prepareModelCalled = true
        
        if shouldThrowError {
            throw RecorderError.modelNotFound
        }
    }
    
    func transcribe(
        audioURL: URL,
        languageCode: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> TranscriptionResult {
        transcribeCalled = true
        
        if shouldThrowError {
            throw RecorderError.transcriptionFailed(
                NSError(domain: "MockEngine", code: -1, userInfo: nil)
            )
        }
        
        // Simulate progress updates
        for progress in mockProgressUpdates {
            progressHandler(progress)
            try await Task.sleep(nanoseconds: transcriptionDelay / UInt64(mockProgressUpdates.count))
        }
        
        // Return mock result or default
        return mockResult ?? TranscriptionResult(
            text: "Mock transcription text",
            segments: [
                TranscriptionSegment(text: "Mock", start: 0.0, end: 1.0),
                TranscriptionSegment(text: "transcription", start: 1.0, end: 2.0),
                TranscriptionSegment(text: "text", start: 2.0, end: 3.0)
            ]
        )
    }
    
    func cancelTranscription() async {
        cancelTranscriptionCalled = true
    }
    
    // Helper methods for testing
    func reset() {
        prepareModelCalled = false
        transcribeCalled = false
        cancelTranscriptionCalled = false
        shouldThrowError = false
        mockResult = nil
    }
}

// MARK: - Tests

final class TranscriptionServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: TranscriptionService!
    var mockEngine: MockTranscriptionEngine!
    var storageService: NotesStorageService!
    var persistenceController: PersistenceController!
    var testNoteIDs: [UUID] = []
    
    // MARK: - Setup & Teardown
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        persistenceController = PersistenceController(inMemory: true)
        storageService = NotesStorageService(
            persistenceController: persistenceController,
            fileStorageService: FileStorageService()
        )
        
        // Create mock engine
        mockEngine = MockTranscriptionEngine()
        
        // Create service with mock engine
        sut = TranscriptionService(
            engine: mockEngine,
            storageService: storageService
        )
        
        testNoteIDs = []
    }
    
    @MainActor
    override func tearDown() async throws {
        // Clean up test notes
        for noteID in testNoteIDs {
            try? storageService.deleteNote(noteID)
        }
        
        testNoteIDs = []
        sut = nil
        mockEngine = nil
        storageService = nil
        persistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func createTestNote() throws -> AudioNote {
        let note = try storageService.createNote(
            title: "Test Note",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        return note
    }
    
    private func createTestAudioFile() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFileName = "\(UUID().uuidString).m4a"
        let testFileURL = tempDirectory.appendingPathComponent(testFileName)
        
        let testData = "Test audio data".data(using: .utf8)!
        try testData.write(to: testFileURL)
        
        return testFileURL
    }
    
    // MARK: - Transcription Tests
    
    @MainActor
    func testTranscribe_CallsEngineWithCorrectParameters() async throws {
        // Given: A test note and audio file
        let note = try createTestNote()
        let audioURL = try createTestAudioFile()
        
        // When: We transcribe the audio
        var progressUpdates: [Double] = []
        let stream = await sut.transcribe(
            audioURL: audioURL,
            noteID: note.id,
            languageCode: "ru",
            mode: .fast
        )
        
        for await progress in stream {
            progressUpdates.append(progress)
        }
        
        // Then: Engine should be called
        let engineCalled = await mockEngine.transcribeCalled
        XCTAssertTrue(engineCalled, "Engine transcribe should be called")
        
        // Progress updates should be received
        XCTAssertFalse(progressUpdates.isEmpty, "Should receive progress updates")
        
        // Clean up
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    @MainActor
    func testTranscribe_UpdatesNoteWithResult() async throws {
        // Given: A test note and audio file
        let note = try createTestNote()
        let audioURL = try createTestAudioFile()
        
        let expectedText = "Expected transcription text"
        await mockEngine.reset()
        await mockEngine.setMockResult(TranscriptionResult(text: expectedText, segments: []))
        
        // When: We transcribe the audio
        let stream = await sut.transcribe(
            audioURL: audioURL,
            noteID: note.id,
            languageCode: "ru",
            mode: .fast
        )
        
        // Consume the stream
        for await _ in stream { }
        
        // Wait a moment for the update to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then: Note should be updated with transcription
        let updatedNote = storageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote)
        XCTAssertEqual(updatedNote?.transcript, expectedText)
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false)
        
        // Clean up
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    @MainActor
    func testTranscribe_ReportsProgressUpdates() async throws {
        // Given: A test note and audio file
        let note = try createTestNote()
        let audioURL = try createTestAudioFile()
        
        // When: We transcribe and collect progress updates
        var progressUpdates: [Double] = []
        let stream = await sut.transcribe(
            audioURL: audioURL,
            noteID: note.id,
            languageCode: "en",
            mode: .accurate
        )
        
        for await progress in stream {
            progressUpdates.append(progress)
        }
        
        // Then: Should receive multiple progress updates
        XCTAssertGreaterThan(progressUpdates.count, 1, "Should receive multiple progress updates")
        
        // Progress should be in ascending order
        for i in 0..<(progressUpdates.count - 1) {
            XCTAssertLessThanOrEqual(
                progressUpdates[i],
                progressUpdates[i + 1],
                "Progress should be in ascending order"
            )
        }
        
        // Last progress should be 1.0 (100%)
        if let lastProgress = progressUpdates.last {
            XCTAssertEqual(lastProgress, 1.0, accuracy: 0.01, "Last progress should be 1.0")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    @MainActor
    func testTranscribe_WithError_MarksTranscriptionAsCompleted() async throws {
        // Given: A test note and mock engine that throws error
        let note = try createTestNote()
        let audioURL = try createTestAudioFile()
        
        await mockEngine.reset()
        await mockEngine.setShouldThrowError(true)
        
        // When: We attempt transcription
        let stream = await sut.transcribe(
            audioURL: audioURL,
            noteID: note.id,
            languageCode: "ru",
            mode: .fast
        )
        
        // Consume the stream
        for await _ in stream { }
        
        // Wait for update to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then: Note should be marked as completed (even though it failed)
        let updatedNote = storageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote)
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false)
        
        // Clean up
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    // MARK: - Retry Transcription Tests
    
    @MainActor
    func testRetryTranscription_StartsNewTranscription() async throws {
        // Given: A test note
        let note = try createTestNote()
        let audioURL = try createTestAudioFile()
        
        // When: We retry transcription
        await mockEngine.reset()
        let stream = await sut.retryTranscription(
            noteID: note.id,
            audioURL: audioURL,
            languageCode: "ru",
            mode: .fast
        )
        
        // Consume the stream
        for await _ in stream { }
        
        // Then: Engine should be called
        let engineCalled = await mockEngine.transcribeCalled
        XCTAssertTrue(engineCalled, "Engine should be called for retry")
        
        // Clean up
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    // MARK: - Cancel Transcription Tests
    
    func testCancelTranscription_CallsEngineCancel() async throws {
        // Given: A note ID
        let noteID = UUID()
        
        // When: We cancel transcription
        await sut.cancelTranscription(noteID: noteID)
        
        // Then: Engine cancel should be called
        let cancelCalled = await mockEngine.cancelTranscriptionCalled
        XCTAssertTrue(cancelCalled, "Engine cancelTranscription should be called")
    }
    
    func testCancelAllTranscriptions_CallsEngineCancel() async throws {
        // When: We cancel all transcriptions
        await sut.cancelAllTranscriptions()
        
        // Then: Engine cancel should be called
        let cancelCalled = await mockEngine.cancelTranscriptionCalled
        XCTAssertTrue(cancelCalled, "Engine cancelTranscription should be called")
    }
}

// MARK: - Mock Engine Helper Extensions

extension MockTranscriptionEngine {
    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }
    
    func setMockResult(_ result: TranscriptionResult) {
        mockResult = result
    }
}
