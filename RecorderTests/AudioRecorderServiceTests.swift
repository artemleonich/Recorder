//
//  AudioRecorderServiceTests.swift
//  RecorderTests
//
//  Unit tests for AudioRecorderService
//

import XCTest
import AVFoundation
@testable import Recorder

@MainActor
final class AudioRecorderServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: AudioRecorderService!
    var fileStorageService: FileStorageService!
    var testFileName: String!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        fileStorageService = FileStorageService()
        sut = AudioRecorderService(fileStorageService: fileStorageService)
        testFileName = UUID().uuidString
    }
    
    override func tearDown() async throws {
        // Clean up any test files
        if let fileName = testFileName {
            try? fileStorageService.deleteAudioFile(fileName: "\(fileName).m4a")
        }
        
        sut = nil
        fileStorageService = nil
        testFileName = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Permission Tests
    
    func testRequestPermission_WhenGranted_ReturnsTrue() async throws {
        // Given: Permission is already granted (we can't mock AVAudioSession easily)
        // When: We request permission
        let hasPermission = await sut.requestPermission()
        
        // Then: Result should reflect actual permission status
        // Note: This test will pass if permission is granted, skip if denied
        if AVAudioSession.sharedInstance().recordPermission == .granted {
            XCTAssertTrue(hasPermission, "Should return true when permission is granted")
        }
    }
    
    func testRequestPermission_UpdatesPermissionStatus() async throws {
        // Given: Service is initialized
        // When: We request permission
        let hasPermission = await sut.requestPermission()
        
        // Then: Result should match AVAudioSession permission status
        let actualPermission = AVAudioSession.sharedInstance().recordPermission
        if actualPermission == .granted {
            XCTAssertTrue(hasPermission)
        } else if actualPermission == .denied {
            XCTAssertFalse(hasPermission)
        }
    }
    
    // MARK: - Recording Tests
    
    func testStartRecording_CreatesAudioFile() async throws {
        // Given: Permission is granted
        let hasPermission = await sut.requestPermission()
        guard hasPermission else {
            throw XCTSkip("Microphone permission not granted - skipping test")
        }
        
        // When: We start recording
        try await sut.startRecording(fileName: testFileName)
        
        // Then: Recording should be active
        XCTAssertTrue(sut.isRecording, "isRecording should be true after starting")
        XCTAssertEqual(sut.currentDuration, 0, accuracy: 0.1, "Duration should start at 0")
        
        // Clean up
        await sut.cancelRecording()
    }
    
    func testStartRecording_WithoutPermission_ThrowsError() async throws {
        // Given: Permission is denied (we can't force this, so we'll skip if granted)
        let hasPermission = await sut.requestPermission()
        guard !hasPermission else {
            throw XCTSkip("Microphone permission is granted - cannot test denial case")
        }
        
        // When/Then: Starting recording should throw permission denied error
        do {
            try await sut.startRecording(fileName: testFileName)
            XCTFail("Should throw microphonePermissionDenied error")
        } catch let error as RecorderError {
            if case .microphonePermissionDenied = error {
                // Expected error
            } else {
                XCTFail("Expected microphonePermissionDenied, got \(error)")
            }
        }
    }
    
    func testStopRecording_ReturnsFileURL() async throws {
        // Given: Recording is active
        let hasPermission = await sut.requestPermission()
        guard hasPermission else {
            throw XCTSkip("Microphone permission not granted - skipping test")
        }
        
        try await sut.startRecording(fileName: testFileName)
        
        // Wait a moment for recording to actually start
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // When: We stop recording
        let fileURL = try await sut.stopRecording()
        
        // Then: Should return valid URL and recording should be inactive
        XCTAssertFalse(sut.isRecording, "isRecording should be false after stopping")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "Audio file should exist")
        XCTAssertTrue(fileURL.lastPathComponent.contains(testFileName), "File name should match")
    }
    
    func testStopRecording_WithoutActiveRecording_ThrowsError() async throws {
        // Given: No active recording
        // When/Then: Stopping should throw error
        do {
            _ = try await sut.stopRecording()
            XCTFail("Should throw error when no recording is active")
        } catch {
            // Expected error
            XCTAssertTrue(error is RecorderError, "Should throw RecorderError")
        }
    }
    
    // MARK: - Metrics Update Tests
    
    func testRecording_UpdatesDurationAndAudioLevel() async throws {
        // Given: Recording is active
        let hasPermission = await sut.requestPermission()
        guard hasPermission else {
            throw XCTSkip("Microphone permission not granted - skipping test")
        }
        
        try await sut.startRecording(fileName: testFileName)
        
        // When: We wait for metrics to update
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then: Duration should have increased
        XCTAssertGreaterThan(sut.currentDuration, 0, "Duration should increase during recording")
        
        // Audio level should be in valid range (-160 to 0 dB)
        XCTAssertGreaterThanOrEqual(sut.audioLevel, -160.0, "Audio level should be >= -160 dB")
        XCTAssertLessThanOrEqual(sut.audioLevel, 0.0, "Audio level should be <= 0 dB")
        
        // Clean up
        await sut.cancelRecording()
    }
    
    // MARK: - Cancel Recording Tests
    
    func testCancelRecording_DeletesFile() async throws {
        // Given: Recording is active
        let hasPermission = await sut.requestPermission()
        guard hasPermission else {
            throw XCTSkip("Microphone permission not granted - skipping test")
        }
        
        try await sut.startRecording(fileName: testFileName)
        
        // Get the expected file path
        let recordingsDir = try fileStorageService.getRecordingsDirectory()
        let expectedFilePath = recordingsDir.appendingPathComponent("\(testFileName!).m4a").path
        
        // When: We cancel recording
        await sut.cancelRecording()
        
        // Then: Recording should be inactive and file should be deleted
        XCTAssertFalse(sut.isRecording, "isRecording should be false after canceling")
        XCTAssertEqual(sut.currentDuration, 0, "Duration should be reset to 0")
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedFilePath), "Audio file should be deleted")
    }
    
    func testCancelRecording_ResetsState() async throws {
        // Given: Recording is active
        let hasPermission = await sut.requestPermission()
        guard hasPermission else {
            throw XCTSkip("Microphone permission not granted - skipping test")
        }
        
        try await sut.startRecording(fileName: testFileName)
        
        // Wait for some duration to accumulate
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // When: We cancel recording
        await sut.cancelRecording()
        
        // Then: All state should be reset
        XCTAssertFalse(sut.isRecording, "isRecording should be false")
        XCTAssertEqual(sut.currentDuration, 0, "currentDuration should be 0")
        XCTAssertEqual(sut.audioLevel, 0, "audioLevel should be 0")
    }
}
