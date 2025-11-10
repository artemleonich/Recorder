//
//  TranscriptionMode.swift
//  Recorder
//
//  Enum representing transcription modes with different speed/accuracy tradeoffs
//

import Foundation

enum TranscriptionMode: String, CaseIterable, Codable {
    /// Fast transcription using tiny/base Whisper model
    case fast
    
    /// Accurate transcription using small/medium Whisper model
    case accurate
    
    // MARK: - Computed Properties
    
    /// Human-readable display name for the mode
    var displayName: String {
        switch self {
        case .fast:
            return NSLocalizedString("transcription.mode.fast", comment: "Fast transcription mode")
        case .accurate:
            return NSLocalizedString("transcription.mode.accurate", comment: "Accurate transcription mode")
        }
    }
    
    /// Whisper model name to use for this mode
    var modelName: String {
        switch self {
        case .fast:
            return "openai_whisper-base"
        case .accurate:
            return "openai_whisper-small"
        }
    }
    
    /// Description of the mode for settings UI
    var description: String {
        switch self {
        case .fast:
            return NSLocalizedString("transcription.mode.fast.description", comment: "Fast mode description")
        case .accurate:
            return NSLocalizedString("transcription.mode.accurate.description", comment: "Accurate mode description")
        }
    }
}
