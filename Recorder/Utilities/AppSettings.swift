//
//  AppSettings.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import SwiftUI
import Combine

@MainActor
final class AppSettings: ObservableObject {

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

    static let shared = AppSettings()

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

    var transcriptionModeEnum: TranscriptionMode {
        get { TranscriptionMode(rawValue: transcriptionMode) ?? .fast }
        set { transcriptionMode = newValue.rawValue }
    }

    var colorScheme: ColorScheme? {
        switch appAppearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var localeIdentifier: String? {
        switch appLanguage {
        case "ru": return "ru"
        case "en": return "en"
        default: return nil
        }
    }

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

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

        cancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncFromUserDefaults()
            }
    }

    deinit {
        cancellable?.cancel()
    }

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
