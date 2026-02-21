//
//  AudioPlayerServiceTests.swift
//  RecorderTests
//
//  Created by Артём Леонов on 11/10/25.
//

import XCTest
import AVFoundation
@testable import Recorder

@MainActor
final class AudioPlayerServiceTests: XCTestCase {

    var sut: AudioPlayerService!
    var testAudioURL: URL!

    override func setUp() async throws {
        try await super.setUp()

        sut = AudioPlayerService()
        testAudioURL = try createTestAudioFile()
    }

    override func tearDown() async throws {
        sut.stop()

        if let url = testAudioURL {
            try? FileManager.default.removeItem(at: url)
        }

        sut = nil
        testAudioURL = nil

        try await super.tearDown()
    }

    private func createTestAudioFile() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFileName = "\(UUID().uuidString).m4a"
        let testFileURL = tempDirectory.appendingPathComponent(testFileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: testFileURL, settings: settings)
        recorder.record()
        Thread.sleep(forTimeInterval: 0.5)
        recorder.stop()

        return testFileURL
    }

    // MARK: - Load Audio

    func testLoadAudio_LoadsFileSuccessfully() async throws {
        try await sut.loadAudio(url: testAudioURL)

        XCTAssertGreaterThan(sut.duration, 0, "Duration should be greater than 0")
        XCTAssertEqual(sut.currentTime, 0, "Current time should start at 0")
        XCTAssertFalse(sut.isPlaying, "Should not be playing initially")
    }

    func testLoadAudio_WithNonExistentFile_ThrowsError() async throws {
        let nonExistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent.m4a")

        do {
            try await sut.loadAudio(url: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch let error as RecorderError {
            if case .audioFileNotFound = error {
            } else {
                XCTFail("Expected audioFileNotFound error, got \(error)")
            }
        }
    }

    func testLoadAudio_StopsExistingPlayback() async throws {
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()

        XCTAssertTrue(sut.isPlaying, "Should be playing")

        let newAudioURL = try createTestAudioFile()
        try await sut.loadAudio(url: newAudioURL)

        XCTAssertFalse(sut.isPlaying, "Should not be playing after loading new file")
        XCTAssertEqual(sut.currentTime, 0, "Current time should be reset")

        try? FileManager.default.removeItem(at: newAudioURL)
    }

    // MARK: - Playback

    func testPlay_StartsPlayback() async throws {
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()

        XCTAssertTrue(sut.isPlaying, "isPlaying should be true after play")
    }

    func testPlay_WithoutLoadedAudio_ThrowsError() async throws {
        do {
            try await sut.play()
            XCTFail("Should throw error when no audio is loaded")
        } catch {
            XCTAssertTrue(error is RecorderError, "Should throw RecorderError")
        }
    }

    func testPlay_UpdatesCurrentTime() async throws {
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()

        let initialTime = sut.currentTime

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertGreaterThan(sut.currentTime, initialTime, "Current time should increase during playback")
    }

    func testPause_StopsPlayback() async throws {
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()

        XCTAssertTrue(sut.isPlaying, "Should be playing")

        sut.pause()

        XCTAssertFalse(sut.isPlaying, "isPlaying should be false after pause")
    }

    func testPause_PreservesCurrentTime() async throws {
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()

        try await Task.sleep(nanoseconds: 100_000_000)

        let timeBeforePause = sut.currentTime

        sut.pause()

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.currentTime, timeBeforePause, accuracy: 0.1, "Current time should be preserved after pause")
    }

    func testSeek_ChangesCurrentTime() async throws {
        try await sut.loadAudio(url: testAudioURL)

        let targetTime: TimeInterval = 0.2

        sut.seek(to: targetTime)

        XCTAssertEqual(sut.currentTime, targetTime, accuracy: 0.1, "Current time should match seek target")
    }

    func testSeek_ClampsToValidRange() async throws {
        try await sut.loadAudio(url: testAudioURL)

        sut.seek(to: sut.duration + 10)
        XCTAssertLessThanOrEqual(sut.currentTime, sut.duration, "Should not seek beyond duration")

        sut.seek(to: -10)
        XCTAssertGreaterThanOrEqual(sut.currentTime, 0, "Should not seek to negative time")
    }

    func testSkipForward_AdvancesTime() async throws {
        try await sut.loadAudio(url: testAudioURL)

        let initialTime = sut.currentTime
        let skipAmount: TimeInterval = 10

        sut.skipForward(seconds: skipAmount)

        let expectedTime = min(initialTime + skipAmount, sut.duration)
        XCTAssertEqual(sut.currentTime, expectedTime, accuracy: 0.1, "Should skip forward by specified amount")
    }

    func testSkipForward_DoesNotExceedDuration() async throws {
        try await sut.loadAudio(url: testAudioURL)
        sut.seek(to: sut.duration - 1)

        sut.skipForward(seconds: 10)

        XCTAssertLessThanOrEqual(sut.currentTime, sut.duration, "Should not exceed duration")
    }

    func testSkipBackward_RewindsTime() async throws {
        try await sut.loadAudio(url: testAudioURL)
        sut.seek(to: 0.3)

        let initialTime = sut.currentTime
        let skipAmount: TimeInterval = 10

        sut.skipBackward(seconds: skipAmount)

        let expectedTime = max(initialTime - skipAmount, 0)
        XCTAssertEqual(sut.currentTime, expectedTime, accuracy: 0.1, "Should skip backward by specified amount")
    }

    func testSkipBackward_DoesNotGoBelowZero() async throws {
        try await sut.loadAudio(url: testAudioURL)
        sut.seek(to: 0.1)

        sut.skipBackward(seconds: 10)

        XCTAssertGreaterThanOrEqual(sut.currentTime, 0, "Should not go below 0")
    }

    func testStop_ResetsPlayback() async throws {
        try await sut.loadAudio(url: testAudioURL)
        try await sut.play()

        try await Task.sleep(nanoseconds: 100_000_000)

        sut.stop()

        XCTAssertFalse(sut.isPlaying, "Should not be playing after stop")
        XCTAssertEqual(sut.currentTime, 0, "Current time should be reset to 0")
    }

    func testPlayback_StopsAutomaticallyAtEnd() async throws {
        try await sut.loadAudio(url: testAudioURL)

        sut.seek(to: sut.duration - 0.1)

        try await sut.play()

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertFalse(sut.isPlaying, "Should stop playing at end")
        XCTAssertEqual(sut.currentTime, 0, accuracy: 0.1, "Should reset to beginning")
    }
}
