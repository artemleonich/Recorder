//
//  AudioPlayerService.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import AVFoundation
import Combine
import Foundation
import OSLog

@MainActor
final class AudioPlayerService: NSObject, ObservableObject {

    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let logger = Logger.audio

    func loadAudio(url: URL) async throws {
        stop()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            logger.info("Audio loaded: \(url.lastPathComponent), duration: \(self.duration)s")
        } catch {
            logger.error("Failed to load audio: \(error.localizedDescription)")
            throw RecorderError.audioFileNotFound
        }
    }

    func play() async throws {
        guard let player = audioPlayer else {
            throw RecorderError.audioFileNotFound
        }

        guard player.play() else {
            throw RecorderError.generic(NSError(
                domain: "AudioPlayerService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to start playback"]
            ))
        }

        isPlaying = true
        startTimer()
        logger.info("Playback started")
    }

    func pause() {
        guard let player = audioPlayer else { return }
        player.pause()
        isPlaying = false
        stopTimer()
        logger.info("Playback paused at \(self.currentTime)s")
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
    }

    func skipForward(seconds: TimeInterval = 10) {
        guard let player = audioPlayer else { return }
        let newTime = min(player.currentTime + seconds, duration)
        seek(to: newTime)
    }

    func skipBackward(seconds: TimeInterval = 10) {
        guard let player = audioPlayer else { return }
        let newTime = max(player.currentTime - seconds, 0)
        seek(to: newTime)
    }

    func stop() {
        guard let player = audioPlayer else { return }
        player.stop()
        player.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCurrentTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateCurrentTime() {
        guard let player = audioPlayer, player.isPlaying else { return }
        currentTime = player.currentTime
    }

    deinit {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
            stopTimer()
            audioPlayer?.currentTime = 0
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            if let error = error {
                self.logger.error("Audio decode error: \(error.localizedDescription)")
            }
            self.isPlaying = false
            self.stopTimer()
        }
    }
}
