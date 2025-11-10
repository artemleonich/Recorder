//
//  PerformanceTests.swift
//  RecorderTests
//
//  Performance tests for critical app operations
//

import XCTest
@testable import Recorder
import CoreData

@MainActor
final class PerformanceTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var storageService: NotesStorageService!
    var fileStorageService: FileStorageService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup in-memory Core Data for testing
        persistenceController = PersistenceController(inMemory: true)
        storageService = NotesStorageService(
            persistenceController: persistenceController
        )
        fileStorageService = FileStorageService()
    }
    
    override func tearDown() async throws {
        storageService = nil
        persistenceController = nil
        fileStorageService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Notes List Loading Performance
    
    /// Test that loading 100 notes takes less than 0.5 seconds
    func testNotesListLoadingPerformance() async throws {
        // Create 100 test notes
        for i in 0..<100 {
            _ = try storageService.createNote(
                title: "Test Note \(i)",
                audioFileName: "test_\(i).m4a",
                duration: Double(i * 10),
                languageCode: "en"
            )
        }
        
        // Measure loading time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try storageService.fetchAllNotes()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        print("📊 Notes list loading time for 100 notes: \(String(format: "%.3f", loadTime))s")
        
        // Assert loading time is under 0.5 seconds
        XCTAssertLessThan(loadTime, 0.5, "Loading 100 notes should take less than 0.5 seconds")
        
        // Verify all notes were loaded
        XCTAssertEqual(storageService.notes.count, 100)
    }
    
    /// Test search performance on large dataset
    func testSearchPerformance() async throws {
        // Create 100 test notes with varied content
        for i in 0..<100 {
            var note = try storageService.createNote(
                title: "Note \(i)",
                audioFileName: "test_\(i).m4a",
                duration: Double(i * 10),
                languageCode: "en"
            )
            
            // Add transcript to some notes
            if i % 3 == 0 {
                try storageService.updateNoteTranscript(
                    note.id,
                    transcript: "This is a test transcript for note number \(i)"
                )
            }
        }
        
        // Measure search time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let results = storageService.searchNotes(query: "test")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let searchTime = endTime - startTime
        
        print("📊 Search time for 100 notes: \(String(format: "%.3f", searchTime))s")
        
        // Assert search time is under 0.1 seconds
        XCTAssertLessThan(searchTime, 0.1, "Searching 100 notes should take less than 0.1 seconds")
        
        // Verify search results
        XCTAssertGreaterThan(results.count, 0)
    }
    
    // MARK: - Memory Management
    
    /// Test that resources are properly released
    func testMemoryManagement() async throws {
        weak var weakStorageService: NotesStorageService?
        
        do {
            let tempService = NotesStorageService(
                persistenceController: persistenceController
            )
            weakStorageService = tempService
            
            // Create some notes
            _ = try tempService.createNote(
                title: "Test",
                audioFileName: "test.m4a",
                duration: 10.0,
                languageCode: "en"
            )
        }
        
        // Service should be deallocated
        XCTAssertNil(weakStorageService, "NotesStorageService should be deallocated when out of scope")
    }
    
    // MARK: - Core Data Performance
    
    /// Test batch operations performance
    func testBatchCreatePerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create 50 notes in sequence
        for i in 0..<50 {
            _ = try storageService.createNote(
                title: "Batch Note \(i)",
                audioFileName: "batch_\(i).m4a",
                duration: 60.0,
                languageCode: "en"
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let createTime = endTime - startTime
        
        print("📊 Batch create time for 50 notes: \(String(format: "%.3f", createTime))s")
        
        // Assert reasonable performance
        XCTAssertLessThan(createTime, 2.0, "Creating 50 notes should take less than 2 seconds")
    }
    
    /// Test update operations performance
    func testBatchUpdatePerformance() async throws {
        // Create 50 notes
        var noteIDs: [UUID] = []
        for i in 0..<50 {
            let note = try storageService.createNote(
                title: "Update Test \(i)",
                audioFileName: "update_\(i).m4a",
                duration: 60.0,
                languageCode: "en"
            )
            noteIDs.append(note.id)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Update all notes
        for (index, noteID) in noteIDs.enumerated() {
            try storageService.updateNoteTranscript(
                noteID,
                transcript: "Updated transcript \(index)"
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let updateTime = endTime - startTime
        
        print("📊 Batch update time for 50 notes: \(String(format: "%.3f", updateTime))s")
        
        // Assert reasonable performance
        XCTAssertLessThan(updateTime, 2.0, "Updating 50 notes should take less than 2 seconds")
    }
    
    // MARK: - File Operations Performance
    
    /// Test file existence check performance
    func testFileExistenceCheckPerformance() throws {
        let testFileName = "performance_test.m4a"
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check existence 1000 times
        for _ in 0..<1000 {
            _ = fileStorageService.audioFileExists(fileName: testFileName)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let checkTime = endTime - startTime
        
        print("📊 File existence check time for 1000 operations: \(String(format: "%.3f", checkTime))s")
        
        // Assert reasonable performance
        XCTAssertLessThan(checkTime, 0.5, "1000 file existence checks should take less than 0.5 seconds")
    }
}
