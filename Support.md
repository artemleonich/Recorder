# Dictofon Support / Поддержка Dictofon

Dictofon records voice notes and turns speech into editable text on iPhone and iPad. Its companion Apple Watch app transfers recordings to the paired iPhone.

## Contact / Связаться с разработчиком

Artem Leonov / Артём Леонов

App support / Поддержка: [hoodoos-runaway5l@icloud.com](mailto:hoodoos-runaway5l@icloud.com)

Privacy questions / Вопросы конфиденциальности: [artemleonov@yahoo.com](mailto:artemleonov@yahoo.com)

[Privacy Policy / Политика конфиденциальности](PrivacyPolicy.md)

You can also open Dictofon → Settings → Support. Include your device model, iOS version, Dictofon version, selected language and the steps that led to the problem. A screenshot of the error can help. Please exclude private content; recordings and transcripts are not required to ask for help. The developer cannot access your private notes or iCloud account.

В приложении также есть Настройки → Поддержка. Укажите модель устройства, версию iOS и Dictofon, выбранный язык и действия перед ошибкой. Можно приложить снимок сообщения об ошибке без личного содержимого. Для обращения не требуется отправлять записи и расшифровки. У разработчика нет доступа к вашим личным заметкам или iCloud.

## English: common questions

### A recording will not start

Allow microphone access for Dictofon in iOS Settings and check available device storage. If another app or a phone call is using audio, finish it and try again. Importing an existing audio file does not require recording a new one.

### Live transcription is unavailable

Live transcription uses Apple's on-device speech recognition and requires a supported device, language and installed speech assets. Complete any model download while connected to the internet. You can still record audio and transcribe it afterward with the models built into the app: GigaAM v3 for Russian and Parakeet v3 for 25 European languages, including English (choose the model for Russian in Settings → Recognition engine). Chinese, Japanese and Korean speech recognition are not offered in version 3.0.

### Translation or text actions are unavailable

Apple Translation requires a supported language pair and may ask you to download a language pack. Apple Intelligence text actions require compatible hardware, supported languages and an enabled, ready system model. Basic text cleanup remains available without Apple Intelligence. Recognition and generated text can contain errors; review text before sharing it.

### Insights are missing or show only key fragments

Summary, Tasks and Chapters are generated on the device by Apple Intelligence or, for languages it does not support yet, by the Qwen3.5 model built into the app. The built-in model needs a device with at least 8 GB of memory (iPhone 15 Pro, iPhone 16 and 17 families and newer); on other devices, and while the device is very warm, Insights are assembled from the recording's own sentences and titled "Key fragments". Very short recordings are not analyzed, and Insights appear only after the transcript is ready. Use "Refresh analysis" after editing the transcript. Check generated text before relying on it, especially names, numbers, dates and dosages.

### Speaker labels are wrong or missing

Speaker detection is on by default and runs on the device with models built into the app; it works best with clear audio and distinct voices. Tap a speaker name or long-press a passage to rename, reassign or merge speakers. Turn the feature off in Settings → Transcription.

### Chat with a recording

The Chat tab in a note answers questions about that recording ("What did we decide?", "Write a follow-up email", "Make it shorter") with the language model on your device — nothing is sent online. The model reads the whole transcript and the summary; if the recording does not contain the answer, it says so. The first answer after a while takes longer while the model loads into memory, and the status line shows what the model is doing. Tap a [mm:ss] time in an answer to hear that moment and check it. On devices without the built-in model, the chat shows the matching moments of the recording instead.

### App size and the optional Gemma model

Dictofon is about 3.4 GB because the speech and language models are built in; nothing has to be downloaded after installation. The optional Gemma 4 E4B model (about 4.6 GB) is offered in Settings → Local AI on devices with 12 GB of memory or more. It downloads over Wi‑Fi (or over cellular if you allow it), needs about 5.4 GB of free space and comes from Hugging Face as a file of model weights. You can remove it on the same screen; the built-in model then takes over.

### App Lock does not unlock

App Lock uses Face ID, Touch ID or your device passcode. If biometrics fail, enter the passcode. Turn App Lock off in Settings → Privacy. Control Center controls and the recording card on the Lock Screen show only recording controls and the elapsed time, never transcripts.

### Notifications

Dictofon notifies you when a transcript finishes while the app is in the background and when the system stops a recording (a call, another app using the microphone or low storage). These notifications arrive quietly in Notification Center; to get banners and sounds, or to turn them off, use iOS Settings → Notifications → Dictofon.

### Notes or audio have not synchronized

Check that both devices use the same Apple Account, iCloud Drive is available and iCloud access for Dictofon is enabled in Settings. Check network access and available iCloud storage. Open Dictofon on both devices and allow time for synchronization. A note and its audio can arrive at different times. Export important local recordings before troubleshooting; do not remove the app as the first step.

### Restore or remove a note

Open Trash to restore a note. Permanent deletion or emptying Trash removes notes from the app and requests deletion of their iCloud copies when synchronization is available. This also affects your synchronized devices. Files exported or shared elsewhere and device backups are managed separately. The developer cannot restore permanently deleted recordings.

### Apple Watch recordings

Keep the paired iPhone available and open Dictofon on it so transferred recordings can be received and transcribed. The Watch can record audio, but speech recognition runs on the paired iPhone. Bluetooth, connectivity and available storage may affect transfer time.

## Русский: частые вопросы

### Не начинается запись

Разрешите Dictofon доступ к микрофону в Настройках iOS и проверьте свободное место. Если звук занят звонком или другим приложением, завершите его и повторите попытку. Можно также импортировать готовый аудиофайл.

### Недоступна расшифровка во время записи

Эта функция использует локальное распознавание Apple и требует поддержки устройства, языка и установленных речевых моделей. Если система предлагает загрузку, завершите её при подключении к интернету. Аудио всё равно можно записать и расшифровать позднее встроенными моделями: GigaAM v3 для русской речи и Parakeet v3 для 25 европейских языков, включая английский (модель для русского выбирается в Настройках → Движок распознавания). Распознавание китайской, японской и корейской речи в версии 3.0 не предлагается.

### Недоступны перевод или действия с текстом

Переводу Apple нужна поддерживаемая языковая пара; может потребоваться загрузка языкового пакета. Действия Apple Intelligence требуют совместимого устройства, поддерживаемых языков и включённой, готовой системной модели. Простая очистка текста доступна без Apple Intelligence. Распознавание и сгенерированный текст могут содержать ошибки — проверьте результат перед отправкой.

### Нет итогов или показаны только ключевые фрагменты

«Кратко», «Задачи» и «Главы» создаются на устройстве Apple Intelligence или, для языков, которые он пока не поддерживает, встроенной моделью Qwen3.5. Встроенной модели нужно устройство с 8 ГБ памяти и больше (iPhone 15 Pro, iPhone 16 и 17 и новее); на других устройствах, а также при сильном нагреве итоги составляются из фраз самой записи и называются «Ключевые фрагменты». Очень короткие записи не анализируются, а итоги появляются только после расшифровки. После правки текста нажмите «Обновить анализ». Проверяйте сгенерированный текст, особенно имена, числа, даты и дозировки.

### Неверно определены говорящие

Определение говорящих включено по умолчанию и работает на устройстве встроенными моделями; лучше всего оно справляется с чистой записью и разными голосами. Нажмите на имя говорящего или удерживайте реплику, чтобы переименовать, переназначить или объединить говорящих. Отключить функцию можно в Настройках → Транскрипция.

### Чат с записью

Вкладка «Чат» в заметке отвечает на вопросы об этой записи («Что решили?», «Напиши письмо участникам», «Перескажи короче») с помощью языковой модели на устройстве — ничего не отправляется в интернет. Модель читает всю расшифровку и итоги; если в записи нет ответа, она так и скажет. Первый ответ после перерыва дольше — модель загружается в память, а строка статуса показывает, что она делает. Нажмите время [мм:сс] в ответе, чтобы прослушать это место и проверить. На устройствах без встроенной модели чат показывает подходящие места записи.

### Размер приложения и необязательная модель Gemma

Dictofon занимает около 3,4 ГБ, потому что речевые и языковые модели встроены; после установки ничего скачивать не нужно. Необязательная модель Gemma 4 E4B (около 4,6 ГБ) предлагается в Настройках → Локальный ИИ на устройствах с 12 ГБ памяти и больше. Она скачивается по Wi‑Fi (или по сотовой сети, если вы разрешите), требует около 5,4 ГБ свободного места и загружается с Hugging Face как файл весов модели. Удалить её можно на том же экране — тогда снова работает встроенная модель.

### Не снимается блокировка приложения

Блокировка использует Face ID, Touch ID или код-пароль устройства. Если биометрия не сработала, введите код-пароль. Отключить блокировку можно в Настройках → Конфиденциальность. Кнопки Пункта управления и карточка записи на экране блокировки показывают только управление записью и её длительность, но не расшифровки.

### Уведомления

Dictofon сообщает, когда расшифровка завершилась в фоне, и когда система остановила запись (звонок, другое приложение с микрофоном или закончилось место). Эти уведомления приходят тихо, в Центр уведомлений; включить баннеры и звук или отключить их можно в Настройках iOS → Уведомления → Dictofon.

### Не синхронизируются заметки или аудио

Проверьте одинаковый Аккаунт Apple на обоих устройствах, доступность iCloud Drive и разрешение iCloud для Dictofon. Убедитесь в наличии интернета и свободного места iCloud. Откройте приложение на обоих устройствах и дайте ему время. Заметка и аудиофайл могут появиться не одновременно. Перед устранением неполадок экспортируйте важные локальные записи; не начинайте с удаления приложения.

### Восстановить или удалить заметку

Заметку можно восстановить из Корзины. Окончательное удаление и очистка Корзины удаляют заметки из приложения и запрашивают удаление облачных копий, когда синхронизация доступна. Это затрагивает и ваши синхронизированные устройства. Экспортированные файлы, отправленные копии и резервные копии управляются отдельно. Разработчик не может восстановить окончательно удалённую запись.

### Записи Apple Watch

Держите сопряжённый iPhone доступным и откройте на нём Dictofon для получения и расшифровки записей. Часы записывают аудио, а распознавание выполняется на iPhone. Время передачи зависит от подключения, Bluetooth и свободного места.
