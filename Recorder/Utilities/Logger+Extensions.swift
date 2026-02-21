//
//  Logger+Extensions.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app.recorder"

    static let recording = Logger(subsystem: subsystem, category: "recording")
    static let transcription = Logger(subsystem: subsystem, category: "transcription")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let audio = Logger(subsystem: subsystem, category: "audio")
}
