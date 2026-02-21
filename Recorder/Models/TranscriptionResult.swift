//
//  TranscriptionResult.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation

struct TranscriptionResult: Codable, Equatable {
    let text: String
    let segments: [TranscriptionSegment]

    var totalDuration: TimeInterval {
        guard let lastSegment = segments.last else { return 0 }
        return lastSegment.end
    }

    var segmentCount: Int {
        segments.count
    }

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(text: String, segments: [TranscriptionSegment] = []) {
        self.text = text
        self.segments = segments
    }
}
