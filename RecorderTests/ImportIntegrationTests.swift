//
//  ImportIntegrationTests.swift
//  RecorderTests
//
//  Integration tests for audio file import functionality
//

import XCTest
import AVFoundation
@testable import Recorder

@MainActor
final class ImportIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var notesStorageService: NotesStorageService!
    var fileStorageService: FileStorageService!
    var transcriptionService: TranscriptionService!
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
        
        // Create transcription service
        transcriptionService = TranscriptionService(
            engine: mockEngine,
            storageService: notesStorageService
        )
        
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
        notesStorageService = nil
        fileStorageService = nil
        transcriptionService = nil
        persistenceController = nil
        mockEngine = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test audio file in the temporary directory
    private func createTestAudioFile(format: String, fileName: String? = nil) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFileName = fileName ?? "\(UUID().uuidString).\(format)"
        let fileURL = tempDirectory.appendingPathComponent(testFileName)
        
        // Create minimal valid audio file data based on format
        let testData: Data
        
        switch format.lowercased() {
        case "m4a":
            // Minimal M4A/AAC header
            testData = Data([
                0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70,
                0x4D, 0x34, 0x41, 0x20, 0x00, 0x00, 0x00, 0x00,
                0x4D, 0x34, 0x41, 0x20, 0x6D, 0x70, 0x34, 0x32,
                0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x00, 0x00
            ])
            
        case "mp3":
            // Minimal MP3 header (ID3v2 + frame header)
            testData = Data([
                0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0xFF, 0xFB, 0x90, 0x00, 0x00, 0x00
            ])
            
        case "wav":
            // Minimal WAV header (RIFF + fmt + data chunks)
            testData = Data([
                0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00,
                0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20,
                0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
                0x44, 0xAC, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00,
                0x02, 0x00, 0x10, 0x00, 0x64, 0x61, 0x74, 0x61,
                0x00, 0x00, 0x00, 0x00
            ])
            
        case "aac":
            // Minimal AAC ADTS header
            testData = Data([
                0xFF, 0xF1, 0x50, 0x80, 0x01, 0x3F, 0xFC
            ])
            
        case "caf":
            // Minimal CAF header
            testData = Data([
                0x63, 0x61, 0x66, 0x66, 0x00, 0x01, 0x00, 0x00,
                0x64, 0x65, 0x73, 0x63, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x20
            ])
            
        default:
            // Unknown format - create empty file
            testData = Data()
        }
        
        try testData.write(to: fileURL)
        testFileURLs.append(fileURL)
        
        return fileURL
    }
    
    /// Simulates importing an audio file
    private func simulateImport(sourceURL: URL) throws -> (audioFileName: String, duration: TimeInterval) {
        // Generate new filename
        let audioFileName = "\(UUID().uuidString).m4a"
        
        // Copy file to recordings directory
        let destinationURL = try fileStorageService.saveAudioFile(from: sourceURL, withName: audioFileName)
        testFileURLs.append(destinationURL)
        
        // Determine duration (mock value for testing)
        let duration: TimeInterval = 120.0
        
        return (audioFileName, duration)
    }
    
    // MARK: - Import Tests
    
    func testImportM4AFile_CreatesNoteAndTranscribes() async throws {
        // Given: An M4A audio file
        let sourceURL = try createTestAudioFile(format: "m4a")
        let expectedTranscript = "Imported M4A transcription"
        
        await mockEngine.setMockResult(TranscriptionResult(
            text: expectedTranscript,
            segments: []
        ))
        
        // When: We import the file
        let (audioFileName, duration) = try simulateImport(sourceURL: sourceURL)
        
        let note = try notesStorageService.createNote(
            title: "Imported M4A",
            audioFileName: audioFileName,
            duration: duration,
            languageCode: "en"
        )
        testNoteIDs.append(note.id)
        
        // Then: File should be copied to recordings directory
        let fileExists = fileStorageService.audioFileExists(fileName: audioFileName)
        XCTAssertTrue(fileExists, "Imported file should exist in recordings directory")
        
        // Then: Note should be created with correct properties
        XCTAssertEqual(note.audioFileName, audioFileName)
        XCTAssertEqual(note.duration, duration, accuracy: 0.01)
        
        // When: We transcribe the imported file
        let destinationURL = try fileStorageService.getAudioFileURL(fileName: audioFileName)
        let stream = await transcriptionService.transcribe(
            audioURL: destinationURL,
            noteID: note.id,
            languageCode: "en",
            mode: .fast
        )
        
        for await _ in stream { }
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Then: Transcription should be completed
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertEqual(updatedNote?.transcript, expectedTranscript)
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false)
    }
    
    func testImportMP3File_CreatesNoteAndTranscribes() async throws {
        // Given: An MP3 audio file
        let sourceURL = try createTestAudioFile(format: "mp3")
        let expectedTranscript = "Imported MP3 transcription"
        
        await mockEngine.setMockResult(TranscriptionResult(
            text: expectedTranscript,
            segments: []
        ))
        
        // When: We import the file
        let (audioFileName, duration) = try simulateImport(sourceURL: sourceURL)
        
        let note = try notesStorageService.createNote(
            title: "Imported MP3",
            audioFileName: audioFileName,
            duration: duration,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        // Then: File should be copied
        let fileExists = fileStorageService.audioFileExists(fileName: audioFileName)
        XCTAssertTrue(fileExists, "Imported MP3 file should exist")
        
        // When: We transcribe
        let destinationURL = try fileStorageService.getAudioFileURL(fileName: audioFileName)
        let stream = await transcriptionService.transcribe(
            audioURL: destinationURL,
            noteID: note.id,
            languageCode: "ru",
            mode: .fast
        )
        
        for await _ in stream { }
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Then: Should be transcribed
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertEqual(updatedNote?.transcript, expectedTranscript)
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false)
    }
    
    func testImportWAVFile_CreatesNoteAndTranscribes() async throws {
        // Given: A WAV audio file
        let sourceURL = try createTestAudioFile(format: "wav")
        let expectedTranscript = "Imported WAV transcription"
        
        await mockEngine.setMockResult(TranscriptionResult(
            text: expectedTranscript,
            segments: []
        ))
        
        // When: We import the file
        let (audioFileName, duration) = try simulateImport(sourceURL: sourceURL)
        
        let note = try notesStorageService.createNote(
            title: "Imported WAV",
            audioFileName: audioFileName,
            duration: duration,
            languageCode: "en"
        )
        testNoteIDs.append(note.id)
        
        // Then: File should be copied
        let fileExists = fileStorageService.audioFileExists(fileName: audioFileName)
        XCTAssertTrue(fileExists, "Imported WAV file should exist")
        
        // When: We transcribe
        let destinationURL = try fileStorageService.getAudioFileURL(fileName: audioFileName)
        let stream = await transcriptionService.transcribe(
            audioURL: destinationURL,
            noteID: note.id,
            languageCode: "en",
            mode: .accurate
        )
        
        for await _ in stream { }
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Then: Should be transcribed
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertEqual(updatedNote?.transcript, expectedTranscript)
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false)
    }
    
    func testImportMultipleFormats_AllSucceed() async throws {
        // Given: Multiple audio files in different formats
        let formats = ["m4a", "mp3", "wav", "aac", "caf"]
        var importedNotes: [AudioNote] = []
        
        // When: We import all formats
        for (index, format) in formats.enumerated() {
            let sourceURL = try createTestAudioFile(format: format)
            let expectedTranscript = "Transcription for \(format) file"
            
            await mockEngine.reset()
            await mockEngine.setMockResult(TranscriptionResult(
                text: expectedTranscript,
                segments: []
            ))
            
            let (audioFileName, duration) = try simulateImport(sourceURL: sourceURL)
            
            let note = try notesStorageService.createNote(
                title: "Import \(format.uppercased())",
                audioFileName: audioFileName,
                duration: duration,
                languageCode: "en"
            )
            testNoteIDs.append(note.id)
            importedNotes.append(note)
            
            // Verify file exists
            let fileExists = fileStorageService.audioFileExists(fileName: audioFileName)
            XCTAssertTrue(fileExists, "\(format.uppercased()) file should exist")
            
            // Transcribe
            let destinationURL = try fileStorageService.getAudioFileURL(fileName: audioFileName)
            let stream = await transcriptionService.transcribe(
                audioURL: destinationURL,
                noteID: note.id,
                languageCode: "en",
                mode: .fast
            )
            
            for await _ in stream { }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        
        // Then: All notes should be created and transcribed
        XCTAssertEqual(importedNotes.count, formats.count, "Should import all formats")
        
        for (index, format) in formats.enumerated() {
            let note = notesStorageService.notes.first(where: { $0.id == importedNotes[index].id })
            XCTAssertNotNil(note, "\(format.uppercased()) note should exist")
            XCTAssertTrue(note?.isTranscriptionCompleted ?? false, "\(format.uppercased()) should be transcribed")
        }
    }
    
    func testImportUnsupportedFormat_CanStillCreateNote() async throws {
        // Given: A file with unsupported format
        let sourceURL = try createTestAudioFile(format: "txt")
        
        // When: We attempt to import (file service doesn't validate format)
        let (audioFileName, duration) = try simulateImport(sourceURL: sourceURL)
        
        // Note: In a real implementation, the ViewModel would validate the format
        // before calling the service. Here we test that the service itself
        // doesn't crash with unexpected formats.
        
        let note = try notesStorageService.createNote(
            title: "Unsupported Format",
            audioFileName: audioFileName,
            duration: duration,
            languageCode: "en"
        )
        testNoteIDs.append(note.id)
        
        // Then: Note should be created (validation happens at ViewModel level)
        XCTAssertNotNil(note)
        XCTAssertEqual(note.audioFileName, audioFileName)
    }
    
    func testImportWithCorrectDuration_StoresAccurately() async throws {
        // Given: Audio files with specific durations
        let testCases: [(format: String, duration: TimeInterval)] = [
            ("m4a", 30.5),
            ("mp3", 120.0),
            ("wav", 45.25)
        ]
        
        // When: We import files with specific durations
        for testCase in testCases {
            let sourceURL = try createTestAudioFile(format: testCase.format)
            
            // Simulate import with specific duration
            let audioFileName = "\(UUID().uuidString).m4a"
            let destinationURL = try fileStorageService.saveAudioFile(from: sourceURL, withName: audioFileName)
            testFileURLs.append(destinationURL)
            
            let note = try notesStorageService.createNote(
                title: "Duration Test \(testCase.format)",
                audioFileName: audioFileName,
                duration: testCase.duration,
                languageCode: "en"
            )
            testNoteIDs.append(note.id)
            
            // Then: Duration should be stored accurately
            XCTAssertEqual(
                note.duration,
                testCase.duration,
                accuracy: 0.01,
                "\(testCase.format) duration should be accurate"
            )
            
            // Verify persistence
            let fetchedNote = notesStorageService.notes.first(where: { $0.id == note.id })
            XCTAssertEqual(
                fetchedNote?.duration,
                testCase.duration,
                accuracy: 0.01,
                "\(testCase.format) duration should persist"
            )
        }
    }
    
    func testImportAndTranscribe_VerifiesFileIntegrity() async throws {
        // Given: An imported audio file
        let sourceURL = try createTestAudioFile(format: "m4a")
        let (audioFileName, duration) = try simulateImport(sourceURL: sourceURL)
        
        // When: We create a note
        let note = try notesStorageService.createNote(
            title: "File Integrity Test",
            audioFileName: audioFileName,
            duration: duration,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        // Then: File should exist and be accessible
        let fileExists = fileStorageService.audioFileExists(fileName: audioFileName)
        XCTAssertTrue(fileExists, "File should exist after import")
        
        let fileURL = try fileStorageService.getAudioFileURL(fileName: audioFileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "File should be accessible")
        
        // When: We delete the note
        try notesStorageService.deleteNote(note.id)
        
        // Then: File should be deleted
        let fileExistsAfterDelete = fileStorageService.audioFileExists(fileName: audioFileName)
        XCTAssertFalse(fileExistsAfterDelete, "File should be deleted with note")
    }
}
