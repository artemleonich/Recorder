//
//  AudioNote.swift
//  Recorder
//
//  Model representing an audio note with its metadata and transcription
//

import Foundation

struct AudioNote: Identifiable, Codable, Equatable {
    /// Unique identifier for the note
    let id: UUID
    
    /// User-editable title of the note
    var title: String
    
    /// Transcribed text from the audio
    var transcript: String
    
    /// Filename of the audio file (UUID-based)
    let audioFileName: String
    
    /// Duration of the audio in seconds
    let duration: TimeInterval
    
    /// Date and time when the note was created
    let createdAt: Date
    
    /// Language code for transcription (e.g., "ru", "en")
    let languageCode: String
    
    /// Flag indicating whether transcription has completed
    var isTranscriptionCompleted: Bool
    
    // MARK: - Initialization
    
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
