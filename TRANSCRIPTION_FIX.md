# Исправление отображения транскрипции

## Дата: 10.11.2025

## Проблема:
Транскрипция не отображалась в деталях заметки после завершения.

## Причины:

### 1. NotesListView не открывал NoteDetailView
**Проблема:** В `NotesListView.swift` была заглушка:
```swift
NavigationLink(destination: Text("Note Detail")) {
```

**Решение:** Заменено на реальный `NoteDetailView`:
```swift
NavigationLink(destination: viewModel.createNoteDetailView(for: note)) {
```

### 2. NoteDetailViewModel не подписывался на обновления заметки
**Проблема:** Когда транскрипция завершалась и обновлялась в базе данных, `NoteDetailViewModel` не получал обновление.

**Решение:** Добавлена подписка на `storageService.$notes` в методе `setupBindings()`:
```swift
// Subscribe to note updates from storage service
storageService.$notes
    .compactMap { [weak self] notes in
        guard let self = self else { return nil }
        return notes.first(where: { $0.id == self.note.id })
    }
    .sink { [weak self] updatedNote in
        guard let self = self else { return }
        if self.note.transcript != updatedNote.transcript ||
           self.note.title != updatedNote.title ||
           self.note.isTranscriptionCompleted != updatedNote.isTranscriptionCompleted {
            self.note = updatedNote
            self.logger.debug("Note updated from storage: \(updatedNote.id)")
        }
    }
    .store(in: &cancellables)
```

### 3. NoteDetailView не реагировал на изменения note.transcript
**Проблема:** `editedTranscript` инициализировался один раз в `init()` и не обновлялся при изменении `viewModel.note.transcript`.

**Решение:** Добавлены `.onChange` модификаторы:
```swift
.onChange(of: viewModel.note.transcript) { oldValue, newValue in
    // Update editedTranscript when transcript changes
    if editedTranscript == oldValue || editedTranscript.isEmpty {
        editedTranscript = newValue
    }
}
.onChange(of: viewModel.note.title) { oldValue, newValue in
    // Update editedTitle when title changes
    if editedTitle == oldValue {
        editedTitle = newValue
    }
}
```

### 4. Отсутствовал индикатор процесса транскрипции
**Проблема:** Пользователь не видел, что транскрипция в процессе.

**Решение:** Добавлен индикатор загрузки и статус:
```swift
// Transcription status indicator
if !viewModel.note.isTranscriptionCompleted {
    HStack(spacing: 4) {
        ProgressView()
            .scaleEffect(0.7)
            .tint(.yellow)
        Text(NSLocalizedString("note.status.processing", comment: "Processing status"))
            .font(.caption)
            .foregroundColor(.yellow)
    }
}
```

И placeholder пока транскрипция не завершена:
```swift
if viewModel.note.isTranscriptionCompleted || !editedTranscript.isEmpty {
    TextEditor(text: $editedTranscript)
    // ... editor
} else {
    // Placeholder while transcription is in progress
    VStack(spacing: 12) {
        ProgressView()
            .tint(.white)
        Text(NSLocalizedString("note.transcription.inprogress", comment: "Transcription in progress"))
            .font(.body)
            .foregroundColor(.white.opacity(0.6))
    }
    // ... placeholder styling
}
```

---

## Измененные файлы:

### 1. `Recorder/Recorder/Views/NotesListView.swift`
- Заменена заглушка `Text("Note Detail")` на `viewModel.createNoteDetailView(for: note)`

### 2. `Recorder/Recorder/ViewModels/NotesListViewModel.swift`
- Добавлен метод `createNoteDetailView(for:)` для создания `NoteDetailView` с правильным ViewModel

### 3. `Recorder/Recorder/ViewModels/NoteDetailViewModel.swift`
- Добавлена подписка на обновления заметки из `storageService.$notes` в `setupBindings()`
- Теперь ViewModel автоматически обновляется при изменении заметки в базе данных

### 4. `Recorder/Recorder/Views/NoteDetailView.swift`
- Добавлены `.onChange` модификаторы для отслеживания изменений `note.transcript` и `note.title`
- Добавлен индикатор статуса транскрипции в заголовке поля
- Добавлен placeholder с ProgressView пока транскрипция не завершена

### 5. `Recorder/Recorder/Resources/Localizable.xcstrings`
- Добавлена строка `note.transcription.inprogress` (RU: "Транскрипция в процессе...", EN: "Transcription in progress...")

---

## Как это работает теперь:

### Поток данных:

1. **Запись завершена** → `RecordingViewModel.stopRecording()`
2. **Создаётся заметка** → `storageService.createNote()`
3. **Запускается транскрипция** → `transcriptionService.transcribe()`
4. **Транскрипция обновляется** → `storageService.updateNoteTranscript()`
5. **NotesStorageService публикует изменение** → `@Published var notes`
6. **NoteDetailViewModel получает обновление** → через подписку на `storageService.$notes`
7. **NoteDetailViewModel обновляет note** → `self.note = updatedNote`
8. **NoteDetailView реагирует** → через `.onChange(of: viewModel.note.transcript)`
9. **UI обновляется** → `editedTranscript = newValue`

### Визуальные индикаторы:

**Пока транскрипция не завершена:**
- В списке заметок: жёлтый значок "⏳ Processing"
- В деталях заметки: 
  - Жёлтый индикатор "⏳ Processing" в заголовке
  - Placeholder с ProgressView вместо TextEditor
  - Текст "Транскрипция в процессе..."

**После завершения транскрипции:**
- В списке заметок: зелёный значок "✓ Completed"
- В деталях заметки:
  - Индикатор исчезает
  - Появляется TextEditor с транскрибированным текстом
  - Текст можно редактировать

---

## Тестирование:

### Сценарий 1: Новая запись
1. Откройте вкладку "Запись"
2. Нажмите красный круг, говорите 5-10 секунд
3. Нажмите красный квадрат
4. Дождитесь завершения транскрипции (прогресс-бар)
5. Перейдите на вкладку "Заметки"
6. **Проверьте:** Заметка показывает "✓ Completed"
7. Откройте заметку
8. **Проверьте:** Транскрипция отображается в TextEditor

### Сценарий 2: Открытие заметки во время транскрипции
1. Создайте запись (как в Сценарии 1)
2. **Сразу** после остановки записи перейдите в "Заметки"
3. Откройте только что созданную заметку
4. **Проверьте:** Показывается "⏳ Processing" и placeholder
5. Подождите несколько секунд
6. **Проверьте:** Placeholder исчезает, появляется транскрипция

### Сценарий 3: Редактирование транскрипции
1. Откройте заметку с завершённой транскрипцией
2. Измените текст в TextEditor
3. Вернитесь назад (свайп или кнопка "Назад")
4. Откройте заметку снова
5. **Проверьте:** Изменения сохранились

---

## Проверка в Xcode:

### Логи для отладки:

При открытии заметки должны появиться логи:
```
[noteDetail] Loading audio for note: <UUID>
[noteDetail] Audio loaded successfully
```

При обновлении транскрипции:
```
[transcription] Transcription completed for note: <UUID>
[notesStorage] Updated note transcript: <UUID>
[noteDetail] Note updated from storage: <UUID>
```

### Точки останова:

Установите breakpoint в:
1. `NoteDetailViewModel.setupBindings()` - проверить подписку
2. `NoteDetailView.onChange(of: viewModel.note.transcript)` - проверить реакцию на изменения
3. `NotesStorageService.updateNoteTranscript()` - проверить обновление в базе

---

## Известные ограничения:

1. **Задержка обновления:** Может быть небольшая задержка (< 1 сек) между завершением транскрипции и отображением текста из-за асинхронности Combine.

2. **Конфликт редактирования:** Если пользователь редактирует транскрипцию в момент её завершения, изменения пользователя будут перезаписаны. Это решается проверкой `if editedTranscript == oldValue || editedTranscript.isEmpty`.

3. **Память:** Подписка на все заметки может быть неэффективна при большом количестве заметок (> 1000). В будущем можно оптимизировать, подписываясь только на конкретную заметку.

---

## Следующие шаги:

1. ✅ Исправлено отображение транскрипции
2. ✅ Добавлены индикаторы процесса
3. ✅ Добавлена автоматическая синхронизация
4. ⏳ Тестирование на реальном устройстве
5. ⏳ Проверка производительности при большом количестве заметок

---

## Контакты:

Если транскрипция всё ещё не отображается:
1. Проверьте логи в Xcode (Cmd+Shift+Y)
2. Убедитесь, что транскрипция завершается успешно
3. Проверьте, что `isTranscriptionCompleted` становится `true`
4. Пришлите логи для анализа
