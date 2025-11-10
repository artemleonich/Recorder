//
//  RecordingUITests.swift
//  RecorderTests
//
//  UI tests for the recording flow
//

import XCTest

final class RecordingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test: Complete Recording Flow
    
    func testRecordingFlow_StartAndStopRecording() throws {
        // Given: App is launched and we're on the recording tab
        // The app should start on the recording tab by default
        
        // Verify we're on the recording screen by checking for the app title
        let appTitle = app.staticTexts["Речь в Текст"]
        XCTAssertTrue(appTitle.exists, "App title should be visible on recording screen")
        
        // Find the record button
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        
        // Verify initial status text
        let idleStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Нажмите для записи'")).firstMatch
        XCTAssertTrue(idleStatus.waitForExistence(timeout: 2), "Idle status should be visible")
        
        // When: User taps the record button to start recording
        recordButton.tap()
        
        // Wait a moment for recording to start
        sleep(1)
        
        // Then: Verify recording has started
        // Check for recording status text
        let recordingStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Идёт запись'")).firstMatch
        XCTAssertTrue(recordingStatus.waitForExistence(timeout: 3), "Recording status should be visible")
        
        // Verify timer is counting (should show something other than 00:00)
        let timer = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        XCTAssertTrue(timer.exists, "Timer should be visible")
        
        // Wait for a few seconds to let recording continue
        sleep(2)
        
        // Verify timer has progressed
        let timerText = timer.label
        XCTAssertNotEqual(timerText, "00:00", "Timer should have progressed from 00:00")
        
        // When: User taps the record button again to stop recording
        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Остановить'")).firstMatch
        XCTAssertTrue(stopButton.exists, "Stop button should exist")
        stopButton.tap()
        
        // Then: Verify transcription indicator appears
        let transcriptionProgress = app.progressIndicators.firstMatch
        XCTAssertTrue(transcriptionProgress.waitForExistence(timeout: 5), "Transcription progress indicator should appear")
        
        // Verify transcription progress text
        let transcriptionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Транскрипция'")).firstMatch
        XCTAssertTrue(transcriptionText.exists, "Transcription text should be visible")
        
        // Wait for transcription to complete (or timeout)
        sleep(3)
        
        // Navigate to notes list to verify the note was created
        let notesTab = app.buttons["Заметки"]
        if notesTab.exists {
            notesTab.tap()
            
            // Wait for notes list to load
            sleep(1)
            
            // Verify at least one note exists
            let notesList = app.scrollViews.firstMatch
            XCTAssertTrue(notesList.exists, "Notes list should exist")
            
            // Look for a note with today's date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let todayString = dateFormatter.string(from: Date())
            
            let todayNote = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", todayString)).firstMatch
            XCTAssertTrue(todayNote.waitForExistence(timeout: 2), "A note with today's date should exist")
        }
    }
    
    // MARK: - Test: Recording Button States
    
    func testRecordingButton_ChangesStateCorrectly() throws {
        // Given: App is on recording screen
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        
        // Verify initial state (Start recording)
        let startLabel = recordButton.label
        XCTAssertTrue(startLabel.contains("Начать") || startLabel.contains("запись"), "Button should show start recording label")
        
        // When: Start recording
        recordButton.tap()
        sleep(1)
        
        // Then: Button should change to stop state
        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Остановить'")).firstMatch
        XCTAssertTrue(stopButton.waitForExistence(timeout: 2), "Button should change to stop state")
        
        // When: Stop recording
        stopButton.tap()
        sleep(1)
        
        // Then: Button should return to start state (after transcription)
        // Note: During transcription, button might be disabled
        let processingStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Обработка'")).firstMatch
        if processingStatus.exists {
            // Wait for processing to complete
            sleep(3)
        }
    }
    
    // MARK: - Test: Timer Functionality
    
    func testRecordingTimer_CountsUpDuringRecording() throws {
        // Given: App is on recording screen
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        let timer = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        XCTAssertTrue(timer.exists, "Timer should exist")
        
        // Verify timer starts at 00:00
        XCTAssertEqual(timer.label, "00:00", "Timer should start at 00:00")
        
        // When: Start recording
        recordButton.tap()
        sleep(1)
        
        // Then: Timer should start counting
        let initialTime = timer.label
        sleep(2)
        
        let updatedTime = timer.label
        XCTAssertNotEqual(initialTime, updatedTime, "Timer should update during recording")
        XCTAssertNotEqual(updatedTime, "00:00", "Timer should have progressed")
        
        // Stop recording
        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Остановить'")).firstMatch
        if stopButton.exists {
            stopButton.tap()
        }
    }
    
    // MARK: - Test: Settings Button
    
    func testSettingsButton_OpensSettings() throws {
        // Given: App is on recording screen
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Настройки' OR identifier == 'gearshape.fill'")).firstMatch
        
        // The settings button might be in the tab bar or as a gear icon
        let settingsTab = app.buttons["Настройки"]
        
        if settingsTab.exists {
            // When: Tap settings tab
            settingsTab.tap()
            
            // Then: Settings screen should be visible
            let settingsTitle = app.staticTexts["Настройки"]
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2), "Settings title should be visible")
        }
    }
    
    // MARK: - Test: Accessibility
    
    func testRecordingScreen_HasAccessibilityLabels() throws {
        // Verify key elements have accessibility labels
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should have accessibility label")
        
        // Verify timer is accessible
        let timer = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        XCTAssertTrue(timer.exists, "Timer should be accessible")
        
        // Verify status text is accessible
        let statusText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись' OR label CONTAINS[c] 'Нажмите'")).firstMatch
        XCTAssertTrue(statusText.exists, "Status text should be accessible")
    }
}
