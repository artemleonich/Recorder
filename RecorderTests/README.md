# RecorderTests

Unit tests for the Recorder iOS application services.

## Overview

This test suite provides comprehensive unit and integration tests for the Recorder app:

### Unit Tests

- **AudioRecorderServiceTests**: Tests for audio recording functionality
- **AudioPlayerServiceTests**: Tests for audio playback functionality
- **NotesStorageServiceTests**: Tests for Core Data storage operations
- **FileStorageServiceTests**: Tests for file system operations
- **TranscriptionServiceTests**: Tests for transcription coordination (with mock engine)

### Integration Tests

- **RecordingIntegrationTests**: Tests for complete recording and transcription flow
- **ImportIntegrationTests**: Tests for audio file import functionality
- **PlaybackIntegrationTests**: Tests for audio playback and note editing

## Setup

### Adding Tests to Xcode Project

Since this is an iOS project, you'll need to add the test target to your Xcode project:

1. Open `Recorder.xcodeproj` in Xcode
2. Go to **File → New → Target**
3. Select **iOS → Unit Testing Bundle**
4. Name it `RecorderTests`
5. Set the target to be tested as `Recorder`
6. Click **Finish**

### Adding Test Files

After creating the test target:

1. In Xcode's Project Navigator, right-click on the `RecorderTests` folder
2. Select **Add Files to "Recorder"...**
3. Navigate to the `RecorderTests` directory in Finder
4. Select all `.swift` test files
5. Make sure **Copy items if needed** is unchecked (files are already in place)
6. Make sure the `RecorderTests` target is checked
7. Click **Add**

Alternatively, you can drag and drop the test files from Finder into the `RecorderTests` group in Xcode.

## Running Tests

### From Xcode

1. Select the `RecorderTests` scheme
2. Press `Cmd + U` to run all tests
3. Or use **Product → Test** from the menu

### From Command Line

```bash
cd Recorder
xcodebuild test -scheme Recorder -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Test Requirements

### Permissions

Some tests require microphone permission:
- **AudioRecorderServiceTests**: Requires microphone access for recording tests
- Tests will be skipped if permission is not granted

### Test Data

Tests create temporary files and in-memory Core Data stores:
- All test data is cleaned up in `tearDown()` methods
- No persistent data is created during testing

## Test Coverage

The test suite focuses on:

✅ Core functionality of each service
✅ Error handling and edge cases
✅ State management and lifecycle
✅ Integration between services (using mocks where appropriate)

### Coverage Goals

- **Services**: > 80% code coverage
- **ViewModels**: > 80% code coverage (to be added in integration tests)
- **UI Components**: > 60% code coverage (to be added in UI tests)

## Mock Objects

### MockTranscriptionEngine

Located in `TranscriptionServiceTests.swift`, this mock implements the `TranscriptionEngine` protocol for testing transcription coordination without depending on WhisperKit.

Features:
- Configurable success/failure scenarios
- Simulated progress updates
- Controllable transcription delay
- Call tracking for verification

## Integration Tests

Integration tests verify the complete workflows by testing multiple services working together.

### RecordingIntegrationTests

Tests the complete recording and transcription flow:
- Creating notes from recordings
- Automatic transcription after recording
- Progress updates during transcription
- Data persistence in Core Data
- Audio file storage on disk
- Error handling during transcription

### ImportIntegrationTests

Tests audio file import functionality:
- Importing different audio formats (M4A, MP3, WAV, AAC, CAF)
- File copying to recordings directory
- Duration extraction from audio files
- Automatic transcription after import
- Validation of unsupported formats
- File integrity verification

### PlaybackIntegrationTests

Tests audio playback and note editing:
- Loading and playing audio files
- Play/pause/stop controls
- Seeking and skipping functionality
- Editing note titles and transcripts
- Data persistence across operations
- Concurrent playback and editing
- Audio file integrity after edits

## Best Practices

1. **Isolation**: Each test is independent and doesn't rely on other tests
2. **Cleanup**: All tests clean up their resources in `tearDown()`
3. **Async/Await**: Tests use modern Swift concurrency for async operations
4. **Descriptive Names**: Test names clearly describe what is being tested
5. **Arrange-Act-Assert**: Tests follow the AAA pattern for clarity

## Troubleshooting

### Tests Fail Due to Permissions

If recording tests fail:
1. Run the app once on the simulator
2. Grant microphone permission when prompted
3. Run tests again

### Core Data Conflicts

If you see Core Data errors:
- Tests use in-memory stores that are isolated
- Check that `PersistenceController(inMemory: true)` is being used
- Ensure proper cleanup in `tearDown()`

### File System Issues

If file tests fail:
- Check that the app has proper file system access
- Verify that temporary directory is accessible
- Ensure cleanup is happening in `tearDown()`

## Future Enhancements

Planned additions to the test suite:

- [x] Integration tests (Task 15) - Completed
- [ ] UI tests (Task 16)
- [ ] Accessibility tests (Task 17)
- [ ] Performance tests
- [ ] Snapshot tests for UI components

## Contributing

When adding new tests:

1. Follow the existing test structure
2. Use descriptive test names: `test<Method>_<Scenario>_<ExpectedResult>`
3. Add proper setup and teardown
4. Document any special requirements
5. Ensure tests are deterministic and don't depend on timing

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Best Practices](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Async Testing in Swift](https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations)
