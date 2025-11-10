# Manual Testing Guide - Offline Voice Recorder

## Overview
This document provides a comprehensive manual testing checklist for the "Речь в Текст: офлайн диктофон с транскрипцией" iOS application. Follow each test scenario carefully and document any issues found.

## Prerequisites
- iOS device or simulator running iOS 17.0+
- Xcode 15.0+
- Test audio files in various formats (m4a, mp3, wav, aac, caf)
- Clean app installation (delete and reinstall if needed)

---

## Test Scenario 1: Full Recording Cycle
**Requirement Coverage**: 1.1-1.7, 2.1-2.8

### Steps:
1. **Launch the app** for the first time
   - [ ] App launches successfully
   - [ ] Main tab view displays with 3 tabs: Запись, Заметки, Настройки

2. **Navigate to Recording tab**
   - [ ] Recording screen displays with gradient background
   - [ ] Timer shows 00:00
   - [ ] Red record button is visible
   - [ ] Status shows "Нажмите для записи"

3. **Start recording**
   - [ ] Tap the record button
   - [ ] Microphone permission dialog appears (first time only)
   - [ ] Grant microphone permission
   - [ ] Recording starts immediately
   - [ ] Timer begins counting (MM:SS format)
   - [ ] Waveform visualization appears and animates
   - [ ] Record button shows white square inside
   - [ ] Status changes to "Идёт запись..."
   - [ ] Button has pulsing animation

4. **During recording**
   - [ ] Timer updates every second
   - [ ] Waveform responds to audio input (speak into microphone)
   - [ ] No UI freezing or lag
   - [ ] Record for at least 10 seconds

5. **Stop recording**
   - [ ] Tap the record button again
   - [ ] Recording stops immediately
   - [ ] Transcription progress indicator appears
   - [ ] Progress updates from 0% to 100%
   - [ ] Audio file is saved

6. **Verify note creation**
   - [ ] Navigate to "Заметки" tab
   - [ ] New note appears at the top of the list
   - [ ] Note title is in format "DD.MM.YYYY HH:MM"
   - [ ] Duration is displayed correctly
   - [ ] Transcription status shows "В процессе..." initially
   - [ ] After completion, status changes to "Готово" with green checkmark

7. **View transcription**
   - [ ] Tap on the note
   - [ ] Note detail screen opens
   - [ ] Transcription text is displayed
   - [ ] Text matches the recorded audio content
   - [ ] Audio player is visible at the bottom

**Expected Result**: Complete recording cycle works without errors, transcription completes successfully.

---

## Test Scenario 2: Audio Import
**Requirement Coverage**: 5.1-5.6

### Prepare Test Files:
Create or download test audio files:
- test_audio.m4a (1-2 minutes)
- test_audio.mp3 (1-2 minutes)
- test_audio.wav (1-2 minutes)
- test_audio.aac (1-2 minutes)
- test_audio.caf (1-2 minutes)
- invalid_file.txt (for negative testing)

### Steps:

1. **Enable audio import** (if not already enabled)
   - [ ] Go to Settings → Транскрипция
   - [ ] Ensure "Импорт аудио" toggle is ON

2. **Import M4A file**
   - [ ] Go to Notes list
   - [ ] Tap import button (if visible in UI)
   - [ ] Select test_audio.m4a
   - [ ] File imports successfully
   - [ ] New note is created
   - [ ] Duration is calculated correctly
   - [ ] Transcription starts automatically

3. **Import MP3 file**
   - [ ] Repeat import process with test_audio.mp3
   - [ ] Verify successful import and transcription

4. **Import WAV file**
   - [ ] Repeat import process with test_audio.wav
   - [ ] Verify successful import and transcription

5. **Import AAC file**
   - [ ] Repeat import process with test_audio.aac
   - [ ] Verify successful import and transcription

6. **Import CAF file**
   - [ ] Repeat import process with test_audio.caf
   - [ ] Verify successful import and transcription

7. **Import invalid file**
   - [ ] Try to import invalid_file.txt
   - [ ] Error message appears: "Неподдерживаемый формат"
   - [ ] Import is cancelled
   - [ ] No note is created

**Expected Result**: All supported formats import successfully, unsupported formats show error.

---

## Test Scenario 3: Audio Playback
**Requirement Coverage**: 4.1-4.7

### Steps:

1. **Test short audio (< 30 seconds)**
   - [ ] Create or select a note with short audio
   - [ ] Open note detail
   - [ ] Tap Play button
   - [ ] Audio plays immediately
   - [ ] Progress slider moves smoothly
   - [ ] Current time updates every second
   - [ ] Total duration is displayed correctly
   - [ ] Audio plays to the end
   - [ ] Playback stops automatically at the end
   - [ ] Play button returns to play state

2. **Test medium audio (1-3 minutes)**
   - [ ] Select a note with medium-length audio
   - [ ] Open note detail
   - [ ] Tap Play button
   - [ ] Audio plays correctly
   - [ ] Pause during playback
   - [ ] Audio pauses immediately
   - [ ] Resume playback
   - [ ] Audio continues from paused position

3. **Test long audio (> 5 minutes)**
   - [ ] Select a note with long audio
   - [ ] Open note detail
   - [ ] Tap Play button
   - [ ] Audio plays without issues
   - [ ] No memory leaks or performance degradation

4. **Test seek functionality**
   - [ ] Start playing any audio
   - [ ] Drag progress slider to middle
   - [ ] Audio jumps to selected position
   - [ ] Playback continues from new position
   - [ ] Drag to beginning
   - [ ] Audio restarts from 00:00
   - [ ] Drag to near end
   - [ ] Audio plays remaining seconds

5. **Test skip buttons**
   - [ ] Start playing audio
   - [ ] Tap "-10 сек" button
   - [ ] Audio rewinds 10 seconds
   - [ ] If at beginning, stays at 00:00
   - [ ] Tap "+10 сек" button
   - [ ] Audio skips forward 10 seconds
   - [ ] If near end, stops at total duration

6. **Test background behavior**
   - [ ] Start playing audio
   - [ ] Navigate away from note detail
   - [ ] Audio continues playing (or stops, depending on design)
   - [ ] Return to note detail
   - [ ] Playback state is correct

**Expected Result**: Audio playback works smoothly for all durations, all controls function correctly.

---

## Test Scenario 4: Note Editing
**Requirement Coverage**: 3.3-3.5

### Steps:

1. **Edit note title**
   - [ ] Open any note detail
   - [ ] Tap on title field
   - [ ] Keyboard appears
   - [ ] Edit title to "Test Note Title"
   - [ ] Tap "Done" or dismiss keyboard
   - [ ] Title is saved
   - [ ] Navigate back to notes list
   - [ ] New title is displayed in list
   - [ ] Reopen note
   - [ ] Title persists correctly

2. **Edit transcription text**
   - [ ] Open any note detail
   - [ ] Tap on transcript text editor
   - [ ] Keyboard appears
   - [ ] Edit transcript text
   - [ ] Add new lines and paragraphs
   - [ ] Tap "Сохранить" or navigate away
   - [ ] Changes are saved
   - [ ] Navigate back to notes list
   - [ ] Reopen note
   - [ ] Transcript changes persist

3. **Edit empty transcription**
   - [ ] Create a note without transcription (if possible)
   - [ ] Open note detail
   - [ ] Manually add transcription text
   - [ ] Save changes
   - [ ] Verify text is saved correctly

4. **Test long text editing**
   - [ ] Open note with long transcription
   - [ ] Scroll through text editor
   - [ ] Edit text at various positions
   - [ ] Verify no performance issues
   - [ ] Verify all changes are saved

**Expected Result**: All edits are saved correctly and persist after app restart.

---

## Test Scenario 5: Note Deletion
**Requirement Coverage**: 3.6-3.7

### Steps:

1. **Delete via swipe gesture**
   - [ ] Go to notes list
   - [ ] Count total notes
   - [ ] Swipe left on any note
   - [ ] Red delete button appears
   - [ ] Tap delete button
   - [ ] Confirmation dialog appears (if implemented)
   - [ ] Confirm deletion
   - [ ] Note disappears from list
   - [ ] Note count decreases by 1

2. **Verify file deletion**
   - [ ] Note the audio file name before deletion
   - [ ] Delete the note
   - [ ] Check app storage (Settings → О приложении)
   - [ ] Storage usage decreases
   - [ ] Audio file is removed from filesystem

3. **Delete multiple notes**
   - [ ] Delete 3-5 notes in succession
   - [ ] All notes are removed correctly
   - [ ] No crashes or errors
   - [ ] Storage usage updates correctly

4. **Delete last note**
   - [ ] Delete all notes until only one remains
   - [ ] Delete the last note
   - [ ] Empty state is displayed (if implemented)
   - [ ] No crashes

**Expected Result**: Notes and their audio files are deleted completely, storage is freed.

---

## Test Scenario 6: Search Functionality
**Requirement Coverage**: 3.2

### Prepare Test Data:
Create notes with distinct titles and transcriptions:
- "Meeting Notes" - transcript: "Discuss project timeline"
- "Shopping List" - transcript: "Buy milk and bread"
- "Idea for App" - transcript: "Create a todo list application"
- "Phone Call" - transcript: "Call John about the meeting"

### Steps:

1. **Search by title**
   - [ ] Go to notes list
   - [ ] Tap search field
   - [ ] Type "Meeting"
   - [ ] Only "Meeting Notes" appears
   - [ ] Clear search
   - [ ] All notes reappear

2. **Search by transcript content**
   - [ ] Type "project" in search
   - [ ] "Meeting Notes" appears (contains "project" in transcript)
   - [ ] Other notes are filtered out

3. **Search with partial match**
   - [ ] Type "app" in search
   - [ ] Both "Idea for App" and "application" matches appear
   - [ ] Partial matching works

4. **Search with no results**
   - [ ] Type "xyz123nonexistent"
   - [ ] No results are shown
   - [ ] Empty state or message appears
   - [ ] Clear search
   - [ ] All notes reappear

5. **Search case insensitivity**
   - [ ] Type "MEETING" (uppercase)
   - [ ] "Meeting Notes" still appears
   - [ ] Search is case-insensitive

6. **Search with special characters**
   - [ ] Type search with special characters
   - [ ] No crashes
   - [ ] Search handles special characters gracefully

**Expected Result**: Search filters notes correctly by both title and transcript content.

---

## Test Scenario 7: Text Export and Sharing
**Requirement Coverage**: 7.1-7.4

### Steps:

1. **Share via Messages**
   - [ ] Open any note detail
   - [ ] Tap "Поделиться текстом" button
   - [ ] UIActivityViewController appears
   - [ ] Select "Messages"
   - [ ] Text is formatted: "{title}\n{date}\n\n{transcript}"
   - [ ] Message composer opens with text
   - [ ] Cancel and return to app

2. **Share via Mail**
   - [ ] Tap "Поделиться текстом" button
   - [ ] Select "Mail"
   - [ ] Mail composer opens
   - [ ] Text is in email body
   - [ ] Cancel and return to app

3. **Copy to clipboard**
   - [ ] Tap "Поделиться текстом" button
   - [ ] Select "Copy"
   - [ ] Text is copied to clipboard
   - [ ] Open Notes app or any text field
   - [ ] Paste text
   - [ ] Verify text format is correct

4. **Share via other apps**
   - [ ] Try sharing to WhatsApp, Telegram, etc.
   - [ ] Verify text is passed correctly to each app

5. **Test auto-backup to clipboard** (if enabled)
   - [ ] Go to Settings
   - [ ] Enable "Автоматическое резервное копирование"
   - [ ] Create a new recording
   - [ ] Wait for transcription to complete
   - [ ] Open any text field
   - [ ] Paste
   - [ ] Verify transcription text was auto-copied

**Expected Result**: Text sharing works through all standard iOS sharing channels.

---

## Test Scenario 8: Settings and Configuration
**Requirement Coverage**: 6.1-6.8

### Steps:

1. **Test language settings**
   - [ ] Go to Settings → Язык
   - [ ] Change to "Русский"
   - [ ] UI updates to Russian
   - [ ] Change to "English"
   - [ ] UI updates to English
   - [ ] Change to "Авто"
   - [ ] UI follows system language

2. **Test appearance settings**
   - [ ] Go to Settings → Внешний вид → Тема
   - [ ] Select "Светлая"
   - [ ] App switches to light mode
   - [ ] Select "Тёмная"
   - [ ] App switches to dark mode
   - [ ] Select "Авто"
   - [ ] App follows system appearance
   - [ ] Change system appearance
   - [ ] App updates accordingly

3. **Test transcription mode**
   - [ ] Go to Settings → Транскрипция → Режим
   - [ ] Select "Быстрый"
   - [ ] Create a new recording
   - [ ] Note transcription time
   - [ ] Go back to Settings
   - [ ] Select "Точный"
   - [ ] Create another recording
   - [ ] Verify transcription is more accurate (may take longer)

4. **Test audio import toggle**
   - [ ] Go to Settings → Транскрипция
   - [ ] Disable "Импорт аудио"
   - [ ] Import button is hidden/disabled
   - [ ] Enable "Импорт аудио"
   - [ ] Import button is visible/enabled

5. **Test archive audio setting**
   - [ ] Go to Settings → Транскрипция
   - [ ] Disable "Архивировать аудио"
   - [ ] Create a new recording
   - [ ] After transcription completes
   - [ ] Verify audio file is deleted (only transcript remains)
   - [ ] Enable "Архивировать аудио"
   - [ ] Create another recording
   - [ ] Verify audio file is kept

6. **Test auto-delete old notes**
   - [ ] Go to Settings → Транскрипция
   - [ ] Enable "Автоудаление старых заметок"
   - [ ] Set days to 1
   - [ ] Create a test note
   - [ ] Manually change note's creation date to 2 days ago (requires debugging)
   - [ ] Restart app
   - [ ] Verify old note is deleted

7. **Test storage information**
   - [ ] Go to Settings → О приложении
   - [ ] Verify "Занимаемое место" is displayed
   - [ ] Note the storage value
   - [ ] Create several recordings
   - [ ] Return to Settings
   - [ ] Verify storage value increased
   - [ ] Delete recordings
   - [ ] Verify storage value decreased

**Expected Result**: All settings work correctly and affect app behavior as expected.

---

## Test Scenario 9: Error Handling
**Requirement Coverage**: 9.1-9.6

### Steps:

1. **Test microphone permission denial**
   - [ ] Uninstall and reinstall app
   - [ ] Launch app
   - [ ] Go to Recording tab
   - [ ] Tap record button
   - [ ] Permission dialog appears
   - [ ] Tap "Don't Allow"
   - [ ] Error message appears: "Доступ к микрофону запрещён"
   - [ ] Message includes instructions to enable in Settings
   - [ ] Tap OK
   - [ ] Go to iOS Settings → Privacy → Microphone
   - [ ] Enable permission for app
   - [ ] Return to app
   - [ ] Try recording again
   - [ ] Recording works

2. **Test insufficient storage**
   - [ ] Fill device storage to < 50 MB free
   - [ ] Try to start recording
   - [ ] Warning appears: "Недостаточно места"
   - [ ] Recording is blocked
   - [ ] Free up space
   - [ ] Try recording again
   - [ ] Recording works

3. **Test recording failure**
   - [ ] Start recording
   - [ ] During recording, simulate audio session interruption (e.g., phone call)
   - [ ] Error message appears: "Ошибка записи аудио"
   - [ ] Option to retry is available

4. **Test transcription failure**
   - [ ] Create a recording with very poor audio quality
   - [ ] If transcription fails
   - [ ] Error message appears: "Ошибка транскрипции"
   - [ ] Option to retry transcription is available
   - [ ] Tap retry
   - [ ] Transcription attempts again

5. **Test missing audio file**
   - [ ] Create a note
   - [ ] Manually delete audio file from filesystem (requires debugging/file access)
   - [ ] Try to play audio
   - [ ] Error message appears: "Аудиофайл не найден"
   - [ ] Option to delete note is offered

6. **Test model not found**
   - [ ] Remove Whisper model files (requires debugging)
   - [ ] Try to transcribe
   - [ ] Error message appears: "Модель распознавания речи недоступна"
   - [ ] Instructions for downloading model are shown

**Expected Result**: All error scenarios are handled gracefully with clear user messages.

---

## Test Scenario 10: Background and Multitasking
**Requirement Coverage**: Performance and stability

### Steps:

1. **Test recording in background**
   - [ ] Start recording
   - [ ] Press home button (app goes to background)
   - [ ] Wait 10 seconds
   - [ ] Return to app
   - [ ] Verify recording continued or stopped appropriately
   - [ ] Check recorded duration

2. **Test transcription in background**
   - [ ] Start a recording
   - [ ] Stop recording (transcription starts)
   - [ ] Immediately press home button
   - [ ] Wait for transcription to complete (check notifications if any)
   - [ ] Return to app
   - [ ] Verify transcription completed successfully

3. **Test playback interruption**
   - [ ] Start playing audio
   - [ ] Receive a phone call or FaceTime call
   - [ ] Answer call
   - [ ] End call
   - [ ] Return to app
   - [ ] Verify playback state (paused or stopped)

4. **Test app switching**
   - [ ] Start recording
   - [ ] Switch to another app
   - [ ] Return to recorder app
   - [ ] Verify recording state
   - [ ] Stop recording
   - [ ] Verify file is saved correctly

5. **Test memory warnings**
   - [ ] Open many notes in succession
   - [ ] Navigate between screens rapidly
   - [ ] Monitor for memory warnings or crashes
   - [ ] App should handle memory pressure gracefully

6. **Test app termination and restart**
   - [ ] Create several notes
   - [ ] Force quit app
   - [ ] Relaunch app
   - [ ] Verify all notes are still present
   - [ ] Verify all data persists correctly

**Expected Result**: App handles background operations and multitasking correctly without data loss.

---

## Additional Test Cases

### Accessibility Testing
- [ ] Enable VoiceOver and navigate through all screens
- [ ] Increase text size to maximum and verify layout
- [ ] Enable Reduce Motion and verify animations are disabled
- [ ] Test with high contrast mode
- [ ] Verify all buttons meet 44x44pt minimum size

### Device Compatibility
- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPhone 15 Pro Max (large screen)
- [ ] Test on iPad (if supported)
- [ ] Test in portrait orientation
- [ ] Test in landscape orientation (if supported)

### Performance Testing
- [ ] Create 100+ notes and verify list scrolling is smooth
- [ ] Measure app launch time (should be < 1 second)
- [ ] Measure recording start time (should be < 0.5 seconds)
- [ ] Measure transcription time for 1-minute audio
- [ ] Monitor CPU and memory usage during transcription

### Stress Testing
- [ ] Create a 30-minute recording
- [ ] Import a very large audio file
- [ ] Create 500+ notes
- [ ] Search with very long query strings
- [ ] Rapidly tap buttons to test for race conditions

---

## Test Results Template

### Test Session Information
- **Date**: _______________
- **Tester**: _______________
- **Device**: _______________
- **iOS Version**: _______________
- **App Version**: _______________
- **Build Number**: _______________

### Summary
- **Total Test Cases**: _______________
- **Passed**: _______________
- **Failed**: _______________
- **Blocked**: _______________
- **Not Tested**: _______________

### Issues Found

| Issue # | Severity | Scenario | Description | Steps to Reproduce | Expected | Actual |
|---------|----------|----------|-------------|-------------------|----------|--------|
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |

**Severity Levels**:
- **Critical**: App crashes, data loss, core functionality broken
- **High**: Major feature not working, significant UX issue
- **Medium**: Minor feature issue, workaround available
- **Low**: Cosmetic issue, minor inconvenience

---

## Sign-off

### Tester Sign-off
- **Name**: _______________
- **Signature**: _______________
- **Date**: _______________

### Approval
- **Product Owner**: _______________
- **Date**: _______________

---

## Notes and Observations

Use this section to document any additional observations, suggestions, or concerns discovered during testing:

_______________________________________________________________________________
_______________________________________________________________________________
_______________________________________________________________________________
_______________________________________________________________________________
_______________________________________________________________________________

