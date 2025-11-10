# 🔧 Исправление WhisperKit

## Проблема:
```
Missing package product 'WhisperKit'
```

Пакет WhisperKit не загружен или повреждён.

---

## Решение через Xcode (РЕКОМЕНДУЕТСЯ):

### Шаг 1: Откройте проект
```bash
open Recorder/Recorder.xcodeproj
```

### Шаг 2: Сбросьте пакеты
1. В Xcode: **File → Packages → Reset Package Caches**
2. Подождите завершения

### Шаг 3: Обновите пакеты
1. В Xcode: **File → Packages → Update to Latest Package Versions**
2. Подождите загрузки (может занять 1-2 минуты)

### Шаг 4: Очистите и соберите
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. **Product → Build** (Cmd+B)
3. **Product → Run** (Cmd+R)

---

## Альтернативное решение (если Xcode не помогает):

### Вариант 1: Удалите DerivedData вручную
1. Закройте Xcode
2. Откройте Finder
3. Нажмите **Cmd+Shift+G**
4. Вставьте: `~/Library/Developer/Xcode/DerivedData`
5. Найдите папки начинающиеся с `Recorder-`
6. Удалите их в корзину
7. Откройте проект снова

### Вариант 2: Через терминал с правами
```bash
# Закройте Xcode сначала!
sudo rm -rf ~/Library/Developer/Xcode/DerivedData/Recorder-*

# Откройте проект
open Recorder/Recorder.xcodeproj

# В Xcode: File → Packages → Resolve Package Versions
```

---

## Проверка:

После загрузки пакетов проверьте:

1. В Xcode слева в навигаторе должна появиться секция **Package Dependencies**
2. Там должен быть **WhisperKit** с версией 0.15.0
3. Раскройте WhisperKit - должны быть подпакеты:
   - swift-transformers
   - swift-jinja
   - swift-argument-parser
   - swift-collections

---

## Если всё ещё не работает:

### Проверьте интернет-соединение
WhisperKit загружается с GitHub, нужен интернет.

### Проверьте версию Xcode
```bash
xcodebuild -version
```

Должно быть: **Xcode 15.0** или новее

### Проверьте Package.resolved
```bash
cat Recorder/Recorder.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

Если файла нет - это нормально, он создастся после загрузки пакетов.

---

## После успешной загрузки:

1. **Cmd+Shift+K** (Clean)
2. **Cmd+B** (Build)
3. **Cmd+R** (Run)

---

## Важно! ⚠️

WhisperKit - это большой пакет (~500 MB).
Первая загрузка может занять **5-10 минут** в зависимости от скорости интернета.

Не прерывайте процесс загрузки!

---

## Готово! ✅

После загрузки WhisperKit приложение соберётся и запустится.

Транскрипция будет работать! 🎉
