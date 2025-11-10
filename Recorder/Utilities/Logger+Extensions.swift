//
//  Logger+Extensions.swift
//  Recorder
//
//  Created by Kiro on 11/10/25.
//

import OSLog

extension Logger {
    /// Subsystem identifier for the Recorder app
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app.recorder"
    
    /// Logger for recording-related operations
    /// Use this for audio recording events, microphone permissions, and recording lifecycle
    static let recording = Logger(subsystem: subsystem, category: "recording")
    
    /// Logger for transcription-related operations
    /// Use this for Whisper model loading, transcription progress, and transcription results
    static let transcription = Logger(subsystem: subsystem, category: "transcription")
    
    /// Logger for storage-related operations
    /// Use this for Core Data operations, file system operations, and data persistence
    static let storage = Logger(subsystem: subsystem, category: "storage")
    
    /// Logger for audio playback operations
    /// Use this for audio player events, playback controls, and audio session management
    static let audio = Logger(subsystem: subsystem, category: "audio")
}
