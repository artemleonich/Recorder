//
//  AppSettings.swift
//  Recorder
//
//  Created by Kiro on 10.11.2025.
//

import SwiftUI
import Combine

/// Application settings stored in UserDefaults
@MainActor
final class AppSettings: ObservableObject {

    // MARK: - Nested Types

    private enum Keys {
        static let appLanguage = "appLanguage"
        static let appAppearance = "appAppearance"
        static let transcriptionMode = "transcriptionMode"
        static let allowAudioImport = "allowAudioImport"
        static let archiveAudio = "archiveAudio"
        static let autoBackup = "autoBackup"
        static let autoDeleteOldMessages = "autoDeleteOldMessages"
        static let autoDeleteDays = "autoDeleteDays"
        static let soundEffects = "soundEffects"
    }

    // MARK: - Singleton

    static let shared = AppSettings()

    // MARK: - Properties

    private let userDefaults: UserDefaults

    @Published var appLanguage: String {
        didSet { persist(appLanguage, forKey: Keys.appLanguage) }
    }

    @Published var appAppearance: String {
        didSet { persist(appAppearance, forKey: Keys.appAppearance) }
    }

    @Published var transcriptionMode: String {
        didSet { persist(transcriptionMode, forKey: Keys.transcriptionMode) }
    }

    @Published var allowAudioImport: Bool {
        didSet { persist(allowAudioImport, forKey: Keys.allowAudioImport) }
    }

    @Published var archiveAudio: Bool {
        didSet { persist(archiveAudio, forKey: Keys.archiveAudio) }
    }

    @Published var autoBackup: Bool {
        didSet { persist(autoBackup, forKey: Keys.autoBackup) }
    }

    @Published var autoDeleteOldMessages: Bool {
        didSet { persist(autoDeleteOldMessages, forKey: Keys.autoDeleteOldMessages) }
    }

    @Published var autoDeleteDays: Int {
        didSet { persist(autoDeleteDays, forKey: Keys.autoDeleteDays) }
    }

    @Published var soundEffects: Bool {
        didSet { persist(soundEffects, forKey: Keys.soundEffects) }
    }

    private var cancellable: AnyCancellable?

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

    /// Resolved locale for UI presentation
    var locale: Locale {
        if let identifier = localeIdentifier, !identifier.isEmpty {
            return Locale(identifier: identifier)
        }
        return .autoupdatingCurrent
    }

    // MARK: - Initialization

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Register default values
        userDefaults.register(defaults: [
            Keys.appLanguage: "auto",
            Keys.appAppearance: "system",
            Keys.transcriptionMode: "fast",
            Keys.allowAudioImport: true,
            Keys.archiveAudio: true,
            Keys.autoBackup: false,
            Keys.autoDeleteOldMessages: false,
            Keys.autoDeleteDays: 30,
            Keys.soundEffects: true
        ])

        appLanguage = userDefaults.string(forKey: Keys.appLanguage) ?? "auto"
        appAppearance = userDefaults.string(forKey: Keys.appAppearance) ?? "system"
        transcriptionMode = userDefaults.string(forKey: Keys.transcriptionMode) ?? "fast"
        allowAudioImport = userDefaults.bool(forKey: Keys.allowAudioImport)
        archiveAudio = userDefaults.bool(forKey: Keys.archiveAudio)
        autoBackup = userDefaults.bool(forKey: Keys.autoBackup)
        autoDeleteOldMessages = userDefaults.bool(forKey: Keys.autoDeleteOldMessages)
        autoDeleteDays = userDefaults.integer(forKey: Keys.autoDeleteDays)
        soundEffects = userDefaults.bool(forKey: Keys.soundEffects)

        // Listen for external UserDefaults changes (e.g., from extensions)
        cancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.syncFromUserDefaults()
            }
    }

    deinit {
        cancellable?.cancel()
    }

    // MARK: - Private Helpers

    private func persist<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    private func syncFromUserDefaults() {
        let updatedLanguage = userDefaults.string(forKey: Keys.appLanguage) ?? "auto"
        let updatedAppearance = userDefaults.string(forKey: Keys.appAppearance) ?? "system"
        let updatedTranscriptionMode = userDefaults.string(forKey: Keys.transcriptionMode) ?? "fast"
        let updatedAllowImport = userDefaults.bool(forKey: Keys.allowAudioImport)
        let updatedArchiveAudio = userDefaults.bool(forKey: Keys.archiveAudio)
        let updatedAutoBackup = userDefaults.bool(forKey: Keys.autoBackup)
        let updatedAutoDelete = userDefaults.bool(forKey: Keys.autoDeleteOldMessages)
        let updatedAutoDeleteDays = userDefaults.integer(forKey: Keys.autoDeleteDays)
        let updatedSoundEffects = userDefaults.bool(forKey: Keys.soundEffects)

        if appLanguage != updatedLanguage { appLanguage = updatedLanguage }
        if appAppearance != updatedAppearance { appAppearance = updatedAppearance }
        if transcriptionMode != updatedTranscriptionMode { transcriptionMode = updatedTranscriptionMode }
        if allowAudioImport != updatedAllowImport { allowAudioImport = updatedAllowImport }
        if archiveAudio != updatedArchiveAudio { archiveAudio = updatedArchiveAudio }
        if autoBackup != updatedAutoBackup { autoBackup = updatedAutoBackup }
        if autoDeleteOldMessages != updatedAutoDelete { autoDeleteOldMessages = updatedAutoDelete }
        if autoDeleteDays != updatedAutoDeleteDays { autoDeleteDays = updatedAutoDeleteDays }
        if soundEffects != updatedSoundEffects { soundEffects = updatedSoundEffects }
    }
}
