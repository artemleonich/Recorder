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
                // If record() fails the session is still active — clean up
                // before throwing so we don't leak it.
                teardownAudioSession()
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

        // Deactivate the audio session so other audio apps (music,
        // phone calls) resume normally. ``.notifyOthersOnDeactivation``
        // asks the system to pause-and-resume other audio sources
        // gracefully instead of cutting them off.
        teardownAudioSession()

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

        // Always deactivate the session, even when the user cancels
        // mid-recording. The previous version left the session active
        // and broke other audio apps on the device.
        teardownAudioSession()

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

    /// Deactivates the shared audio session. Safe to call multiple times
    /// and when no session is active — ``setActive(_:options:)`` will
    /// just log and return an error that we intentionally swallow here
    /// because teardown failures are not user-facing.
    ///
    /// We pass ``.notifyOthersOnDeactivation`` so any other audio app
    /// (Music, Podcasts, etc.) that's been paused because of our
    /// ``.playAndRecord`` category gets cleanly resumed when the user
    /// leaves Recording.
    private func teardownAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
        } catch {
            // ``setActive(false)`` returns an error if the session is
            // already inactive (which is normal — cancel-after-stop
            // races, idempotent callers, etc.) — we ignore those.
            logger.debug("Audio session teardown returned: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func startMetricsTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            // Single Task wrapper, single [weak self] — the previous
            // version had a nested [weak self] in [weak self] which was
            // a code smell. ``Task { @MainActor in }`` already isolates
            // onto the main actor and the outer closure is non-escaping
            // once the timer is invalidated.
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
        // Best-effort stop. The recorder is already nil or stopping on
        // happy paths; this catches the case where the object is
        // deallocated while a recording is still in flight.
        audioRecorder?.stop()
        // Don't touch AVAudioSession from deinit — it's MainActor-isolated
        // state and deinit may run off the main actor. The session is
        // also automatically deactivated when the app is suspended.
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