//
//  DateFormatter+Extensions.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation

extension DateFormatter {

    static var noteTitle: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.locale = Locale.current
        return formatter
    }

    static var noteDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM, HH:mm"
        formatter.locale = Locale.current
        return formatter
    }

    static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
