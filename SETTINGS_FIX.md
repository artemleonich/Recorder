# Исправление проблем с настройками и крашем

## Проблемы
1. Приложение крашилось при переключении между табами
2. Изменение языка приложения не применялось
3. Изменение темы (светлая/темная) не применялось

## Причины

### 1. Краш при переключении табов
В `MainTabView` использовались `@StateObject` для ViewModels, которые уже были созданы в `RecorderApp`. Это приводило к двойной инициализации и конфликтам с изоляцией акторов.

### 2. Настройки не применялись
`AppSettings` в `RecorderApp` был объявлен как `private let`, что не позволяло SwiftUI отслеживать изменения. Также ViewModels создавались с разными экземплярами `AppSettings`.

## Решения

### 1. Исправлен MainTabView
Заменил `@StateObject` на `@ObservedObject`:

```swift
// БЫЛО:
@StateObject private var recordingViewModel: RecordingViewModel

// СТАЛО:
@ObservedObject var recordingViewModel: RecordingViewModel
```

### 2. Добавлен синглтон для AppSettings
```swift
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private init() {
        // Settings are automatically loaded from UserDefaults via @AppStorage
    }
    // ...
}
```

### 3. Обновлен RecorderApp
```swift
@main
struct RecorderApp: App {
    @StateObject private var appSettings = AppSettings.shared
    
    @StateObject private var recordingViewModel: RecordingViewModel
    @StateObject private var notesListViewModel: NotesListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        // Все ViewModels используют AppSettings.shared
        _recordingViewModel = StateObject(wrappedValue: RecordingViewModel(
            // ...
            settings: AppSettings.shared
        ))
        // ...
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView(...)
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.colorScheme)
                .environment(\.locale, appSettings.localeIdentifier != nil ? Locale(identifier: appSettings.localeIdentifier!) : .current)
                .id(appSettings.appLanguage + appSettings.appAppearance)
        }
    }
}
```

## Результаты
- ✅ Приложение больше не крашится при переключении табов
- ✅ Изменение языка применяется мгновенно (через `.id()`)
- ✅ Изменение темы применяется мгновенно (через `.preferredColorScheme()`)
- ✅ Все ViewModels используют один экземпляр AppSettings
- ✅ Правильная изоляция акторов сохраняется
