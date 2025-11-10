//
//  TranscriptionSegment.swift
//  Recorder
//
//  Model representing a segment of transcribed text with timestamps
//

import Foundation

struct TranscriptionSegment: Codable, Equatable {
    /// The transcribed text for this segment
    let text: String
    
    /// Start time of the segment in seconds
    let start: TimeInterval
    
    /// End time of the segment in seconds
    let end: TimeInterval
    
    // MARK: - Computed Properties
    
    /// Duration of the segment in seconds
    var duration: TimeInterval {
        end - start
    }
    
    // MARK: - Initialization
    
    init(text: String, start: TimeInterval, end: TimeInterval) {
        self.text = text
        self.start = start
        self.end = end
    }
}
