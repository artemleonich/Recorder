//
//  AppSettings.swift
//  Recorder
//
//  Created by Kiro on 10.11.2025.
//

import SwiftUI
import Combine

/// Application settings stored in UserDefaults via @AppStorage
@MainActor
final class AppSettings: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppSettings()
    
    // MARK: - Language Settings
    
    /// Application language: "auto", "ru", or "en"
    @AppStorage("appLanguage") var appLanguage: String = "auto"
    
    // MARK: - Appearance Settings
    
    /// Application appearance: "system", "light", or "dark"
    @AppStorage("appAppearance") var appAppearance: String = "system"
    
    // MARK: - Transcription Settings
    
    /// Transcription mode: "fast" or "accurate"
    @AppStorage("transcriptionMode") var transcriptionMode: String = "fast"
    
    // MARK: - Import/Export Settings
    
    /// Allow importing audio files from external sources
    @AppStorage("allowAudioImport") var allowAudioImport: Bool = true
    
    /// Keep audio files after transcription (if false, delete audio after successful transcription)
    @AppStorage("archiveAudio") var archiveAudio: Bool = true
    
    /// Automatically copy transcription text to clipboard after completion
    @AppStorage("autoBackup") var autoBackup: Bool = false
    
    // MARK: - Auto-Delete Settings
    
    /// Automatically delete old notes
    @AppStorage("autoDeleteOldMessages") var autoDeleteOldMessages: Bool = false
    
    /// Number of days after which to delete old notes (when autoDeleteOldMessages is true)
    @AppStorage("autoDeleteDays") var autoDeleteDays: Int = 30
    
    // MARK: - Audio Settings
    
    /// Enable sound effects for UI interactions
    @AppStorage("soundEffects") var soundEffects: Bool = true
    
    // MARK: - Computed Properties
    
    /// Transcription mode as enum
    var transcriptionModeEnum: TranscriptionMode {
        get {
            TranscriptionMode(rawValue: transcriptionMode) ?? .fast
        }
        set {
            transcriptionMode = newValue.rawValue
        }
    }
    
    /// App appearance as ColorScheme
    var colorScheme: ColorScheme? {
        switch appAppearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // system default
        }
    }
    
    /// App language as locale identifier
    var localeIdentifier: String? {
        switch appLanguage {
        case "ru":
            return "ru"
        case "en":
            return "en"
        case "auto":
            return nil // use system locale
        default:
            return nil
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Settings are automatically loaded from UserDefaults via @AppStorage
    }
}
