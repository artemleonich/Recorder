//
//  TranscriptionSegment.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation

struct TranscriptionSegment: Codable, Equatable {
    let text: String
    let start: TimeInterval
    let end: TimeInterval

    var duration: TimeInterval {
        end - start
    }

    init(text: String, start: TimeInterval, end: TimeInterval) {
        self.text = text
        self.start = start
        self.end = end
    }
}
