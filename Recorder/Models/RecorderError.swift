//
//  RecorderError.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import Foundation

enum RecorderError: LocalizedError {
    case microphonePermissionDenied
    case recordingFailed(Error)
    case transcriptionFailed(Error)
    case modelNotFound
    case insufficientStorage
    case audioFileNotFound
    case importFailed(Error)
    case fileOperationFailed(Error)
    case storageOperationFailed(Error)
    case invalidAudioFormat
    case generic(Error)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return NSLocalizedString(
                "error.microphone.denied.title",
                value: "Доступ к микрофону запрещён",
                comment: "Microphone permission denied error title"
            )
        case .recordingFailed:
            return NSLocalizedString(
                "error.recording.failed.title",
                value: "Ошибка записи аудио",
                comment: "Recording failed error title"
            )
        case .transcriptionFailed:
            return NSLocalizedString(
                "error.transcription.failed.title",
                value: "Ошибка транскрипции",
                comment: "Transcription failed error title"
            )
        case .modelNotFound:
            return NSLocalizedString(
                "error.model.notfound.title",
                value: "Модель распознавания речи недоступна",
                comment: "Model not found error title"
            )
        case .insufficientStorage:
            return NSLocalizedString(
                "error.storage.insufficient.title",
                value: "Недостаточно места на устройстве",
                comment: "Insufficient storage error title"
            )
        case .audioFileNotFound:
            return NSLocalizedString(
                "error.audiofile.notfound.title",
                value: "Аудиофайл не найден",
                comment: "Audio file not found error title"
            )
        case .importFailed:
            return NSLocalizedString(
                "error.import.failed.title",
                value: "Ошибка импорта аудиофайла",
                comment: "Import failed error title"
            )
        case .fileOperationFailed:
            return NSLocalizedString(
                "error.file.operation.failed.title",
                value: "Ошибка работы с файлом",
                comment: "File operation failed error title"
            )
        case .storageOperationFailed:
            return NSLocalizedString(
                "error.storage.operation.failed.title",
                value: "Ошибка сохранения данных",
                comment: "Storage operation failed error title"
            )
        case .invalidAudioFormat:
            return NSLocalizedString(
                "error.audio.format.invalid.title",
                value: "Неподдерживаемый формат аудио",
                comment: "Invalid audio format error title"
            )
        case .generic:
            return NSLocalizedString(
                "error.generic.title",
                value: "Произошла ошибка",
                comment: "Generic error title"
            )
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return NSLocalizedString(
                "error.microphone.denied.suggestion",
                value: "Пожалуйста, предоставьте доступ к микрофону в настройках iOS: Настройки → Конфиденциальность → Микрофон → Речь в Текст",
                comment: "Microphone permission denied recovery suggestion"
            )
        case .insufficientStorage:
            return NSLocalizedString(
                "error.storage.insufficient.suggestion",
                value: "Освободите место на устройстве, удалив ненужные файлы или приложения. Для записи требуется минимум 50 МБ свободного места.",
                comment: "Insufficient storage recovery suggestion"
            )
        case .modelNotFound:
            return NSLocalizedString(
                "error.model.notfound.suggestion",
                value: "Попробуйте переустановить приложение или проверьте подключение к интернету для загрузки модели при первом запуске.",
                comment: "Model not found recovery suggestion"
            )
        case .audioFileNotFound:
            return NSLocalizedString(
                "error.audiofile.notfound.suggestion",
                value: "Аудиофайл был удалён или перемещён. Вы можете удалить эту заметку.",
                comment: "Audio file not found recovery suggestion"
            )
        case .recordingFailed(let error):
            return String(
                format: NSLocalizedString(
                    "error.recording.failed.suggestion",
                    value: "Попробуйте записать снова. Детали: %@",
                    comment: "Recording failed recovery suggestion"
                ),
                error.localizedDescription
            )
        case .transcriptionFailed:
            return NSLocalizedString(
                "error.transcription.failed.suggestion",
                value: "Попробуйте повторить транскрипцию или выберите другой режим в настройках.",
                comment: "Transcription failed recovery suggestion"
            )
        case .importFailed(let error):
            return String(
                format: NSLocalizedString(
                    "error.import.failed.suggestion",
                    value: "Убедитесь, что файл имеет поддерживаемый формат (M4A, MP3, WAV, AAC, CAF). Детали: %@",
                    comment: "Import failed recovery suggestion"
                ),
                error.localizedDescription
            )
        case .fileOperationFailed(let error):
            return String(
                format: NSLocalizedString(
                    "error.file.operation.failed.suggestion",
                    value: "Попробуйте повторить операцию. Детали: %@",
                    comment: "File operation failed recovery suggestion"
                ),
                error.localizedDescription
            )
        case .storageOperationFailed(let error):
            return String(
                format: NSLocalizedString(
                    "error.storage.operation.failed.suggestion",
                    value: "Попробуйте перезапустить приложение. Детали: %@",
                    comment: "Storage operation failed recovery suggestion"
                ),
                error.localizedDescription
            )
        case .invalidAudioFormat:
            return NSLocalizedString(
                "error.audio.format.invalid.suggestion",
                value: "Поддерживаемые форматы: M4A, MP3, WAV, AAC, CAF",
                comment: "Invalid audio format recovery suggestion"
            )
        case .generic(let error):
            return String(
                format: NSLocalizedString(
                    "error.generic.suggestion",
                    value: "Попробуйте повторить операцию. Детали: %@",
                    comment: "Generic error recovery suggestion"
                ),
                error.localizedDescription
            )
        }
    }

    var failureReason: String? {
        switch self {
        case .recordingFailed(let error),
             .transcriptionFailed(let error),
             .importFailed(let error),
             .fileOperationFailed(let error),
             .storageOperationFailed(let error),
             .generic(let error):
            return error.localizedDescription
        default:
            return nil
        }
    }
}
