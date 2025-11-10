//
//  TranscriptionResult.swift
//  Recorder
//
//  Model representing the complete result of a transcription operation
//

import Foundation

struct TranscriptionResult: Codable, Equatable {
    /// The complete transcribed text
    let text: String
    
    /// Array of transcription segments with timestamps
    let segments: [TranscriptionSegment]
    
    // MARK: - Computed Properties
    
    /// Total duration covered by all segments
    var totalDuration: TimeInterval {
        guard let lastSegment = segments.last else { return 0 }
        return lastSegment.end
    }
    
    /// Number of segments in the transcription
    var segmentCount: Int {
        segments.count
    }
    
    /// Check if the transcription is empty
    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    
    init(text: String, segments: [TranscriptionSegment] = []) {
        self.text = text
        self.segments = segments
    }
}
