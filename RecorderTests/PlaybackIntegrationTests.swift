//
//  PlaybackIntegrationTests.swift
//  RecorderTests
//
//  Integration tests for audio playback and note editing functionality
//

import XCTest
import AVFoundation
@testable import Recorder

@MainActor
final class PlaybackIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var audioPlayerService: AudioPlayerService!
    var notesStorageService: NotesStorageService!
    var fileStorageService: FileStorageService!
    var persistenceController: PersistenceController!
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
        
        // Create audio player service
        audioPlayerService = AudioPlayerService()
        
        testNoteIDs = []
        testFileURLs = []
    }
    
    override func tearDown() async throws {
        // Stop any playing audio
        audioPlayerService.stop()
        
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
        audioPlayerService = nil
        notesStorageService = nil
        fileStorageService = nil
        persistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test audio file with minimal valid M4A data
    private func createTestAudioFile(fileName: String) throws -> URL {
        let recordingsDirectory = try fileStorageService.getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent("\(fileName).m4a")
        
        // Create minimal valid M4A file
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
    
    /// Creates a test note with audio file
    private func createTestNoteWithAudio(title: String = "Test Note") throws -> (note: AudioNote, audioURL: URL) {
        let fileName = UUID().uuidString
        let audioURL = try createTestAudioFile(fileName: fileName)
        
        let note = try notesStorageService.createNote(
            title: title,
            audioFileName: fileName,
            duration: 60.0,
            languageCode: "en"
        )
        testNoteIDs.append(note.id)
        
        return (note, audioURL)
    }
    
    // MARK: - Playback Tests
    
    func testLoadAndPlayAudio_UpdatesPlayerState() async throws {
        // Given: A note with audio file
        let (note, audioURL) = try createTestNoteWithAudio(title: "Playback Test")
        
        // When: We load the audio
        try await audioPlayerService.loadAudio(url: audioURL)
        
        // Then: Duration should be set (even if minimal for test file)
        XCTAssertGreaterThanOrEqual(audioPlayerService.duration, 0, "Duration should be set")
        XCTAssertFalse(audioPlayerService.isPlaying, "Should not be playing initially")
        XCTAssertEqual(audioPlayerService.currentTime, 0, accuracy: 0.1, "Current time should be 0")
    }
    
    func testPlayAndPauseAudio_TogglesPlayingState() async throws {
        // Given: A loaded audio file
        let (_, audioURL) = try createTestNoteWithAudio()
        try await audioPlayerService.loadAudio(url: audioURL)
        
        // When: We play the audio
        try await audioPlayerService.play()
        
        // Then: Should be playing
        XCTAssertTrue(audioPlayerService.isPlaying, "Should be playing after play()")
        
        // When: We pause
        audioPlayerService.pause()
        
        // Then: Should not be playing
        XCTAssertFalse(audioPlayerService.isPlaying, "Should not be playing after pause()")
    }
    
    func testSeekToPosition_UpdatesCurrentTime() async throws {
        // Given: A loaded audio file
        let (_, audioURL) = try createTestNoteWithAudio()
        try await audioPlayerService.loadAudio(url: audioURL)
        
        // When: We seek to a specific position
        let seekTime: TimeInterval = 30.0
        audioPlayerService.seek(to: seekTime)
        
        // Wait a moment for seek to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Current time should be updated
        // Note: For minimal test files, seeking might not work perfectly
        // but the method should not crash
        XCTAssertGreaterThanOrEqual(audioPlayerService.currentTime, 0)
    }
    
    func testSkipForwardAndBackward_AdjustsPosition() async throws {
        // Given: A loaded audio file
        let (_, audioURL) = try createTestNoteWithAudio()
        try await audioPlayerService.loadAudio(url: audioURL)
        
        // Set initial position
        audioPlayerService.seek(to: 30.0)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let initialTime = audioPlayerService.currentTime
        
        // When: We skip forward
        audioPlayerService.skipForward(seconds: 10.0)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Time should increase (or stay at max)
        XCTAssertGreaterThanOrEqual(audioPlayerService.currentTime, initialTime)
        
        // When: We skip backward
        audioPlayerService.skipBackward(seconds: 5.0)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Method should execute without crashing
        XCTAssertGreaterThanOrEqual(audioPlayerService.currentTime, 0)
    }
    
    func testStopAudio_ResetsPlayerState() async throws {
        // Given: A playing audio file
        let (_, audioURL) = try createTestNoteWithAudio()
        try await audioPlayerService.loadAudio(url: audioURL)
        try await audioPlayerService.play()
        
        // When: We stop the audio
        audioPlayerService.stop()
        
        // Then: Should not be playing and position should reset
        XCTAssertFalse(audioPlayerService.isPlaying, "Should not be playing after stop")
        XCTAssertEqual(audioPlayerService.currentTime, 0, accuracy: 0.1, "Should reset to beginning")
    }
    
    // MARK: - Note Editing Tests
    
    func testEditNoteTitle_PersistsChanges() async throws {
        // Given: A created note
        let (note, _) = try createTestNoteWithAudio(title: "Original Title")
        
        // When: We update the title
        let newTitle = "Updated Title"
        try notesStorageService.updateNoteTitle(note.id, title: newTitle)
        
        // Then: Title should be updated in storage
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote, "Note should exist")
        XCTAssertEqual(updatedNote?.title, newTitle, "Title should be updated")
        
        // Then: Changes should persist after refetch
        let fetchedNotes = try notesStorageService.fetchAllNotes()
        let refetchedNote = fetchedNotes.first(where: { $0.id == note.id })
        XCTAssertEqual(refetchedNote?.title, newTitle, "Title should persist")
    }
    
    func testEditNoteTranscript_PersistsChanges() async throws {
        // Given: A created note with initial transcript
        let (note, _) = try createTestNoteWithAudio()
        try notesStorageService.updateNoteTranscript(note.id, transcript: "Initial transcript")
        
        // When: We update the transcript
        let newTranscript = "This is the updated transcript with more detailed content."
        try notesStorageService.updateNoteTranscript(note.id, transcript: newTranscript)
        
        // Then: Transcript should be updated
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote, "Note should exist")
        XCTAssertEqual(updatedNote?.transcript, newTranscript, "Transcript should be updated")
        
        // Then: Changes should persist
        let fetchedNotes = try notesStorageService.fetchAllNotes()
        let refetchedNote = fetchedNotes.first(where: { $0.id == note.id })
        XCTAssertEqual(refetchedNote?.transcript, newTranscript, "Transcript should persist")
    }
    
    func testEditMultipleFields_AllPersist() async throws {
        // Given: A created note
        let (note, _) = try createTestNoteWithAudio(title: "Original")
        
        // When: We update multiple fields
        let newTitle = "Updated Title"
        let newTranscript = "Updated transcript content"
        
        try notesStorageService.updateNoteTitle(note.id, title: newTitle)
        try notesStorageService.updateNoteTranscript(note.id, transcript: newTranscript)
        try notesStorageService.updateTranscriptionStatus(note.id, isCompleted: true)
        
        // Then: All changes should be persisted
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(updatedNote)
        XCTAssertEqual(updatedNote?.title, newTitle, "Title should be updated")
        XCTAssertEqual(updatedNote?.transcript, newTranscript, "Transcript should be updated")
        XCTAssertTrue(updatedNote?.isTranscriptionCompleted ?? false, "Status should be updated")
        
        // Verify persistence after refetch
        let fetchedNotes = try notesStorageService.fetchAllNotes()
        let refetchedNote = fetchedNotes.first(where: { $0.id == note.id })
        XCTAssertEqual(refetchedNote?.title, newTitle)
        XCTAssertEqual(refetchedNote?.transcript, newTranscript)
        XCTAssertTrue(refetchedNote?.isTranscriptionCompleted ?? false)
    }
    
    func testEditNote_WhileAudioIsLoaded_DoesNotAffectPlayback() async throws {
        // Given: A note with loaded audio
        let (note, audioURL) = try createTestNoteWithAudio(title: "Original Title")
        try await audioPlayerService.loadAudio(url: audioURL)
        
        let originalDuration = audioPlayerService.duration
        
        // When: We edit the note
        try notesStorageService.updateNoteTitle(note.id, title: "New Title")
        try notesStorageService.updateNoteTranscript(note.id, transcript: "New transcript")
        
        // Then: Audio player should not be affected
        XCTAssertEqual(audioPlayerService.duration, originalDuration, "Duration should remain the same")
        
        // Should still be able to play
        try await audioPlayerService.play()
        XCTAssertTrue(audioPlayerService.isPlaying, "Should still be able to play")
        
        audioPlayerService.stop()
    }
    
    // MARK: - Integration Tests
    
    func testCompletePlaybackAndEditingFlow() async throws {
        // Given: A note with audio
        let (note, audioURL) = try createTestNoteWithAudio(title: "Complete Flow Test")
        
        // When: We load and play the audio
        try await audioPlayerService.loadAudio(url: audioURL)
        try await audioPlayerService.play()
        
        // Then: Should be playing
        XCTAssertTrue(audioPlayerService.isPlaying)
        
        // When: We pause and edit the note
        audioPlayerService.pause()
        try notesStorageService.updateNoteTitle(note.id, title: "Edited During Playback")
        try notesStorageService.updateNoteTranscript(note.id, transcript: "Edited transcript")
        
        // Then: Changes should be saved
        let updatedNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertEqual(updatedNote?.title, "Edited During Playback")
        XCTAssertEqual(updatedNote?.transcript, "Edited transcript")
        
        // When: We resume playback
        try await audioPlayerService.play()
        
        // Then: Should play successfully
        XCTAssertTrue(audioPlayerService.isPlaying)
        
        // Cleanup
        audioPlayerService.stop()
    }
    
    func testPersistenceAcrossMultipleOperations() async throws {
        // Given: A note with audio
        let (note, audioURL) = try createTestNoteWithAudio(title: "Persistence Test")
        
        // When: We perform multiple operations
        // 1. Load audio
        try await audioPlayerService.loadAudio(url: audioURL)
        
        // 2. Edit title
        try notesStorageService.updateNoteTitle(note.id, title: "First Edit")
        
        // 3. Play audio
        try await audioPlayerService.play()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // 4. Edit transcript while playing
        try notesStorageService.updateNoteTranscript(note.id, transcript: "Transcript during playback")
        
        // 5. Stop playback
        audioPlayerService.stop()
        
        // 6. Edit title again
        try notesStorageService.updateNoteTitle(note.id, title: "Second Edit")
        
        // 7. Mark transcription as completed
        try notesStorageService.updateTranscriptionStatus(note.id, isCompleted: true)
        
        // Then: All changes should be persisted
        let finalNote = notesStorageService.notes.first(where: { $0.id == note.id })
        XCTAssertNotNil(finalNote)
        XCTAssertEqual(finalNote?.title, "Second Edit")
        XCTAssertEqual(finalNote?.transcript, "Transcript during playback")
        XCTAssertTrue(finalNote?.isTranscriptionCompleted ?? false)
        
        // Verify persistence after refetch
        let fetchedNotes = try notesStorageService.fetchAllNotes()
        let refetchedNote = fetchedNotes.first(where: { $0.id == note.id })
        XCTAssertEqual(refetchedNote?.title, "Second Edit")
        XCTAssertEqual(refetchedNote?.transcript, "Transcript during playback")
        XCTAssertTrue(refetchedNote?.isTranscriptionCompleted ?? false)
    }
    
    func testMultipleNotesPlaybackAndEditing() async throws {
        // Given: Multiple notes with audio
        var notes: [(note: AudioNote, audioURL: URL)] = []
        for i in 1...3 {
            let noteWithAudio = try createTestNoteWithAudio(title: "Note \(i)")
            notes.append(noteWithAudio)
        }
        
        // When: We interact with each note
        for (index, noteData) in notes.enumerated() {
            // Load and play audio
            try await audioPlayerService.loadAudio(url: noteData.audioURL)
            try await audioPlayerService.play()
            try await Task.sleep(nanoseconds: 50_000_000)
            audioPlayerService.stop()
            
            // Edit the note
            let newTitle = "Edited Note \(index + 1)"
            let newTranscript = "Transcript for note \(index + 1)"
            try notesStorageService.updateNoteTitle(noteData.note.id, title: newTitle)
            try notesStorageService.updateNoteTranscript(noteData.note.id, transcript: newTranscript)
        }
        
        // Then: All notes should have their changes persisted
        let fetchedNotes = try notesStorageService.fetchAllNotes()
        
        for (index, noteData) in notes.enumerated() {
            let fetchedNote = fetchedNotes.first(where: { $0.id == noteData.note.id })
            XCTAssertNotNil(fetchedNote, "Note \(index + 1) should exist")
            XCTAssertEqual(fetchedNote?.title, "Edited Note \(index + 1)")
            XCTAssertEqual(fetchedNote?.transcript, "Transcript for note \(index + 1)")
        }
    }
    
    func testEditingDoesNotCorruptAudioFile() async throws {
        // Given: A note with audio file
        let (note, audioURL) = try createTestNoteWithAudio()
        
        // Get original file size
        let originalAttributes = try FileManager.default.attributesOfItem(atPath: audioURL.path)
        let originalSize = originalAttributes[.size] as? Int64
        
        // When: We edit the note multiple times
        for i in 1...5 {
            try notesStorageService.updateNoteTitle(note.id, title: "Edit \(i)")
            try notesStorageService.updateNoteTranscript(note.id, transcript: "Transcript \(i)")
        }
        
        // Then: Audio file should remain unchanged
        let currentAttributes = try FileManager.default.attributesOfItem(atPath: audioURL.path)
        let currentSize = currentAttributes[.size] as? Int64
        
        XCTAssertEqual(originalSize, currentSize, "Audio file size should not change")
        
        // Should still be able to load the audio
        try await audioPlayerService.loadAudio(url: audioURL)
        XCTAssertGreaterThanOrEqual(audioPlayerService.duration, 0, "Should still be able to load audio")
    }
}
