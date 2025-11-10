//
//  AudioRecorderService.swift
//  Recorder
//
//  Service for managing audio recording through the device microphone
//

#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import Combine
import Foundation
import OSLog

/// Service responsible for audio recording functionality
final class AudioRecorderService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates whether recording is currently active
    @Published var isRecording: Bool = false
    
    /// Current duration of the recording in seconds
    @Published var currentDuration: TimeInterval = 0
    
    /// Current audio level in decibels (-160.0 to 0.0)
    @Published var audioLevel: Float = 0
    
    // MARK: - Private Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private let logger = Logger.recording
    private let fileStorageService: FileStorageService
    
    // MARK: - Initialization
    
    init(fileStorageService: FileStorageService = FileStorageService()) {
        self.fileStorageService = fileStorageService
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Requests microphone permission from the user
    /// - Returns: true if permission is granted, false otherwise
    func requestPermission() async -> Bool {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            let status = await AVAudioApplication.shared.recordPermission
            
            switch status {
            case .granted:
                logger.info("Microphone permission already granted")
                return true
                
            case .denied:
                logger.warning("Microphone permission denied")
                return false
                
            case .undetermined:
                logger.info("Requesting microphone permission")
                let granted = await AVAudioApplication.requestRecordPermission()
                logger.info("Microphone permission \(granted ? "granted" : "denied")")
                return granted
                
            @unknown default:
                logger.error("Unknown microphone permission status")
                return false
            }
        } else {
            // Fallback for iOS 16 and earlier
            let status = AVAudioSession.sharedInstance().recordPermission
            
            switch status {
            case .granted:
                logger.info("Microphone permission already granted")
                return true
                
            case .denied:
                logger.warning("Microphone permission denied")
                return false
                
            case .undetermined:
                logger.info("Requesting microphone permission")
                return await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        self.logger.info("Microphone permission \(granted ? "granted" : "denied")")
                        continuation.resume(returning: granted)
                    }
                }
                
            @unknown default:
                logger.error("Unknown microphone permission status")
                return false
            }
        }
        #else
        return true
        #endif
    }
    
    /// Starts recording audio with the specified filename
    /// - Parameter fileName: Name for the audio file (without extension)
    /// - Throws: RecorderError if recording fails to start
    func startRecording(fileName: String) async throws {
        // Check permission first
        let hasPermission = await requestPermission()
        guard hasPermission else {
            throw RecorderError.microphonePermissionDenied
        }
        
        // Setup audio session
        try setupAudioSession()
        
        // Get recording directory and create file URL
        let recordingsDirectory = try fileStorageService.getRecordingsDirectory()
        let fileURL = recordingsDirectory.appendingPathComponent("\(fileName).m4a")
        
        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // Create and configure audio recorder
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            // Start recording
            guard audioRecorder?.record() == true else {
                throw RecorderError.recordingFailed(NSError(
                    domain: "AudioRecorderService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"]
                ))
            }
            
            // Update state on main actor
            await MainActor.run {
                isRecording = true
                currentDuration = 0
                audioLevel = 0
                
                // Start timer for updating metrics
                startMetricsTimer()
            }
            
            logger.info("Recording started: \(fileName).m4a")
            
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            throw RecorderError.recordingFailed(error)
        }
    }
    
    /// Stops the current recording and returns the file URL
    /// - Returns: URL of the recorded audio file
    /// - Throws: RecorderError if no recording is active or stopping fails
    func stopRecording() async throws -> URL {
        guard isRecording, let recorder = audioRecorder else {
            throw RecorderError.recordingFailed(NSError(
                domain: "AudioRecorderService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No active recording"]
            ))
        }
        
        // Stop recording
        recorder.stop()
        
        let fileURL = recorder.url
        
        // Update state on main actor
        await MainActor.run {
            // Stop timer
            stopMetricsTimer()
            
            // Update state
            isRecording = false
            currentDuration = 0
            audioLevel = 0
        }
        
        logger.info("Recording stopped: \(fileURL.lastPathComponent)")
        
        // Clean up
        audioRecorder = nil
        
        return fileURL
    }
    
    /// Cancels the current recording and deletes the file
    func cancelRecording() async {
        guard isRecording, let recorder = audioRecorder else {
            return
        }
        
        let fileURL = recorder.url
        
        // Stop recording
        recorder.stop()
        recorder.deleteRecording()
        
        // Update state on main actor
        await MainActor.run {
            // Stop timer
            stopMetricsTimer()
            
            // Update state
            isRecording = false
            currentDuration = 0
            audioLevel = 0
        }
        
        logger.info("Recording cancelled: \(fileURL.lastPathComponent)")
        
        // Clean up
        audioRecorder = nil
    }
    
    // MARK: - Private Methods
    
    /// Sets up the audio session for recording
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            logger.info("Audio session configured for recording")
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
            throw RecorderError.recordingFailed(error)
        }
    }
    
    /// Starts the timer for updating recording metrics
    @MainActor
    private func startMetricsTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMetrics()
            }
        }
    }
    
    /// Stops the metrics update timer
    @MainActor
    private func stopMetricsTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    /// Updates current duration and audio level
    @MainActor
    private func updateMetrics() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return
        }
        
        // Update duration
        currentDuration = recorder.currentTime
        
        // Update audio level
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        audioLevel = averagePower
    }
    
    // MARK: - Deinitialization
    
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
