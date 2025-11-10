//
//  AudioPlayerServiceTests.swift
//  RecorderTests
//
//  Unit tests for AudioPlayerService
//

import XCTest
import AVFoundation
@testable import Recorder

@MainActor
final class AudioPlayerServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: AudioPlayerService!
    var testAudioURL: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        sut = AudioPlayerService()
        testAudioURL = try createTestAudioFile()
    }
    
    override func tearDown() async throws {
        // Clean up
        sut.stop()
        
        if let url = testAudioURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        sut = nil
        testAudioURL = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestAudioFile() throws -> URL {
        // Create a simple audio file for testing
        // We'll create a very short silent audio file
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFileName = "\(UUID().uuidString).m4a"
        let testFileURL = tempDirectory.appendingPathComponent(testFileName)
        
        // Create audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create a short recording
        let recorder = try AVAudioRecorder(url: testFileURL, settings: settings)
        recorder.record()
        
        // Record for a very short time
        Thread.sleep(forTimeInterval: 0.5)
        
        recorder.stop()
        
        return testFileURL
    }
    
    // MARK: - Load Audio Tests
    
    func testLoadAudio_LoadsFileSuccessfully() async throws {
        // When: We load an audio file
        try await sut.loadAudio(url: testAudioURL)
        
        // Then: Duration should be set
        XCTAssertGreaterThan(sut.duration, 0, "Duration should be greater than 0")
        XCTAssertEqual(sut.currentTime, 0, "Current time should start at 0")
        XCTAssertFalse(sut.isPlaying, "Should not be playing initially")
    }
    
    func testLoadAudio_WithNonExistentFile_ThrowsError() async throws {
        // Given: A non-existent file URL
        let nonExistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent.m4a")
        
        // When/Then: Loading should throw error
        do {
            try await sut.loadAudio(url: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch let error as RecorderError {
            if case .audioFileNotFound = error {
                // Expected error
            } else {
                XCTFail("Expected audioFileNotFound error, got \(error)")
            }
        }
    }
    
    func testLoadAudio_StopsExistingPlayback() async throws {
        // Given: Audio is loaded and playing
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()
        
        XCTAssertTrue(sut.isPlaying, "Should be playing")
        
        // When: We load a new audio file
        let newAudioURL = try createTestAudioFile()
        try await sut.loadAudio(url: newAudioURL)
        
        // Then: Playback should be stopped
        XCTAssertFalse(sut.isPlaying, "Should not be playing after loading new file")
        XCTAssertEqual(sut.currentTime, 0, "Current time should be reset")
        
        // Clean up
        try? FileManager.default.removeItem(at: newAudioURL)
    }
    
    // MARK: - Play Tests
    
    func testPlay_StartsPlayback() async throws {
        // Given: Audio is loaded
        try await sut.loadAudio(url: testAudioURL)
        
        // When: We start playback
        try await sut.play()
        
        // Then: isPlaying should be true
        XCTAssertTrue(sut.isPlaying, "isPlaying should be true after play")
    }
    
    func testPlay_WithoutLoadedAudio_ThrowsError() async throws {
        // Given: No audio is loaded
        // When/Then: Playing should throw error
        do {
            try await sut.play()
            XCTFail("Should throw error when no audio is loaded")
        } catch {
            XCTAssertTrue(error is RecorderError, "Should throw RecorderError")
        }
    }
    
    func testPlay_UpdatesCurrentTime() async throws {
        // Given: Audio is loaded and playing
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()
        
        let initialTime = sut.currentTime
        
        // When: We wait for playback to progress
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then: Current time should have increased
        XCTAssertGreaterThan(sut.currentTime, initialTime, "Current time should increase during playback")
    }
    
    // MARK: - Pause Tests
    
    func testPause_StopsPlayback() async throws {
        // Given: Audio is playing
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()
        
        XCTAssertTrue(sut.isPlaying, "Should be playing")
        
        // When: We pause
        sut.pause()
        
        // Then: isPlaying should be false
        XCTAssertFalse(sut.isPlaying, "isPlaying should be false after pause")
    }
    
    func testPause_PreservesCurrentTime() async throws {
        // Given: Audio is playing
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()
        
        // Wait for some playback
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let timeBeforePause = sut.currentTime
        
        // When: We pause
        sut.pause()
        
        // Wait a moment
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Current time should not have changed significantly
        XCTAssertEqual(sut.currentTime, timeBeforePause, accuracy: 0.1, "Current time should be preserved after pause")
    }
    
    // MARK: - Seek Tests
    
    func testSeek_ChangesCurrentTime() async throws {
        // Given: Audio is loaded
        try await sut.loadAudio(url: testAudioURL)
        
        let targetTime: TimeInterval = 0.2
        
        // When: We seek to a specific time
        sut.seek(to: targetTime)
        
        // Then: Current time should be updated
        XCTAssertEqual(sut.currentTime, targetTime, accuracy: 0.1, "Current time should match seek target")
    }
    
    func testSeek_ClampsToValidRange() async throws {
        // Given: Audio is loaded
        try await sut.loadAudio(url: testAudioURL)
        
        // When: We seek beyond the duration
        sut.seek(to: sut.duration + 10)
        
        // Then: Should clamp to duration
        XCTAssertLessThanOrEqual(sut.currentTime, sut.duration, "Should not seek beyond duration")
        
        // When: We seek to negative time
        sut.seek(to: -10)
        
        // Then: Should clamp to 0
        XCTAssertGreaterThanOrEqual(sut.currentTime, 0, "Should not seek to negative time")
    }
    
    // MARK: - Skip Forward Tests
    
    func testSkipForward_AdvancesTime() async throws {
        // Given: Audio is loaded
        try await sut.loadAudio(url: testAudioURL)
        
        let initialTime = sut.currentTime
        let skipAmount: TimeInterval = 10
        
        // When: We skip forward
        sut.skipForward(seconds: skipAmount)
        
        // Then: Current time should advance (or reach end)
        let expectedTime = min(initialTime + skipAmount, sut.duration)
        XCTAssertEqual(sut.currentTime, expectedTime, accuracy: 0.1, "Should skip forward by specified amount")
    }
    
    func testSkipForward_DoesNotExceedDuration() async throws {
        // Given: Audio is loaded near the end
        try await sut.loadAudio(url: testAudioURL)
        sut.seek(to: sut.duration - 1)
        
        // When: We skip forward beyond the end
        sut.skipForward(seconds: 10)
        
        // Then: Should not exceed duration
        XCTAssertLessThanOrEqual(sut.currentTime, sut.duration, "Should not exceed duration")
    }
    
    // MARK: - Skip Backward Tests
    
    func testSkipBackward_RewindsTime() async throws {
        // Given: Audio is loaded at a position
        try await sut.loadAudio(url: testAudioURL)
        sut.seek(to: 0.3)
        
        let initialTime = sut.currentTime
        let skipAmount: TimeInterval = 10
        
        // When: We skip backward
        sut.skipBackward(seconds: skipAmount)
        
        // Then: Current time should rewind (or reach start)
        let expectedTime = max(initialTime - skipAmount, 0)
        XCTAssertEqual(sut.currentTime, expectedTime, accuracy: 0.1, "Should skip backward by specified amount")
    }
    
    func testSkipBackward_DoesNotGoBelowZero() async throws {
        // Given: Audio is loaded near the beginning
        try await sut.loadAudio(url: testAudioURL)
        sut.seek(to: 0.1)
        
        // When: We skip backward beyond the start
        sut.skipBackward(seconds: 10)
        
        // Then: Should not go below 0
        XCTAssertGreaterThanOrEqual(sut.currentTime, 0, "Should not go below 0")
    }
    
    // MARK: - Stop Tests
    
    func testStop_ResetsPlayback() async throws {
        // Given: Audio is playing
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()
        
        // Wait for some playback
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // When: We stop
        sut.stop()
        
        // Then: Should reset to beginning and stop playing
        XCTAssertFalse(sut.isPlaying, "Should not be playing after stop")
        XCTAssertEqual(sut.currentTime, 0, "Current time should be reset to 0")
    }
    
    // MARK: - Automatic Stop Tests
    
    func testPlayback_StopsAutomaticallyAtEnd() async throws {
        // Given: Audio is loaded
        try await sut.loadAudio(url: testAudioURL)
        
        // Seek near the end
        sut.seek(to: sut.duration - 0.1)
        
        // When: We start playback
        try await sut.play()
        
        // Wait for playback to finish
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then: Should stop automatically
        XCTAssertFalse(sut.isPlaying, "Should stop playing at end")
        XCTAssertEqual(sut.currentTime, 0, accuracy: 0.1, "Should reset to beginning")
    }
}
