import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: backgroundGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("settings.title")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top)

                        // Language section
                        SettingsSection(title: NSLocalizedString("settings.section.language", comment: "Language section"), icon: "globe", iconColor: .blue) {
                            NavigationLink(destination: LanguageSelectionView(selectedLanguage: binding(\.appLanguage))) {
                                SettingsRow(
                                    title: "settings.language.app",
                                    value: languageDisplayName(viewModel.settings.appLanguage)
                                )
                            }
                        }

                        // Appearance section
                        SettingsSection(title: NSLocalizedString("settings.section.appearance", comment: "Appearance section"), icon: "paintbrush.fill", iconColor: .purple) {
                            NavigationLink(destination: AppearanceSelectionView(selectedAppearance: binding(\.appAppearance))) {
                                SettingsRow(
                                    title: "settings.appearance.theme",
                                    value: appearanceDisplayName(viewModel.settings.appAppearance)
                                )
                            }

                            NavigationLink(destination: Text("settings.appearance.textsize")) {
                                SettingsRow(
                                    title: "settings.appearance.textsize",
                                    value: "settings.appearance.textsize.system"
                                )
                            }
                        }

                        // Transcription section
                        SettingsSection(title: NSLocalizedString("settings.section.transcription", comment: "Transcription section"), icon: "waveform", iconColor: .green) {
                            NavigationLink(destination: TranscriptionModeSelectionView(selectedMode: binding(\.transcriptionMode))) {
                                SettingsRow(
                                    title: "settings.transcription.mode",
                                    value: transcriptionModeDisplayName(viewModel.settings.transcriptionMode)
                                )
                            }
                            
                            Toggle(isOn: binding(\.allowAudioImport)) {
                                Text(NSLocalizedString("settings.transcription.import", comment: "Import audio"))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.accentColor)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            Toggle(isOn: binding(\.archiveAudio)) {
                                Text(NSLocalizedString("settings.transcription.archive", comment: "Archive audio"))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.accentColor)
                            .padding()
                            .background(sectionBackground)

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: binding(\.autoDeleteOldMessages)) {
                                    Text(NSLocalizedString("settings.transcription.autodelete", comment: "Auto-delete"))
                                        .foregroundColor(.white)
                                }
                                .tint(Color.accentColor)

                                if viewModel.settings.autoDeleteOldMessages {
                                    Picker(NSLocalizedString("settings.transcription.autodelete.days", comment: "Delete after"), selection: binding(\.autoDeleteDays)) {
                                        Text(NSLocalizedString("settings.transcription.autodelete.7days", comment: "7 days")).tag(7)
                                        Text(NSLocalizedString("settings.transcription.autodelete.14days", comment: "14 days")).tag(14)
                                        Text(NSLocalizedString("settings.transcription.autodelete.30days", comment: "30 days")).tag(30)
                                        Text(NSLocalizedString("settings.transcription.autodelete.60days", comment: "60 days")).tag(60)
                                        Text(NSLocalizedString("settings.transcription.autodelete.90days", comment: "90 days")).tag(90)
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            Toggle(isOn: binding(\.autoBackup)) {
                                Text(NSLocalizedString("settings.transcription.autobackup", comment: "Auto-backup"))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.accentColor)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            Toggle(isOn: binding(\.soundEffects)) {
                                Text(NSLocalizedString("settings.transcription.soundeffects", comment: "Sound effects"))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.accentColor)
                            .padding()
                            .background(sectionBackground)
                        }

                        // Storage info
                        SettingsSection(title: "settings.section.storage", icon: "internaldrive", iconColor: .orange) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("settings.storage.used")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatBytes(viewModel.storageUsed))
                                        .foregroundColor(.primary)
                                }

                                HStack {
                                    Text("settings.storage.available")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatBytes(viewModel.storageAvailable))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(sectionBackground)
                        }

                        // About section
                        SettingsSection(title: "settings.section.about", icon: "info.circle", iconColor: .gray) {
                            HStack {
                                Text("settings.about.version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(sectionBackground)

                            NavigationLink(destination: Text("settings.about.privacy")) {
                                SettingsRow(title: "settings.about.privacy")
                            }

                            Button(action: {
                                // Open App Store rating
                                #if canImport(UIKit)
                                if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
                                    UIApplication.shared.open(url)
                                }
                                #endif
                            }) {
                                HStack {
                                    Text("settings.about.rate")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(sectionBackground)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.calculateStorageUsage()
        }
    }
    
    private func languageDisplayName(_ code: String) -> LocalizedStringKey {
        switch code {
        case "auto": return "settings.language.auto"
        case "ru": return "settings.language.russian"
        case "en": return "settings.language.english"
        default: return "settings.language.auto"
        }
    }

    private func appearanceDisplayName(_ appearance: String) -> LocalizedStringKey {
        switch appearance {
        case "system": return "settings.appearance.auto"
        case "light": return "settings.appearance.light"
        case "dark": return "settings.appearance.dark"
        default: return "settings.appearance.auto"
        }
    }

    private func transcriptionModeDisplayName(_ mode: String) -> LocalizedStringKey {
        switch mode {
        case "fast": return "settings.transcription.mode.fast"
        case "accurate": return "settings.transcription.mode.accurate"
        default: return "settings.transcription.mode.fast"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel.settings[keyPath: keyPath] },
            set: { viewModel.settings[keyPath: keyPath] = $0 }
        )
    }
}

// Settings section component
struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.caption)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                content
            }
            .padding(.horizontal)
        }
    }
}

// Settings row component
struct SettingsRow: View {
    let title: LocalizedStringKey
    var value: LocalizedStringKey? = nil

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)

            Spacer()

            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// Language selection view
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss

    let languages = [
        ("auto", LocalizedStringKey("settings.language.auto")),
        ("ru", LocalizedStringKey("settings.language.russian")),
        ("en", LocalizedStringKey("settings.language.english"))
    ]

    var body: some View {
        List {
            ForEach(languages, id: \.0) { code, name in
                Button(action: {
                    selectedLanguage = code
                    // Force UI update by posting notification
                    NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
                    dismiss()
                }) {
                    HStack {
                        Text(name)
                        Spacer()
                        if selectedLanguage == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("settings.section.language")
    }
}

// Appearance selection view
struct AppearanceSelectionView: View {
    @Binding var selectedAppearance: String
    @Environment(\.dismiss) private var dismiss

    let appearances = [
        ("system", LocalizedStringKey("settings.appearance.auto")),
        ("light", LocalizedStringKey("settings.appearance.light")),
        ("dark", LocalizedStringKey("settings.appearance.dark"))
    ]

    var body: some View {
        List {
            ForEach(appearances, id: \.0) { code, name in
                Button(action: {
                    selectedAppearance = code
                    // Force UI update by posting notification
                    NotificationCenter.default.post(name: NSNotification.Name("AppearanceChanged"), object: nil)
                    dismiss()
                }) {
                    HStack {
                        Text(name)
                        Spacer()
                        if selectedAppearance == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("settings.appearance.theme")
    }
}

// Transcription mode selection view
struct TranscriptionModeSelectionView: View {
    @Binding var selectedMode: String
    @Environment(\.dismiss) private var dismiss
    
    let modes = [
        ("fast", LocalizedStringKey("settings.transcription.mode.fast"), LocalizedStringKey("settings.transcription.mode.fast.description")),
        ("accurate", LocalizedStringKey("settings.transcription.mode.accurate"), LocalizedStringKey("settings.transcription.mode.accurate.description"))
    ]

    var body: some View {
        List {
            ForEach(modes, id: \.0) { code, name, description in
                Button(action: {
                    selectedMode = code
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.body)
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedMode == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("settings.transcription.mode")
    }
}
