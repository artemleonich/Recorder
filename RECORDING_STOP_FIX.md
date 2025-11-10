# Исправление ошибки при остановке записи

## Проблема
При остановке записи приложение выдавало ошибку (SIGABRT).

## Причины

### 1. Двойное расширение файла
В `RecordingViewModel.stopRecording()` добавлялось расширение `.m4a` к имени файла, хотя `AudioRecorderService.stopRecording()` уже возвращал URL с расширением. Это приводило к созданию файла с именем типа `uuid.m4a.m4a`.

### 2. Actor isolation нарушение
В методе `startTranscription()` обновлялись `@Published` свойства внутри `Task` без явного указания `@MainActor`, что могло вызывать краш при попытке обновить UI из фонового потока.

## Решения

### 1. Исправлено имя файла
```swift
// БЫЛО:
let note = try storageService.createNote(
    title: title,
    audioFileName: "\(fileName).m4a",  // Двойное расширение!
    duration: duration,
    languageCode: languageCode
)

// СТАЛО:
// Note: audioURL already includes .m4a extension
let audioFileName = audioURL.lastPathComponent
let note = try storageService.createNote(
    title: title,
    audioFileName: audioFileName,  // Правильное имя из URL
    duration: duration,
    languageCode: languageCode
)
```

### 2. Исправлена actor isolation
```swift
// БЫЛО:
transcriptionTask = Task {
    // Обновление @Published свойств без @MainActor
    transcriptionProgress = progress
    isTranscribing = false
}

// СТАЛО:
transcriptionTask = Task { @MainActor in
    // Явное указание @MainActor для обновления UI
    transcriptionProgress = progress
    isTranscribing = false
}
```

## Результаты
- ✅ Остановка записи работает без ошибок
- ✅ Файлы сохраняются с правильным именем (без двойного расширения)
- ✅ Обновления UI происходят на главном потоке
- ✅ Транскрипция запускается корректно после остановки записи
