# UI Tests Documentation

This directory contains UI tests for the Recorder application. The UI tests use XCTest and XCUITest frameworks to test the user interface and user interactions.

## Test Files

### 1. RecordingUITests.swift
Tests for the recording screen functionality:
- Complete recording flow (start → record → stop → transcribe)
- Recording button state changes
- Timer functionality during recording
- Settings button navigation
- Transcription progress indicator
- Accessibility labels

**Key Test Cases:**
- `testRecordingFlow_StartAndStopRecording()` - Tests the complete recording workflow
- `testRecordingButton_ChangesStateCorrectly()` - Verifies button state transitions
- `testRecordingTimer_CountsUpDuringRecording()` - Validates timer accuracy
- `testSettingsButton_OpensSettings()` - Tests navigation to settings
- `testRecordingScreen_HasAccessibilityLabels()` - Verifies accessibility support

### 2. NotesListUITests.swift
Tests for the notes list screen:
- Notes list display
- Search functionality and filtering
- Swipe-to-delete gestures
- Empty state display
- FAB (Floating Action Button) functionality
- Note selection and navigation

**Key Test Cases:**
- `testNotesList_DisplaysNotes()` - Verifies notes list rendering
- `testNotesSearch_FiltersNotesByTitle()` - Tests search filtering
- `testNotesSearch_ShowsEmptyStateWhenNoResults()` - Validates empty search results
- `testNotesList_SwipeToDeleteShowsDeleteButton()` - Tests swipe gesture
- `testNotesList_DeleteButtonRemovesNote()` - Verifies note deletion
- `testNotesList_TappingNoteOpensDetail()` - Tests navigation to detail view

### 3. NoteDetailUITests.swift
Tests for the note detail screen:
- Note information display
- Title editing
- Transcript editing
- Audio playback controls (play/pause)
- Skip forward/backward buttons
- Share functionality
- Progress slider interaction
- Time display

**Key Test Cases:**
- `testNoteDetail_DisplaysNoteInformation()` - Verifies all note details are shown
- `testNoteDetail_EditTitle()` - Tests title editing functionality
- `testNoteDetail_EditTranscript()` - Tests transcript editing
- `testNoteDetail_PlayButtonTogglesPlayback()` - Validates audio playback
- `testNoteDetail_SkipBackwardButton()` - Tests skip backward control
- `testNoteDetail_SkipForwardButton()` - Tests skip forward control
- `testNoteDetail_ShareButtonOpensShareSheet()` - Verifies share functionality
- `testNoteDetail_SliderSeeksPlayback()` - Tests playback seeking

### 4. SettingsUITests.swift
Tests for the settings screen:
- Settings sections display
- Language selection
- Theme/appearance changes
- Transcription mode selection
- Toggle switches (import, archive, auto-delete, auto-backup, sound effects)
- Storage information display
- About section (version, privacy policy, rate app)
- Settings persistence after app restart

**Key Test Cases:**
- `testSettings_DisplaysAllSections()` - Verifies all settings sections
- `testSettings_ChangeLanguage()` - Tests language selection
- `testSettings_ChangeTheme()` - Tests theme switching
- `testSettings_ChangeTranscriptionMode()` - Tests transcription mode selection
- `testSettings_ToggleAudioImport()` - Tests audio import toggle
- `testSettings_ToggleAutoDelete()` - Tests auto-delete toggle with days picker
- `testSettings_SettingsPersistAfterRestart()` - Verifies settings persistence
- `testSettings_DisplaysStorageInformation()` - Tests storage info display

## Running the Tests

### In Xcode

1. Open the Recorder.xcodeproj in Xcode
2. Select the RecorderTests scheme
3. Press Cmd+U to run all tests, or
4. Press Cmd+6 to open the Test Navigator and run individual tests

### From Command Line

```bash
cd Recorder
xcodebuild test -scheme Recorder -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Test Setup

Each test file includes:
- `setUpWithError()` - Launches the app with UI-Testing launch arguments
- `tearDownWithError()` - Cleans up after tests
- Helper methods for common operations

### Launch Arguments

The tests use the following launch arguments:
- `UI-Testing` - Indicates the app is running in UI test mode
- `PrepareTestNotes` - Prepares test data for notes-related tests

## Test Data Preparation

For tests that require existing notes (NotesListUITests, NoteDetailUITests), the app should detect the `PrepareTestNotes` launch argument and create sample notes in the test environment.

## Accessibility Testing

All UI test files include accessibility verification:
- Accessibility labels are present
- Accessibility hints are appropriate
- Elements are properly exposed to VoiceOver
- Interactive elements meet minimum size requirements (44x44 pt)

## Localization

Tests support both Russian and English localization:
- Tests use predicates to match text in either language
- UI elements are identified by both localized text and accessibility identifiers

## Best Practices

1. **Use Predicates**: Tests use NSPredicate for flexible element matching
2. **Wait for Existence**: Tests use `waitForExistence(timeout:)` for asynchronous UI updates
3. **Sleep Judiciously**: Short sleep calls allow UI animations to complete
4. **Accessibility First**: Tests verify accessibility labels alongside functionality
5. **Cleanup**: Tests clean up state to avoid affecting subsequent tests

## Known Limitations

1. **XCTest Module**: The "No such module 'XCTest'" error in the IDE is expected and resolves during test execution
2. **Simulator Required**: UI tests require an iOS Simulator or physical device
3. **Test Data**: Some tests require specific test data to be present
4. **Timing**: Tests may need adjustment for slower devices or simulators

## Requirements Coverage

These UI tests cover the following requirements from the specification:

- **Requirement 1.3**: Recording button and status display
- **Requirement 1.5**: Recording completion and file saving
- **Requirement 2.3**: Transcription progress indicator
- **Requirement 3.2**: Notes search functionality
- **Requirement 3.3**: Note detail display
- **Requirement 3.4**: Title editing
- **Requirement 3.5**: Transcript editing
- **Requirement 3.6**: Swipe-to-delete
- **Requirement 3.7**: Note deletion
- **Requirement 4.2**: Play/pause controls
- **Requirement 4.5**: Skip forward
- **Requirement 4.6**: Skip backward
- **Requirement 6.1**: Language settings
- **Requirement 6.2**: Theme settings
- **Requirement 6.3**: Transcription mode settings
- **Requirement 6.4**: Toggle settings
- **Requirement 6.6**: Settings toggles
- **Requirement 7.1**: Share functionality

## Maintenance

When updating the UI:
1. Update corresponding test predicates if text changes
2. Add new tests for new features
3. Update accessibility identifiers if element identification changes
4. Run full test suite before committing changes

## Troubleshooting

### Tests Fail to Find Elements
- Verify accessibility identifiers are set correctly
- Check that localization keys match
- Ensure UI elements are not hidden or disabled

### Tests Time Out
- Increase timeout values for slow operations
- Check that animations complete before assertions
- Verify test data is properly prepared

### Tests Pass Locally but Fail in CI
- Ensure consistent simulator configuration
- Check for timing issues with slower CI machines
- Verify test data setup is deterministic

## Future Enhancements

Potential improvements for the UI test suite:
1. Add performance testing for UI responsiveness
2. Implement screenshot comparison tests
3. Add tests for landscape orientation
4. Test with different Dynamic Type sizes
5. Add tests for VoiceOver navigation
6. Implement visual regression testing
