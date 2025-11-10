//
//  NotesStorageServiceTests.swift
//  RecorderTests
//
//  Unit tests for NotesStorageService
//

import XCTest
import CoreData
@testable import Recorder

@MainActor
final class NotesStorageServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: NotesStorageService!
    var persistenceController: PersistenceController!
    var fileStorageService: FileStorageService!
    var testNoteIDs: [UUID] = []
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack for testing
        persistenceController = PersistenceController(inMemory: true)
        fileStorageService = FileStorageService()
        sut = NotesStorageService(
            persistenceController: persistenceController,
            fileStorageService: fileStorageService
        )
        testNoteIDs = []
    }
    
    override func tearDown() async throws {
        // Clean up test notes
        for noteID in testNoteIDs {
            try? sut.deleteNote(noteID)
        }
        
        testNoteIDs = []
        sut = nil
        persistenceController = nil
        fileStorageService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Create Note Tests
    
    func testCreateNote_SavesNoteInCoreData() throws {
        // Given: Note parameters
        let title = "Test Note"
        let audioFileName = "\(UUID().uuidString).m4a"
        let duration: TimeInterval = 120.5
        let languageCode = "ru"
        
        // When: We create a note
        let note = try sut.createNote(
            title: title,
            audioFileName: audioFileName,
            duration: duration,
            languageCode: languageCode
        )
        
        testNoteIDs.append(note.id)
        
        // Then: Note should be created with correct properties
        XCTAssertEqual(note.title, title)
        XCTAssertEqual(note.audioFileName, audioFileName)
        XCTAssertEqual(note.duration, duration, accuracy: 0.01)
        XCTAssertEqual(note.languageCode, languageCode)
        XCTAssertEqual(note.transcript, "")
        XCTAssertFalse(note.isTranscriptionCompleted)
        
        // Verify it's in the notes array
        XCTAssertTrue(sut.notes.contains(where: { $0.id == note.id }))
    }
    
    func testCreateNote_UpdatesNotesArray() throws {
        // Given: Initial notes count
        let initialCount = sut.notes.count
        
        // When: We create a note
        let note = try sut.createNote(
            title: "Test Note",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "en"
        )
        
        testNoteIDs.append(note.id)
        
        // Then: Notes array should be updated
        XCTAssertEqual(sut.notes.count, initialCount + 1)
        XCTAssertTrue(sut.notes.contains(where: { $0.id == note.id }))
    }
    
    // MARK: - Update Title Tests
    
    func testUpdateNoteTitle_UpdatesTitleInCoreData() throws {
        // Given: A created note
        let note = try sut.createNote(
            title: "Original Title",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        let newTitle = "Updated Title"
        
        // When: We update the title
        try sut.updateNoteTitle(note.id, title: newTitle)
        
        // Then: Title should be updated
        let updatedNote = sut.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote)
        XCTAssertEqual(updatedNote?.title, newTitle)
    }
    
    func testUpdateNoteTitle_WithNonExistentID_ThrowsError() throws {
        // Given: A non-existent note ID
        let nonExistentID = UUID()
        
        // When/Then: Updating should throw error
        XCTAssertThrowsError(try sut.updateNoteTitle(nonExistentID, title: "New Title")) { error in
            XCTAssertTrue(error is RecorderError)
        }
    }
    
    // MARK: - Update Transcript Tests
    
    func testUpdateNoteTranscript_UpdatesTranscriptInCoreData() throws {
        // Given: A created note
        let note = try sut.createNote(
            title: "Test Note",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        let newTranscript = "This is the transcribed text from the audio recording."
        
        // When: We update the transcript
        try sut.updateNoteTranscript(note.id, transcript: newTranscript)
        
        // Then: Transcript should be updated
        let updatedNote = sut.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote)
        XCTAssertEqual(updatedNote?.transcript, newTranscript)
    }
    
    func testUpdateNoteTranscript_WithNonExistentID_ThrowsError() throws {
        // Given: A non-existent note ID
        let nonExistentID = UUID()
        
        // When/Then: Updating should throw error
        XCTAssertThrowsError(try sut.updateNoteTranscript(nonExistentID, transcript: "Text")) { error in
            XCTAssertTrue(error is RecorderError)
        }
    }
    
    // MARK: - Update Transcription Status Tests
    
    func testUpdateTranscriptionStatus_UpdatesStatusInCoreData() throws {
        // Given: A created note
        let note = try sut.createNote(
            title: "Test Note",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        // Initially should be false
        XCTAssertFalse(note.isTranscriptionCompleted)
        
        // When: We update the status
        try sut.updateTranscriptionStatus(note.id, isCompleted: true)
        
        // Then: Status should be updated
        let updatedNote = sut.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote)
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false)
    }
    
    // MARK: - Delete Note Tests
    
    func testDeleteNote_RemovesNoteFromCoreData() throws {
        // Given: A created note
        let note = try sut.createNote(
            title: "Test Note",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        
        let noteID = note.id
        let initialCount = sut.notes.count
        
        // When: We delete the note
        try sut.deleteNote(noteID)
        
        // Then: Note should be removed
        XCTAssertEqual(sut.notes.count, initialCount - 1)
        XCTAssertFalse(sut.notes.contains(where: { $0.id == noteID }))
    }
    
    func testDeleteNote_WithNonExistentID_ThrowsError() throws {
        // Given: A non-existent note ID
        let nonExistentID = UUID()
        
        // When/Then: Deleting should throw error
        XCTAssertThrowsError(try sut.deleteNote(nonExistentID)) { error in
            XCTAssertTrue(error is RecorderError)
        }
    }
    
    // MARK: - Fetch All Notes Tests
    
    func testFetchAllNotes_ReturnsSortedNotes() throws {
        // Given: Multiple notes created at different times
        let note1 = try sut.createNote(
            title: "Note 1",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note1.id)
        
        // Wait a moment to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.01)
        
        let note2 = try sut.createNote(
            title: "Note 2",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note2.id)
        
        Thread.sleep(forTimeInterval: 0.01)
        
        let note3 = try sut.createNote(
            title: "Note 3",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note3.id)
        
        // When: We fetch all notes
        let notes = try sut.fetchAllNotes()
        
        // Then: Notes should be sorted by creation date (newest first)
        XCTAssertGreaterThanOrEqual(notes.count, 3)
        
        // Find our test notes in the results
        let testNotes = notes.filter { testNoteIDs.contains($0.id) }
        XCTAssertEqual(testNotes.count, 3)
        
        // Verify they're sorted newest first
        for i in 0..<(testNotes.count - 1) {
            XCTAssertGreaterThanOrEqual(
                testNotes[i].createdAt,
                testNotes[i + 1].createdAt,
                "Notes should be sorted by creation date (newest first)"
            )
        }
    }
    
    func testFetchAllNotes_UpdatesNotesProperty() throws {
        // Given: Some notes exist
        let note = try sut.createNote(
            title: "Test Note",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        // When: We fetch all notes
        let fetchedNotes = try sut.fetchAllNotes()
        
        // Then: The notes property should be updated
        XCTAssertEqual(sut.notes.count, fetchedNotes.count)
        XCTAssertTrue(sut.notes.contains(where: { $0.id == note.id }))
    }
    
    // MARK: - Search Notes Tests
    
    func testSearchNotes_ByTitle_ReturnsMatchingNotes() throws {
        // Given: Notes with different titles
        let note1 = try sut.createNote(
            title: "Meeting Notes",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note1.id)
        
        let note2 = try sut.createNote(
            title: "Shopping List",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note2.id)
        
        let note3 = try sut.createNote(
            title: "Meeting Agenda",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note3.id)
        
        // When: We search for "meeting"
        let results = sut.searchNotes(query: "meeting")
        
        // Then: Should return notes with "meeting" in title
        let matchingResults = results.filter { testNoteIDs.contains($0.id) }
        XCTAssertEqual(matchingResults.count, 2)
        XCTAssertTrue(matchingResults.contains(where: { $0.id == note1.id }))
        XCTAssertTrue(matchingResults.contains(where: { $0.id == note3.id }))
    }
    
    func testSearchNotes_ByTranscript_ReturnsMatchingNotes() throws {
        // Given: Notes with different transcripts
        let note1 = try sut.createNote(
            title: "Note 1",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note1.id)
        try sut.updateNoteTranscript(note1.id, transcript: "This is about programming")
        
        let note2 = try sut.createNote(
            title: "Note 2",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note2.id)
        try sut.updateNoteTranscript(note2.id, transcript: "This is about cooking")
        
        // When: We search for "programming"
        let results = sut.searchNotes(query: "programming")
        
        // Then: Should return notes with "programming" in transcript
        let matchingResults = results.filter { testNoteIDs.contains($0.id) }
        XCTAssertEqual(matchingResults.count, 1)
        XCTAssertEqual(matchingResults.first?.id, note1.id)
    }
    
    func testSearchNotes_WithEmptyQuery_ReturnsAllNotes() throws {
        // Given: Some notes exist
        let note = try sut.createNote(
            title: "Test Note",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        let allNotesCount = sut.notes.count
        
        // When: We search with empty query
        let results = sut.searchNotes(query: "")
        
        // Then: Should return all notes
        XCTAssertEqual(results.count, allNotesCount)
    }
    
    func testSearchNotes_CaseInsensitive() throws {
        // Given: A note with specific title
        let note = try sut.createNote(
            title: "Important Meeting",
            audioFileName: "\(UUID().uuidString).m4a",
            duration: 60.0,
            languageCode: "ru"
        )
        testNoteIDs.append(note.id)
        
        // When: We search with different case
        let results1 = sut.searchNotes(query: "IMPORTANT")
        let results2 = sut.searchNotes(query: "important")
        let results3 = sut.searchNotes(query: "ImPoRtAnT")
        
        // Then: All searches should find the note
        XCTAssertTrue(results1.contains(where: { $0.id == note.id }))
        XCTAssertTrue(results2.contains(where: { $0.id == note.id }))
        XCTAssertTrue(results3.contains(where: { $0.id == note.id }))
    }
}
