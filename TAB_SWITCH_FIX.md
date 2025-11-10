# Исправление краша при переключении табов

## Проблема
Приложение крашилось при переключении с таба "Запись" на таб "Заметки".

## Причина
В `MainTabView` использовались `@StateObject` для ViewModels, которые уже были созданы в `RecorderApp`. Это приводило к двойной инициализации ViewModels и конфликтам с изоляцией акторов.

```swift
// БЫЛО (неправильно):
@StateObject private var recordingViewModel: RecordingViewModel
@StateObject private var notesListViewModel: NotesListViewModel
@StateObject private var settingsViewModel: SettingsViewModel

init(...) {
    _recordingViewModel = StateObject(wrappedValue: recordingViewModel)
    _notesListViewModel = StateObject(wrappedValue: notesListViewModel)
    _settingsViewModel = StateObject(wrappedValue: settingsViewModel)
}
```

## Решение
Заменил `@StateObject` на `@ObservedObject`, чтобы использовать уже созданные экземпляры ViewModels из `RecorderApp`:

```swift
// СТАЛО (правильно):
@ObservedObject var recordingViewModel: RecordingViewModel
@ObservedObject var notesListViewModel: NotesListViewModel
@ObservedObject var settingsViewModel: SettingsViewModel

init(...) {
    self.recordingViewModel = recordingViewModel
    self.notesListViewModel = notesListViewModel
    self.settingsViewModel = settingsViewModel
}
```

## Результат
- Приложение больше не крашится при переключении табов
- ViewModels создаются только один раз в `RecorderApp`
- Правильная изоляция акторов сохраняется
