//
//  TranscriptionEngine.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation

protocol TranscriptionEngine: Actor {
    func prepareModel(mode: TranscriptionMode, languageCode: String) async throws
    func transcribe(
        audioURL: URL,
        languageCode: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> TranscriptionResult
    func cancelTranscription() async
}
