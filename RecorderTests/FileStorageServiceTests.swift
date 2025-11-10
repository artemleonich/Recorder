//
//  FileStorageServiceTests.swift
//  RecorderTests
//
//  Unit tests for FileStorageService
//

import XCTest
@testable import Recorder

final class FileStorageServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: FileStorageService!
    var testFileNames: [String] = []
    var testDirectory: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() throws {
        try super.setUp()
        
        sut = FileStorageService()
        testFileNames = []
        testDirectory = try sut.getRecordingsDirectory()
    }
    
    override func tearDown() throws {
        // Clean up all test files
        for fileName in testFileNames {
            try? sut.deleteAudioFile(fileName: fileName)
        }
        
        testFileNames = []
        sut = nil
        testDirectory = nil
        
        try super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestAudioFile() throws -> URL {
        // Create a temporary test file
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFileName = "\(UUID().uuidString).m4a"
        let testFileURL = tempDirectory.appendingPathComponent(testFileName)
        
        // Write some dummy data
        let testData = "Test audio data".data(using: .utf8)!
        try testData.write(to: testFileURL)
        
        return testFileURL
    }
    
    // MARK: - Get Recordings Directory Tests
    
    func testGetRecordingsDirectory_CreatesDirectoryIfNotExists() throws {
        // When: We get the recordings directory
        let directory = try sut.getRecordingsDirectory()
        
        // Then: Directory should exist
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory)
        
        XCTAssertTrue(exists, "Recordings directory should exist")
        XCTAssertTrue(isDirectory.boolValue, "Path should be a directory")
        XCTAssertTrue(directory.lastPathComponent == "Recordings", "Directory should be named 'Recordings'")
    }
    
    func testGetRecordingsDirectory_ReturnsConsistentPath() throws {
        // When: We call getRecordingsDirectory multiple times
        let directory1 = try sut.getRecordingsDirectory()
        let directory2 = try sut.getRecordingsDirectory()
        
        // Then: Should return the same path
        XCTAssertEqual(directory1, directory2, "Should return consistent directory path")
    }
    
    // MARK: - Save Audio File Tests
    
    func testSaveAudioFile_CopiesFileToRecordingsDirectory() throws {
        // Given: A test audio file
        let sourceURL = try createTestAudioFile()
        let fileName = "\(UUID().uuidString).m4a"
        testFileNames.append(fileName)
        
        // When: We save the audio file
        let savedURL = try sut.saveAudioFile(from: sourceURL, withName: fileName)
        
        // Then: File should be copied to recordings directory
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path), "Saved file should exist")
        XCTAssertEqual(savedURL.lastPathComponent, fileName, "File name should match")
        XCTAssertTrue(savedURL.path.contains("Recordings"), "File should be in Recordings directory")
        
        // Clean up source file
        try? FileManager.default.removeItem(at: sourceURL)
    }
    
    func testSaveAudioFile_OverwritesExistingFile() throws {
        // Given: An existing file with the same name
        let sourceURL1 = try createTestAudioFile()
        let fileName = "\(UUID().uuidString).m4a"
        testFileNames.append(fileName)
        
        let savedURL1 = try sut.saveAudioFile(from: sourceURL1, withName: fileName)
        let originalData = try Data(contentsOf: savedURL1)
        
        // When: We save another file with the same name
        let sourceURL2 = try createTestAudioFile()
        let newData = "Different test data".data(using: .utf8)!
        try newData.write(to: sourceURL2)
        
        let savedURL2 = try sut.saveAudioFile(from: sourceURL2, withName: fileName)
        let newSavedData = try Data(contentsOf: savedURL2)
        
        // Then: File should be overwritten
        XCTAssertEqual(savedURL1, savedURL2, "URLs should be the same")
        XCTAssertNotEqual(originalData, newSavedData, "File content should be different")
        
        // Clean up source files
        try? FileManager.default.removeItem(at: sourceURL1)
        try? FileManager.default.removeItem(at: sourceURL2)
    }
    
    func testSaveAudioFile_WithNonExistentSource_ThrowsError() throws {
        // Given: A non-existent source file
        let nonExistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent.m4a")
        let fileName = "\(UUID().uuidString).m4a"
        
        // When/Then: Saving should throw error
        XCTAssertThrowsError(try sut.saveAudioFile(from: nonExistentURL, withName: fileName)) { error in
            XCTAssertTrue(error is RecorderError, "Should throw RecorderError")
        }
    }
    
    // MARK: - Delete Audio File Tests
    
    func testDeleteAudioFile_RemovesFileFromDirectory() throws {
        // Given: A saved audio file
        let sourceURL = try createTestAudioFile()
        let fileName = "\(UUID().uuidString).m4a"
        
        let savedURL = try sut.saveAudioFile(from: sourceURL, withName: fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path), "File should exist before deletion")
        
        // When: We delete the file
        try sut.deleteAudioFile(fileName: fileName)
        
        // Then: File should be removed
        XCTAssertFalse(FileManager.default.fileExists(atPath: savedURL.path), "File should not exist after deletion")
        
        // Clean up source file
        try? FileManager.default.removeItem(at: sourceURL)
    }
    
    func testDeleteAudioFile_WithNonExistentFile_DoesNotThrow() throws {
        // Given: A non-existent file name
        let nonExistentFileName = "\(UUID().uuidString).m4a"
        
        // When/Then: Deleting should not throw (graceful handling)
        XCTAssertNoThrow(try sut.deleteAudioFile(fileName: nonExistentFileName))
    }
    
    // MARK: - Audio File Exists Tests
    
    func testAudioFileExists_WithExistingFile_ReturnsTrue() throws {
        // Given: A saved audio file
        let sourceURL = try createTestAudioFile()
        let fileName = "\(UUID().uuidString).m4a"
        testFileNames.append(fileName)
        
        _ = try sut.saveAudioFile(from: sourceURL, withName: fileName)
        
        // When: We check if file exists
        let exists = sut.audioFileExists(fileName: fileName)
        
        // Then: Should return true
        XCTAssertTrue(exists, "Should return true for existing file")
        
        // Clean up source file
        try? FileManager.default.removeItem(at: sourceURL)
    }
    
    func testAudioFileExists_WithNonExistentFile_ReturnsFalse() throws {
        // Given: A non-existent file name
        let nonExistentFileName = "\(UUID().uuidString).m4a"
        
        // When: We check if file exists
        let exists = sut.audioFileExists(fileName: nonExistentFileName)
        
        // Then: Should return false
        XCTAssertFalse(exists, "Should return false for non-existent file")
    }
    
    func testAudioFileExists_AfterDeletion_ReturnsFalse() throws {
        // Given: A saved audio file that we then delete
        let sourceURL = try createTestAudioFile()
        let fileName = "\(UUID().uuidString).m4a"
        
        _ = try sut.saveAudioFile(from: sourceURL, withName: fileName)
        try sut.deleteAudioFile(fileName: fileName)
        
        // When: We check if file exists
        let exists = sut.audioFileExists(fileName: fileName)
        
        // Then: Should return false
        XCTAssertFalse(exists, "Should return false after deletion")
        
        // Clean up source file
        try? FileManager.default.removeItem(at: sourceURL)
    }
    
    // MARK: - Get Audio File URL Tests
    
    func testGetAudioFileURL_WithExistingFile_ReturnsCorrectURL() throws {
        // Given: A saved audio file
        let sourceURL = try createTestAudioFile()
        let fileName = "\(UUID().uuidString).m4a"
        testFileNames.append(fileName)
        
        let savedURL = try sut.saveAudioFile(from: sourceURL, withName: fileName)
        
        // When: We get the file URL
        let retrievedURL = try sut.getAudioFileURL(fileName: fileName)
        
        // Then: Should return correct URL
        XCTAssertEqual(retrievedURL, savedURL, "Retrieved URL should match saved URL")
        XCTAssertTrue(FileManager.default.fileExists(atPath: retrievedURL.path), "File should exist at URL")
        
        // Clean up source file
        try? FileManager.default.removeItem(at: sourceURL)
    }
    
    func testGetAudioFileURL_WithNonExistentFile_ThrowsError() throws {
        // Given: A non-existent file name
        let nonExistentFileName = "\(UUID().uuidString).m4a"
        
        // When/Then: Getting URL should throw error
        XCTAssertThrowsError(try sut.getAudioFileURL(fileName: nonExistentFileName)) { error in
            guard let recorderError = error as? RecorderError else {
                XCTFail("Should throw RecorderError")
                return
            }
            
            if case .audioFileNotFound = recorderError {
                // Expected error
            } else {
                XCTFail("Should throw audioFileNotFound error")
            }
        }
    }
    
    func testGetAudioFileURL_ReturnsPathInRecordingsDirectory() throws {
        // Given: A saved audio file
        let sourceURL = try createTestAudioFile()
        let fileName = "\(UUID().uuidString).m4a"
        testFileNames.append(fileName)
        
        _ = try sut.saveAudioFile(from: sourceURL, withName: fileName)
        
        // When: We get the file URL
        let fileURL = try sut.getAudioFileURL(fileName: fileName)
        
        // Then: URL should be in Recordings directory
        XCTAssertTrue(fileURL.path.contains("Recordings"), "File should be in Recordings directory")
        XCTAssertEqual(fileURL.lastPathComponent, fileName, "File name should match")
        
        // Clean up source file
        try? FileManager.default.removeItem(at: sourceURL)
    }
}
