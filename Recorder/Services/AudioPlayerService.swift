//
//  AudioPlayerService.swift
//  Recorder
//
//  Service for managing audio playback
//

import AVFoundation
import Combine
import Foundation
import OSLog

/// Service responsible for audio playback functionality
@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates whether audio is currently playing
    @Published var isPlaying: Bool = false
    
    /// Current playback time in seconds
    @Published var currentTime: TimeInterval = 0
    
    /// Total duration of the loaded audio in seconds
    @Published var duration: TimeInterval = 0
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let logger = Logger.audio
    
    // MARK: - Public Methods
    
    /// Loads an audio file for playback
    /// - Parameter url: URL of the audio file to load
    /// - Throws: RecorderError if the file cannot be loaded
    func loadAudio(url: URL) async throws {
        // Stop any existing playback
        stop()
        
        do {
            // Create audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Update duration
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            
            logger.info("Audio loaded: \(url.lastPathComponent), duration: \(self.duration)s")
            
        } catch {
            logger.error("Failed to load audio: \(error.localizedDescription)")
            throw RecorderError.audioFileNotFound
        }
    }
    
    /// Starts or resumes audio playback
    /// - Throws: RecorderError if no audio is loaded
    func play() async throws {
        guard let player = audioPlayer else {
            throw RecorderError.audioFileNotFound
        }
        
        // Start playback
        guard player.play() else {
            throw RecorderError.generic(NSError(
                domain: "AudioPlayerService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to start playback"]
            ))
        }
        
        // Update state
        isPlaying = true
        
        // Start timer for updating current time
        startTimer()
        
        logger.info("Playback started")
    }
    
    /// Pauses audio playback
    func pause() {
        guard let player = audioPlayer else {
            return
        }
        
        player.pause()
        isPlaying = false
        stopTimer()
        
        logger.info("Playback paused at \(self.currentTime)s")
    }
    
    /// Seeks to a specific time in the audio
    /// - Parameter time: Time position in seconds
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else {
            return
        }
        
        // Clamp time to valid range
        let clampedTime = max(0, min(time, duration))
        
        player.currentTime = clampedTime
        currentTime = clampedTime
        
        logger.debug("Seeked to \(clampedTime)s")
    }
    
    /// Skips forward by the specified number of seconds
    /// - Parameter seconds: Number of seconds to skip forward (default: 10)
    func skipForward(seconds: TimeInterval = 10) {
        guard let player = audioPlayer else {
            return
        }
        
        let newTime = min(player.currentTime + seconds, duration)
        seek(to: newTime)
        
        logger.debug("Skipped forward \(seconds)s to \(newTime)s")
    }
    
    /// Skips backward by the specified number of seconds
    /// - Parameter seconds: Number of seconds to skip backward (default: 10)
    func skipBackward(seconds: TimeInterval = 10) {
        guard let player = audioPlayer else {
            return
        }
        
        let newTime = max(player.currentTime - seconds, 0)
        seek(to: newTime)
        
        logger.debug("Skipped backward \(seconds)s to \(newTime)s")
    }
    
    /// Stops playback and resets to the beginning
    func stop() {
        guard let player = audioPlayer else {
            return
        }
        
        player.stop()
        player.currentTime = 0
        
        isPlaying = false
        currentTime = 0
        stopTimer()
        
        logger.info("Playback stopped")
    }
    
    // MARK: - Private Methods
    
    /// Starts the timer for updating current time
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCurrentTime()
            }
        }
    }
    
    /// Stops the current time update timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Updates the current playback time
    private func updateCurrentTime() {
        guard let player = audioPlayer, player.isPlaying else {
            return
        }
        
        currentTime = player.currentTime
    }
    
    // MARK: - Deinitialization
    
    deinit {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        logger.debug("AudioPlayerService deinitialized")
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            // Stop playback and reset to beginning
            isPlaying = false
            currentTime = 0
            stopTimer()
            
            // Reset player position
            audioPlayer?.currentTime = 0
            
            logger.info("Playback finished \(flag ? "successfully" : "with error")")
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            if let error = error {
                self.logger.error("Audio decode error: \(error.localizedDescription)")
            }
            
            // Stop playback on error
            self.isPlaying = false
            self.stopTimer()
        }
    }
}
