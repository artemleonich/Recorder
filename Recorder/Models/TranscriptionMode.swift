//
//  TranscriptionMode.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation

enum TranscriptionMode: String, CaseIterable, Codable {
    case fast
    case accurate

    var displayName: String {
        switch self {
        case .fast:
            return NSLocalizedString("transcription.mode.fast", comment: "Fast transcription mode")
        case .accurate:
            return NSLocalizedString("transcription.mode.accurate", comment: "Accurate transcription mode")
        }
    }

    var modelName: String {
        switch self {
        case .fast:
            return "openai_whisper-base"
        case .accurate:
            return "openai_whisper-small"
        }
    }

    var description: String {
        switch self {
        case .fast:
            return NSLocalizedString("transcription.mode.fast.description", comment: "Fast mode description")
        case .accurate:
            return NSLocalizedString("transcription.mode.accurate.description", comment: "Accurate mode description")
        }
    }
}
