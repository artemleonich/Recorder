//
//  AudioNote.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation

struct AudioNote: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var transcript: String
    let audioFileName: String
    let duration: TimeInterval
    let createdAt: Date
    let languageCode: String
    var isTranscriptionCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        transcript: String = "",
        audioFileName: String,
        duration: TimeInterval,
        createdAt: Date = Date(),
        languageCode: String = "ru",
        isTranscriptionCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.duration = duration
        self.createdAt = createdAt
        self.languageCode = languageCode
        self.isTranscriptionCompleted = isTranscriptionCompleted
    }
}
