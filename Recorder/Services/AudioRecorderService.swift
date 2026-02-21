//
//  AudioRecorderService.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import Combine
import Foundation
import OSLog

final class AudioRecorderService: NSObject, ObservableObject {

    @Published var isRecording: Bool = false
    @Published var currentDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private let logger = Logger.recording
    private let fileStorageService: FileStorageService

    init(fileStorageService: FileStorageService = FileStorageService()) {
        self.fileStorageService = fileStorageService
        super.init()
    }

    func requestPermission() async -> Bool {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            let status = await AVAudioApplication.shared.recordPermission

            switch status {
            case .granted:
                return true
            case .denied:
                logger.warning("Microphone permission denied")
                return false
            case .undetermined:
                let granted = await AVAudioApplication.requestRecordPermission()
                logger.info("Microphone permission \(granted ? "granted" : "denied")")
                return granted
            @unknown default:
                return false
            }
        } else {
            let status = AVAudioSession.sharedInstance().recordPermission

            switch status {
            case .granted:
                return true
            case .denied:
                logger.warning("Microphone permission denied")
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        }
        #else
        return true
        #endif
    }

    func startRecording(fileName: String) async throws {
        let hasPermission = await requestPermission()
        guard hasPermission else {
            throw RecorderError.microphonePermissionDenied
        }

        try setupAudioSession()

        let recordingsDirectory = try fileStorageService.getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent("\(fileName).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            guard audioRecorder?.record() == true else {
                throw RecorderError.recordingFailed(NSError(
                    domain: "AudioRecorderService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"]
                ))
            }

            await MainActor.run {
                isRecording = true
                currentDuration = 0
                audioLevel = 0
                startMetricsTimer()
            }

            logger.info("Recording started: \(fileName).m4a")
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            throw RecorderError.recordingFailed(error)
        }
    }

    func stopRecording() async throws -> URL {
        guard isRecording, let recorder = audioRecorder else {
            throw RecorderError.recordingFailed(NSError(
                domain: "AudioRecorderService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No active recording"]
            ))
        }

        recorder.stop()
        let fileURL = recorder.url

        await MainActor.run {
            stopMetricsTimer()
            isRecording = false
            currentDuration = 0
            audioLevel = 0
        }

        logger.info("Recording stopped: \(fileURL.lastPathComponent)")
        audioRecorder = nil
        return fileURL
    }

    func cancelRecording() async {
        guard isRecording, let recorder = audioRecorder else { return }

        let fileURL = recorder.url
        recorder.stop()
        recorder.deleteRecording()

        await MainActor.run {
            stopMetricsTimer()
            isRecording = false
            currentDuration = 0
            audioLevel = 0
        }

        logger.info("Recording cancelled: \(fileURL.lastPathComponent)")
        audioRecorder = nil
    }

    // MARK: - Private

    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
            throw RecorderError.recordingFailed(error)
        }
    }

    @MainActor
    private func startMetricsTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMetrics()
            }
        }
    }

    @MainActor
    private func stopMetricsTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    @MainActor
    private func updateMetrics() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        currentDuration = recorder.currentTime
        recorder.updateMeters()
        audioLevel = recorder.averagePower(forChannel: 0)
    }

    deinit {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                logger.warning("Recording finished unsuccessfully")
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor [weak self] in
            if let error = error {
                self?.logger.error("Recording encode error: \(error.localizedDescription)")
            }
        }
    }
}
