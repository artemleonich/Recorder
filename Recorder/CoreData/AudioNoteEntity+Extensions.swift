//
//  AudioNoteEntity+Extensions.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation
import CoreData

extension AudioNoteEntity {
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
