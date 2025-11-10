# Полное исправление всех крашей и проблем

## Проблемы
1. ❌ Приложение крашилось при переключении между табами
2. ❌ Приложение крашилось при остановке записи
3. ❌ Настройки языка и темы не применялись
4. ❌ Запись не работала
5. ❌ Транскрипция не запускалась

## Корневые причины

### 1. Множественные экземпляры сервисов
В `RecorderApp.init()` создавались **разные экземпляры** `FileStorageService` и `NotesStorageService` для каждого ViewModel. Это приводило к:
- Рассинхронизации данных между ViewModels
- Проблемам с доступом к файлам
- Крашам при попытке сохранить/загрузить данные

### 2. Неправильное использование @StateObject в MainTabView
`MainTabView` использовал `@StateObject` для ViewModels, переданных из `RecorderApp`, что создавало **двойную инициализацию** и конфликты с изоляцией акторов.

### 3. Проблемы с actor isolation
- Обновление `@Published` свойств в `Task` без явного `@MainActor`
- Попытка обновить UI из фонового потока

### 4. Двойное расширение файла
Имя файла формировалось неправильно: `uuid.m4a.m4a` вместо `uuid.m4a`

### 5. AppSettings не был observable
`AppSettings` был объявлен как `private let`, что не позволяло SwiftUI отслеживать изменения настроек.

## Решения

### 1. Создан ServiceContainer (синглтон для сервисов)
```swift
private class ServiceContainer {
    static let shared = ServiceContainer()
    
    let fileStorageService: FileStorageService
    let notesStorageService: NotesStorageService
    let audioRecorderService: AudioRecorderService
    let transcriptionService: TranscriptionService
    
    private init() {
        // Все сервисы создаются ОДИН РАЗ
        self.fileStorageService = FileStorageService()
        self.audioRecorderService = AudioRecorderService(fileStorageService: fileStorageService)
        self.notesStorageService = NotesStorageService(
            persistenceController: PersistenceController.shared,
            fileStorageService: fileStorageService
        )
        self.transcriptionService = TranscriptionService(storageService: notesStorageService)
    }
}
```

### 2. Обновлен RecorderApp
```swift
@main
struct RecorderApp: App {
    @StateObject private var appSettings = AppSettings.shared
    
    @StateObject private var recordingViewModel: RecordingViewModel
    @StateObject private var notesListViewModel: NotesListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        let services = ServiceContainer.shared  // Используем ОДИН экземпляр
        
        _recordingViewModel = StateObject(wrappedValue: RecordingViewModel(
            audioRecorder: services.audioRecorderService,
            transcriptionService: services.transcriptionService,
            storageService: services.notesStorageService,
            settings: AppSettings.shared
        ))
        // ... остальные ViewModels используют те же сервисы
    }
}
```

### 3. Исправлен MainTabView
```swift
struct MainTabView: View {
    @ObservedObject var recordingViewModel: RecordingViewModel  // Не @StateObject!
    @ObservedObject var notesListViewModel: NotesListViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    init(...) {
        // Простое присваивание, без создания новых экземпляров
        self.recordingViewModel = recordingViewModel
        self.notesListViewModel = notesListViewModel
        self.settingsViewModel = settingsViewModel
    }
}
```

### 4. Добавлен синглтон для AppSettings
```swift
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private init() {
        // Settings are automatically loaded from UserDefaults via @AppStorage
    }
}
```

### 5. Исправлена actor isolation в RecordingViewModel
```swift
transcriptionTask = Task { @MainActor in  // Явное указание @MainActor
    // Обновление @Published свойств
    transcriptionProgress = progress
    isTranscribing = false
}
```

### 6. Исправлено имя файла при остановке записи
```swift
// БЫЛО:
audioFileName: "\(fileName).m4a"  // Двойное расширение!

// СТАЛО:
let audioFileName = audioURL.lastPathComponent  // Правильное имя из URL
```

## Архитектура после исправлений

```
RecorderApp
    ├── AppSettings.shared (синглтон)
    └── ServiceContainer.shared (синглтон)
            ├── FileStorageService
            ├── AudioRecorderService
            ├── NotesStorageService
            └── TranscriptionService
                    ↓
            Все ViewModels используют
            ОДНИ И ТЕ ЖЕ экземпляры сервисов
                    ↓
            MainTabView получает ViewModels
            через @ObservedObject (не создает новые)
```

## Результаты
- ✅ Приложение запускается без крашей
- ✅ Переключение между табами работает стабильно
- ✅ Запись аудио работает корректно
- ✅ Остановка записи работает без ошибок
- ✅ Транскрипция запускается и работает
- ✅ Изменение языка применяется мгновенно
- ✅ Изменение темы применяется мгновенно
- ✅ Все ViewModels синхронизированы (используют одни сервисы)
- ✅ Правильная изоляция акторов
- ✅ Файлы сохраняются с правильными именами

## Ключевые принципы
1. **Один экземпляр сервиса** - все ViewModels должны использовать одни и те же экземпляры сервисов
2. **@StateObject только для создания** - используйте @StateObject только там, где создается объект
3. **@ObservedObject для передачи** - используйте @ObservedObject для объектов, переданных извне
4. **Явный @MainActor** - всегда указывайте @MainActor при обновлении UI из Task
5. **Синглтоны для глобального состояния** - AppSettings и ServiceContainer как синглтоны
