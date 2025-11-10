//
//  DateFormatter+Extensions.swift
//  Recorder
//
//  Extensions for DateFormatter to provide consistent date formatting across the app
//

import Foundation

extension DateFormatter {
    
    /// Formatter for note titles: "DD.MM.YYYY HH:MM"
    static var noteTitle: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.locale = Locale.current
        return formatter
    }
    
    /// Formatter for note display dates: "DD.MM, HH:MM"
    static var noteDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM, HH:mm"
        formatter.locale = Locale.current
        return formatter
    }
    
    /// Formats a duration in seconds to MM:SS format
    /// - Parameter duration: Duration in seconds
    /// - Returns: Formatted string in MM:SS format
    static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
