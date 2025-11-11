import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(hex: "0d0d0d"),
                        Color(hex: "111827")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text(NSLocalizedString("settings.title", comment: "Settings title"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Language section
                        SettingsSection(title: NSLocalizedString("settings.section.language", comment: "Language section"), icon: "globe", iconColor: .blue) {
                            NavigationLink(destination: LanguageSelectionView(selectedLanguage: binding(\.appLanguage))) {
                                SettingsRow(
                                    title: NSLocalizedString("settings.language.app", comment: "App language"),
                                    value: languageDisplayName(viewModel.settings.appLanguage)
                                )
                            }
                        }
                        
                        // Appearance section
                        SettingsSection(title: NSLocalizedString("settings.section.appearance", comment: "Appearance section"), icon: "paintbrush.fill", iconColor: .purple) {
                            NavigationLink(destination: AppearanceSelectionView(selectedAppearance: binding(\.appAppearance))) {
                                SettingsRow(
                                    title: NSLocalizedString("settings.appearance.theme", comment: "Theme"),
                                    value: appearanceDisplayName(viewModel.settings.appAppearance)
                                )
                            }
                            
                            NavigationLink(destination: Text(NSLocalizedString("settings.appearance.textsize", comment: "Text size"))) {
                                SettingsRow(
                                    title: NSLocalizedString("settings.appearance.textsize", comment: "Text size"),
                                    value: NSLocalizedString("settings.appearance.textsize.system", comment: "System")
                                )
                            }
                        }
                        
                        // Transcription section
                        SettingsSection(title: NSLocalizedString("settings.section.transcription", comment: "Transcription section"), icon: "waveform", iconColor: .green) {
                            NavigationLink(destination: TranscriptionModeSelectionView(selectedMode: binding(\.transcriptionMode))) {
                                SettingsRow(
                                    title: NSLocalizedString("settings.transcription.mode", comment: "Transcription mode"),
                                    value: transcriptionModeDisplayName(viewModel.settings.transcriptionMode)
                                )
                            }
                            
                            Toggle(isOn: binding(\.allowAudioImport)) {
                                Text(NSLocalizedString("settings.transcription.import", comment: "Import audio"))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            Toggle(isOn: binding(\.archiveAudio)) {
                                Text(NSLocalizedString("settings.transcription.archive", comment: "Archive audio"))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: binding(\.autoDeleteOldMessages)) {
                                    Text(NSLocalizedString("settings.transcription.autodelete", comment: "Auto-delete"))
                                        .foregroundColor(.white)
                                }
                                .tint(Color.primary)
                                
                                if viewModel.settings.autoDeleteOldMessages {
                                    Picker(NSLocalizedString("settings.transcription.autodelete.days", comment: "Delete after"), selection: binding(\.autoDeleteDays)) {
                                        Text(NSLocalizedString("settings.transcription.autodelete.7days", comment: "7 days")).tag(7)
                                        Text(NSLocalizedString("settings.transcription.autodelete.14days", comment: "14 days")).tag(14)
                                        Text(NSLocalizedString("settings.transcription.autodelete.30days", comment: "30 days")).tag(30)
                                        Text(NSLocalizedString("settings.transcription.autodelete.60days", comment: "60 days")).tag(60)
                                        Text(NSLocalizedString("settings.transcription.autodelete.90days", comment: "90 days")).tag(90)
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.primary)
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
                            .tint(Color.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            Toggle(isOn: binding(\.soundEffects)) {
                                Text(NSLocalizedString("settings.transcription.soundeffects", comment: "Sound effects"))
                                    .foregroundColor(.white)
                            }
                            .tint(Color.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        // Storage info
                        SettingsSection(title: NSLocalizedString("settings.section.storage", comment: "Storage section"), icon: "internaldrive", iconColor: .orange) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(NSLocalizedString("settings.storage.used", comment: "Used"))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text(formatBytes(viewModel.storageUsed))
                                        .foregroundColor(.white)
                                }
                                
                                HStack {
                                    Text(NSLocalizedString("settings.storage.available", comment: "Available"))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text(formatBytes(viewModel.storageAvailable))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        // About section
                        SettingsSection(title: NSLocalizedString("settings.section.about", comment: "About section"), icon: "info.circle", iconColor: .gray) {
                            HStack {
                                Text(NSLocalizedString("settings.about.version", comment: "Version"))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            NavigationLink(destination: Text(NSLocalizedString("settings.about.privacy", comment: "Privacy policy"))) {
                                SettingsRow(title: NSLocalizedString("settings.about.privacy", comment: "Privacy policy"))
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
                                    Text(NSLocalizedString("settings.about.rate", comment: "Rate app"))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
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
    
    private func languageDisplayName(_ code: String) -> String {
        switch code {
        case "auto": return NSLocalizedString("settings.language.auto", comment: "Auto")
        case "ru": return NSLocalizedString("settings.language.russian", comment: "Russian")
        case "en": return NSLocalizedString("settings.language.english", comment: "English")
        default: return NSLocalizedString("settings.language.auto", comment: "Auto")
        }
    }
    
    private func appearanceDisplayName(_ appearance: String) -> String {
        switch appearance {
        case "system": return NSLocalizedString("settings.appearance.auto", comment: "Auto")
        case "light": return NSLocalizedString("settings.appearance.light", comment: "Light")
        case "dark": return NSLocalizedString("settings.appearance.dark", comment: "Dark")
        default: return NSLocalizedString("settings.appearance.auto", comment: "Auto")
        }
    }
    
    private func transcriptionModeDisplayName(_ mode: String) -> String {
        switch mode {
        case "fast": return NSLocalizedString("settings.transcription.mode.fast", comment: "Fast")
        case "accurate": return NSLocalizedString("settings.transcription.mode.accurate", comment: "Accurate")
        default: return NSLocalizedString("settings.transcription.mode.fast", comment: "Fast")
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
    let title: String
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
                    .foregroundColor(.white.opacity(0.7))
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
    let title: String
    var value: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// Language selection view
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    let languages = [
        ("auto", NSLocalizedString("settings.language.auto", comment: "Auto")),
        ("ru", NSLocalizedString("settings.language.russian", comment: "Russian")),
        ("en", NSLocalizedString("settings.language.english", comment: "English"))
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
        .navigationTitle(NSLocalizedString("settings.section.language", comment: "Language"))
    }
}

// Appearance selection view
struct AppearanceSelectionView: View {
    @Binding var selectedAppearance: String
    @Environment(\.dismiss) private var dismiss
    
    let appearances = [
        ("system", NSLocalizedString("settings.appearance.auto", comment: "Auto")),
        ("light", NSLocalizedString("settings.appearance.light", comment: "Light")),
        ("dark", NSLocalizedString("settings.appearance.dark", comment: "Dark"))
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
        .navigationTitle(NSLocalizedString("settings.appearance.theme", comment: "Theme"))
    }
}

// Transcription mode selection view
struct TranscriptionModeSelectionView: View {
    @Binding var selectedMode: String
    @Environment(\.dismiss) private var dismiss
    
    let modes = [
        ("fast", NSLocalizedString("settings.transcription.mode.fast", comment: "Fast"), NSLocalizedString("settings.transcription.mode.fast.description", comment: "Fast description")),
        ("accurate", NSLocalizedString("settings.transcription.mode.accurate", comment: "Accurate"), NSLocalizedString("settings.transcription.mode.accurate.description", comment: "Accurate description"))
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
                                .foregroundColor(.gray)
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
        .navigationTitle(NSLocalizedString("settings.transcription.mode", comment: "Transcription mode"))
    }
}
