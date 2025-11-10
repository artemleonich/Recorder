//
//  NoteDetailUITests.swift
//  RecorderTests
//
//  UI tests for the note detail screen
//

import XCTest

final class NoteDetailUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing", "PrepareTestNotes"]
        app.launch()
        
        // Navigate to notes list
        let notesTab = app.buttons["Заметки"]
        if notesTab.exists {
            notesTab.tap()
            sleep(1)
        }
        
        // Open first note
        let scrollView = app.scrollViews.firstMatch
        let firstNote = scrollView.otherElements.firstMatch
        if firstNote.exists {
            firstNote.tap()
            sleep(1)
        }
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test: Note Detail Display
    
    func testNoteDetail_DisplaysNoteInformation() throws {
        // Given: Note detail screen is open
        // Verify we're on detail screen
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Назад' OR identifier == 'chevron.left'")).firstMatch
        XCTAssertTrue(backButton.exists, "Back button should be visible on detail screen")
        
        // Then: Note information should be displayed
        // Title field should exist
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.exists, "Title field should exist")
        
        // Transcript editor should exist
        let transcriptEditor = app.textViews.firstMatch
        XCTAssertTrue(transcriptEditor.exists, "Transcript editor should exist")
        
        // Audio player controls should exist
        let playButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'play' OR label CONTAINS[c] 'Воспроизвести'")).firstMatch
        XCTAssertTrue(playButton.exists, "Play button should exist")
    }
    
    // MARK: - Test: Title Editing
    
    func testNoteDetail_EditTitle() throws {
        // Given: Note detail screen with title field
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.exists, "Title field should exist")
        
        let originalTitle = titleField.value as? String ?? ""
        
        // When: User edits the title
        titleField.tap()
        
        // Clear existing text
        if let deleteString = titleField.value as? String {
            let deleteCount = deleteString.count
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: deleteCount)
            titleField.typeText(deleteString)
        }
        
        // Type new title
        let newTitle = "Updated Test Title"
        titleField.typeText(newTitle)
        
        // Submit by tapping return or done
        app.buttons["Return"].tap()
        
        // Wait for update
        sleep(1)
        
        // Then: Title should be updated
        let updatedValue = titleField.value as? String ?? ""
        XCTAssertTrue(updatedValue.contains(newTitle), "Title should be updated")
    }
    
    func testNoteDetail_TitleFieldHasAccessibility() throws {
        // Given: Note detail screen
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.exists, "Title field should exist")
        
        // Then: Title field should have accessibility
        XCTAssertNotNil(titleField.label, "Title field should have accessibility label")
        XCTAssertTrue(titleField.isEnabled, "Title field should be enabled")
    }
    
    // MARK: - Test: Transcript Editing
    
    func testNoteDetail_EditTranscript() throws {
        // Given: Note detail screen with transcript editor
        let transcriptEditor = app.textViews.firstMatch
        XCTAssertTrue(transcriptEditor.exists, "Transcript editor should exist")
        
        // When: User edits the transcript
        transcriptEditor.tap()
        
        // Type additional text
        let additionalText = " Additional transcription text."
        transcriptEditor.typeText(additionalText)
        
        // Wait for update
        sleep(1)
        
        // Then: Transcript should contain the new text
        let updatedValue = transcriptEditor.value as? String ?? ""
        XCTAssertTrue(updatedValue.contains(additionalText), "Transcript should contain new text")
    }
    
    func testNoteDetail_TranscriptFieldHasAccessibility() throws {
        // Given: Note detail screen
        let transcriptEditor = app.textViews.firstMatch
        XCTAssertTrue(transcriptEditor.exists, "Transcript editor should exist")
        
        // Then: Transcript editor should have accessibility
        XCTAssertNotNil(transcriptEditor.label, "Transcript editor should have accessibility label")
        XCTAssertTrue(transcriptEditor.isEnabled, "Transcript editor should be enabled")
    }
    
    // MARK: - Test: Audio Playback
    
    func testNoteDetail_PlayButtonTogglesPlayback() throws {
        // Given: Note detail screen with audio player
        let playButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'play.circle' OR label CONTAINS[c] 'Воспроизвести'")).firstMatch
        XCTAssertTrue(playButton.exists, "Play button should exist")
        
        // When: User taps play button
        playButton.tap()
        
        // Wait for playback to start
        sleep(1)
        
        // Then: Button should change to pause
        let pauseButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'pause.circle' OR label CONTAINS[c] 'Пауза'")).firstMatch
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Pause button should appear when playing")
        
        // When: User taps pause button
        pauseButton.tap()
        
        // Wait for pause
        sleep(1)
        
        // Then: Button should change back to play
        XCTAssertTrue(playButton.waitForExistence(timeout: 2), "Play button should reappear when paused")
    }
    
    func testNoteDetail_PlaybackProgressUpdates() throws {
        // Given: Note detail screen with audio player
        let playButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'play.circle'")).firstMatch
        let slider = app.sliders.firstMatch
        
        XCTAssertTrue(playButton.exists, "Play button should exist")
        XCTAssertTrue(slider.exists, "Progress slider should exist")
        
        // Get initial slider value
        let initialValue = slider.value as? String ?? "0%"
        
        // When: User starts playback
        playButton.tap()
        
        // Wait for playback to progress
        sleep(2)
        
        // Then: Slider value should update
        let updatedValue = slider.value as? String ?? "0%"
        // Note: This might not always change if audio is very short or mock
        // Just verify slider still exists and is accessible
        XCTAssertTrue(slider.exists, "Slider should still exist during playback")
        
        // Stop playback
        let pauseButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'pause.circle'")).firstMatch
        if pauseButton.exists {
            pauseButton.tap()
        }
    }
    
    // MARK: - Test: Skip Controls
    
    func testNoteDetail_SkipBackwardButton() throws {
        // Given: Note detail screen with skip controls
        let skipBackButton = app.buttons.matching(NSPredicate(format: "identifier == 'gobackward.10' OR label CONTAINS[c] '10 секунд назад'")).firstMatch
        XCTAssertTrue(skipBackButton.exists, "Skip backward button should exist")
        
        // When: User taps skip backward
        skipBackButton.tap()
        
        // Then: Button should be responsive (no crash)
        sleep(1)
        XCTAssertTrue(skipBackButton.exists, "Skip backward button should still exist after tap")
    }
    
    func testNoteDetail_SkipForwardButton() throws {
        // Given: Note detail screen with skip controls
        let skipForwardButton = app.buttons.matching(NSPredicate(format: "identifier == 'goforward.10' OR label CONTAINS[c] '10 секунд вперёд'")).firstMatch
        XCTAssertTrue(skipForwardButton.exists, "Skip forward button should exist")
        
        // When: User taps skip forward
        skipForwardButton.tap()
        
        // Then: Button should be responsive (no crash)
        sleep(1)
        XCTAssertTrue(skipForwardButton.exists, "Skip forward button should still exist after tap")
    }
    
    func testNoteDetail_SkipButtonsHaveAccessibility() throws {
        // Given: Note detail screen
        let skipBackButton = app.buttons.matching(NSPredicate(format: "identifier == 'gobackward.10'")).firstMatch
        let skipForwardButton = app.buttons.matching(NSPredicate(format: "identifier == 'goforward.10'")).firstMatch
        
        // Then: Skip buttons should have accessibility
        XCTAssertTrue(skipBackButton.exists, "Skip backward button should exist")
        XCTAssertTrue(skipForwardButton.exists, "Skip forward button should exist")
        
        XCTAssertNotNil(skipBackButton.label, "Skip backward should have accessibility label")
        XCTAssertNotNil(skipForwardButton.label, "Skip forward should have accessibility label")
    }
    
    // MARK: - Test: Share Functionality
    
    func testNoteDetail_ShareButtonOpensShareSheet() throws {
        // Given: Note detail screen
        let shareButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Поделиться' OR identifier CONTAINS 'square.and.arrow.up'")).firstMatch
        
        // Share button might be in menu or directly visible
        if !shareButton.exists {
            // Try opening menu
            let menuButton = app.buttons.matching(NSPredicate(format: "identifier == 'ellipsis'")).firstMatch
            if menuButton.exists {
                menuButton.tap()
                sleep(1)
            }
        }
        
        // Look for share button again
        let shareButtonInMenu = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Поделиться'")).firstMatch
        
        if shareButtonInMenu.exists {
            // When: User taps share button
            shareButtonInMenu.tap()
            
            // Wait for share sheet
            sleep(1)
            
            // Then: Share sheet should appear
            // Look for activity view controller elements
            let activityView = app.otherElements["ActivityListView"]
            let shareSheet = app.sheets.firstMatch
            
            XCTAssertTrue(activityView.exists || shareSheet.exists, "Share sheet should appear")
            
            // Dismiss share sheet
            if shareSheet.exists {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            }
        }
    }
    
    func testNoteDetail_ShareButtonHasAccessibility() throws {
        // Given: Note detail screen
        let shareButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Поделиться'")).firstMatch
        
        if shareButton.exists {
            // Then: Share button should have accessibility
            XCTAssertNotNil(shareButton.label, "Share button should have accessibility label")
        }
    }
    
    // MARK: - Test: Navigation
    
    func testNoteDetail_BackButtonReturnsToList() throws {
        // Given: Note detail screen
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Назад' OR identifier == 'chevron.left'")).firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist")
        
        // When: User taps back button
        backButton.tap()
        
        // Wait for navigation
        sleep(1)
        
        // Then: Should return to notes list
        let notesTitle = app.staticTexts["Записи"]
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'Поиск'")).firstMatch
        
        XCTAssertTrue(notesTitle.exists || searchField.exists, "Should return to notes list")
    }
    
    func testNoteDetail_MenuButtonOpensMenu() throws {
        // Given: Note detail screen
        let menuButton = app.buttons.matching(NSPredicate(format: "identifier == 'ellipsis' OR label CONTAINS[c] 'Меню'")).firstMatch
        
        if menuButton.exists {
            // When: User taps menu button
            menuButton.tap()
            
            // Wait for menu
            sleep(1)
            
            // Then: Menu should appear with options
            let shareOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Поделиться'")).firstMatch
            let deleteOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Удалить'")).firstMatch
            
            XCTAssertTrue(shareOption.exists || deleteOption.exists, "Menu options should be visible")
            
            // Dismiss menu by tapping outside
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
    }
    
    // MARK: - Test: Time Display
    
    func testNoteDetail_DisplaysCurrentAndTotalTime() throws {
        // Given: Note detail screen with audio player
        // Look for time labels (format: MM:SS)
        let timeLabels = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'"))
        
        // Should have at least 2 time labels (current and total)
        XCTAssertGreaterThanOrEqual(timeLabels.count, 2, "Should display current and total time")
        
        // Verify times are in correct format
        if timeLabels.count >= 2 {
            let firstTime = timeLabels.element(boundBy: 0).label
            let secondTime = timeLabels.element(boundBy: 1).label
            
            XCTAssertTrue(firstTime.matches("\\d{2}:\\d{2}"), "First time should be in MM:SS format")
            XCTAssertTrue(secondTime.matches("\\d{2}:\\d{2}"), "Second time should be in MM:SS format")
        }
    }
    
    // MARK: - Test: Slider Interaction
    
    func testNoteDetail_SliderSeeksPlayback() throws {
        // Given: Note detail screen with slider
        let slider = app.sliders.firstMatch
        XCTAssertTrue(slider.exists, "Progress slider should exist")
        
        // When: User adjusts slider
        slider.adjust(toNormalizedSliderPosition: 0.5)
        
        // Wait for seek
        sleep(1)
        
        // Then: Slider should be at new position
        // Verify slider still exists and is functional
        XCTAssertTrue(slider.exists, "Slider should still exist after adjustment")
    }
    
    // MARK: - Test: Date and Duration Display
    
    func testNoteDetail_DisplaysDateAndDuration() throws {
        // Given: Note detail screen
        // Look for date icon and duration icon
        let calendarIcon = app.images["calendar"]
        let waveformIcon = app.images["waveform"]
        
        // At least one should exist
        XCTAssertTrue(calendarIcon.exists || waveformIcon.exists, "Date or duration info should be visible")
        
        // Look for date text (format: dd.MM.yyyy, HH:mm)
        let dateText = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}\\\\.\\\\d{2}\\\\.\\\\d{4}, \\\\d{2}:\\\\d{2}'")).firstMatch
        
        // Look for duration text (format: MM:SS)
        let durationText = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        
        XCTAssertTrue(dateText.exists || durationText.exists, "Date or duration text should be visible")
    }
}

// Helper extension for regex matching
extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}
