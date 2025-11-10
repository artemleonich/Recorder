//
//  AudioNoteEntity+Extensions.swift
//  Recorder
//
//  Extension for mapping Core Data entity to Swift model
//

import Foundation
import CoreData

extension AudioNoteEntity {
    /// Convert Core Data entity to Swift model
    /// - Returns: AudioNote struct with all properties mapped
    func toAudioNote() -> AudioNote {
        AudioNote(
            id: id ?? UUID(),
            title: title ?? "",
            transcript: transcript ?? "",
            audioFileName: audioFileName ?? "",
            duration: duration,
            createdAt: createdAt ?? Date(),
            languageCode: languageCode ?? "ru",
            isTranscriptionCompleted: isTranscriptionCompleted
        )
    }
}
