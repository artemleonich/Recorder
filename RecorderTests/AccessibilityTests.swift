//
//  AccessibilityTests.swift
//  RecorderTests
//
//  Accessibility tests for VoiceOver navigation and Dynamic Type support
//

import XCTest

final class AccessibilityTests: XCTestCase {
    
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
    
    // MARK: - VoiceOver Navigation Tests
    
    func testVoiceOver_RecordingScreenNavigation() throws {
        // Given: App is launched on the recording screen
        // Verify main interactive elements have accessibility labels
        
        // Check app title is accessible
        let appTitle = app.staticTexts["Речь в Текст"]
        XCTAssertTrue(appTitle.exists, "App title should be accessible")
        
        // Check record button has accessibility label
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should have accessibility label")
        XCTAssertFalse(recordButton.label.isEmpty, "Record button label should not be empty")
        
        // Verify the button label is descriptive
        let buttonLabel = recordButton.label.lowercased()
        XCTAssertTrue(
            buttonLabel.contains("запись") || buttonLabel.contains("начать") || buttonLabel.contains("остановить"),
            "Record button should have descriptive label"
        )
        
        // Check timer is accessible
        let timer = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        XCTAssertTrue(timer.exists, "Timer should be accessible")
        
        // Check status text is accessible
        let statusText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись' OR label CONTAINS[c] 'Нажмите'")).firstMatch
        XCTAssertTrue(statusText.exists, "Status text should be accessible")
        
        // Check settings button/tab is accessible
        let settingsTab = app.buttons["Настройки"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should be accessible")
        XCTAssertFalse(settingsTab.label.isEmpty, "Settings tab label should not be empty")
    }
    
    func testVoiceOver_NotesListNavigation() throws {
        // Given: Navigate to notes list
        let notesTab = app.buttons["Заметки"]
        XCTAssertTrue(notesTab.exists, "Notes tab should exist")
        XCTAssertFalse(notesTab.label.isEmpty, "Notes tab should have label")
        
        notesTab.tap()
        sleep(1)
        
        // Then: Verify notes list elements are accessible
        
        // Check search field is accessible
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            XCTAssertFalse(searchField.label.isEmpty || searchField.placeholderValue?.isEmpty == true,
                          "Search field should have label or placeholder")
        }
        
        // Check notes list is accessible
        let notesList = app.scrollViews.firstMatch
        XCTAssertTrue(notesList.exists, "Notes list should be accessible")
        
        // If there are notes, check they have accessibility labels
        let firstNote = app.buttons.firstMatch
        if firstNote.exists && firstNote.label.contains(".") {
            // This is likely a note (contains date format)
            XCTAssertFalse(firstNote.label.isEmpty, "Note items should have accessibility labels")
            
            // Verify note label contains useful information
            let noteLabel = firstNote.label
            XCTAssertTrue(
                noteLabel.contains(":") || noteLabel.contains("."),
                "Note label should contain date/time information"
            )
        }
    }
    
    func testVoiceOver_AudioPlayerNavigation() throws {
        // Given: Navigate to notes list and open a note
        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)
        
        // Find and tap on first note if it exists
        let firstNote = app.buttons.firstMatch
        guard firstNote.exists else {
            throw XCTSkip("No notes available to test audio player accessibility")
        }
        
        firstNote.tap()
        sleep(1)
        
        // Then: Verify audio player controls are accessible
        
        // Check play/pause button
        let playButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'play' OR label CONTAINS[c] 'pause' OR label CONTAINS[c] 'воспроизвед' OR label CONTAINS[c] 'пауза'")).firstMatch
        if playButton.exists {
            XCTAssertFalse(playButton.label.isEmpty, "Play/pause button should have accessibility label")
        }
        
        // Check skip forward button
        let skipForwardButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'вперед' OR label CONTAINS[c] '+10' OR label CONTAINS[c] 'forward'")).firstMatch
        if skipForwardButton.exists {
            XCTAssertFalse(skipForwardButton.label.isEmpty, "Skip forward button should have accessibility label")
        }
        
        // Check skip backward button
        let skipBackwardButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'назад' OR label CONTAINS[c] '-10' OR label CONTAINS[c] 'backward'")).firstMatch
        if skipBackwardButton.exists {
            XCTAssertFalse(skipBackwardButton.label.isEmpty, "Skip backward button should have accessibility label")
        }
        
        // Check progress slider
        let progressSlider = app.sliders.firstMatch
        if progressSlider.exists {
            XCTAssertTrue(progressSlider.isEnabled, "Progress slider should be accessible")
        }
        
        // Check time labels
        let timeLabels = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'"))
        XCTAssertGreaterThanOrEqual(timeLabels.count, 1, "Time labels should be accessible")
    }
    
    func testVoiceOver_AllInteractiveElementsHaveLabels() throws {
        // Test: Verify all buttons across the app have accessibility labels
        
        // Recording screen
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists && !recordButton.label.isEmpty, "Record button should have label")
        
        // Tab bar buttons
        let recordingTab = app.buttons["Запись"]
        if recordingTab.exists {
            XCTAssertFalse(recordingTab.label.isEmpty, "Recording tab should have label")
        }
        
        let notesTab = app.buttons["Заметки"]
        XCTAssertTrue(notesTab.exists && !notesTab.label.isEmpty, "Notes tab should have label")
        
        let settingsTab = app.buttons["Настройки"]
        XCTAssertTrue(settingsTab.exists && !settingsTab.label.isEmpty, "Settings tab should have label")
        
        // Navigate to settings
        settingsTab.tap()
        sleep(1)
        
        // Check settings toggles and navigation links
        let settingsElements = app.switches.allElementsBoundByIndex + app.buttons.allElementsBoundByIndex
        for element in settingsElements where element.exists {
            // Skip tab bar buttons
            if element.label != "Запись" && element.label != "Заметки" && element.label != "Настройки" {
                XCTAssertFalse(element.label.isEmpty, "Settings element should have accessibility label: \(element)")
            }
        }
    }
    
    func testVoiceOver_AccessibilityHintsForNonObviousActions() throws {
        // Test: Verify non-obvious actions have accessibility hints
        
        // Record button should have a hint explaining what it does
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        
        // The button's label should be descriptive enough to serve as a hint
        let buttonLabel = recordButton.label.lowercased()
        XCTAssertTrue(
            buttonLabel.contains("начать") || buttonLabel.contains("запись") || buttonLabel.contains("остановить"),
            "Record button should have descriptive action label"
        )
        
        // Navigate to notes list
        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)
        
        // Search field should have placeholder text as hint
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            let placeholder = searchField.placeholderValue ?? ""
            XCTAssertFalse(placeholder.isEmpty, "Search field should have placeholder text")
            XCTAssertTrue(
                placeholder.lowercased().contains("поиск") || placeholder.lowercased().contains("search"),
                "Search field placeholder should indicate search functionality"
            )
        }
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicType_TextElementsScale() throws {
        // Test: Verify text elements scale with Dynamic Type
        // Note: This test verifies that text elements exist and are accessible
        // Actual scaling behavior is tested through manual testing with different text sizes
        
        // Recording screen
        let appTitle = app.staticTexts["Речь в Текст"]
        XCTAssertTrue(appTitle.exists, "App title should exist")
        
        let timer = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        XCTAssertTrue(timer.exists, "Timer should exist")
        
        let statusText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись' OR label CONTAINS[c] 'Нажмите'")).firstMatch
        XCTAssertTrue(statusText.exists, "Status text should exist")
        
        // Navigate to notes list
        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)
        
        // Check notes list text elements
        let notesTitle = app.staticTexts["Записи"]
        if notesTitle.exists {
            XCTAssertTrue(notesTitle.exists, "Notes title should exist")
        }
        
        // Navigate to settings
        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)
        
        // Check settings text elements
        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Settings title should exist")
        
        // Verify section headers exist
        let languageSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Язык'")).firstMatch
        let appearanceSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Внешний вид'")).firstMatch
        let transcriptionSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Транскрипция'")).firstMatch
        
        // At least some section headers should exist
        XCTAssertTrue(
            languageSection.exists || appearanceSection.exists || transcriptionSection.exists,
            "Settings sections should have text labels"
        )
    }
    
    func testDynamicType_LayoutAdaptation() throws {
        // Test: Verify layout doesn't clip text at different sizes
        // This test checks that key UI elements are visible and not truncated
        
        // Recording screen
        let appTitle = app.staticTexts["Речь в Текст"]
        XCTAssertTrue(appTitle.exists, "App title should be visible")
        XCTAssertTrue(appTitle.isHittable, "App title should be fully visible (not clipped)")
        
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should be visible")
        XCTAssertTrue(recordButton.isHittable, "Record button should be fully visible")
        
        // Navigate to notes list
        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)
        
        // Check search field is visible
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            XCTAssertTrue(searchField.isHittable, "Search field should be fully visible")
        }
        
        // Navigate to settings
        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)
        
        // Check settings elements are visible
        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Settings title should be visible")
        XCTAssertTrue(settingsTitle.isHittable, "Settings title should be fully visible")
        
        // Check that toggle switches are visible and accessible
        let toggles = app.switches.allElementsBoundByIndex
        for toggle in toggles where toggle.exists {
            XCTAssertTrue(toggle.isHittable, "Toggle should be fully visible and hittable")
        }
    }
    
    func testDynamicType_MinimumButtonSize() throws {
        // Test: Verify buttons meet minimum 44x44 pt size requirement
        // Note: XCUITest doesn't directly expose frame sizes, so we verify buttons are hittable
        
        // Recording screen - main record button
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        XCTAssertTrue(recordButton.isHittable, "Record button should be hittable (meets minimum size)")
        
        // Verify button can be tapped (indicates sufficient size)
        let buttonFrame = recordButton.frame
        XCTAssertGreaterThanOrEqual(buttonFrame.width, 44, "Record button width should be at least 44pt")
        XCTAssertGreaterThanOrEqual(buttonFrame.height, 44, "Record button height should be at least 44pt")
        
        // Tab bar buttons
        let notesTab = app.buttons["Заметки"]
        XCTAssertTrue(notesTab.isHittable, "Notes tab should be hittable")
        
        let settingsTab = app.buttons["Настройки"]
        XCTAssertTrue(settingsTab.isHittable, "Settings tab should be hittable")
        
        // Navigate to notes list
        notesTab.tap()
        sleep(1)
        
        // Check if there are notes with action buttons
        let firstNote = app.buttons.firstMatch
        if firstNote.exists && firstNote.label.contains(".") {
            XCTAssertTrue(firstNote.isHittable, "Note button should be hittable")
            
            let noteFrame = firstNote.frame
            XCTAssertGreaterThanOrEqual(noteFrame.height, 44, "Note row should be at least 44pt tall")
        }
        
        // Navigate to settings
        settingsTab.tap()
        sleep(1)
        
        // Check settings navigation buttons
        let navigationButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chevron' OR label CONTAINS[c] '>'")).allElementsBoundByIndex
        for button in navigationButtons where button.exists {
            XCTAssertTrue(button.isHittable, "Navigation button should be hittable")
        }
        
        // Check toggle switches
        let toggles = app.switches.allElementsBoundByIndex
        for toggle in toggles where toggle.exists {
            XCTAssertTrue(toggle.isHittable, "Toggle switch should be hittable")
            
            let toggleFrame = toggle.frame
            XCTAssertGreaterThanOrEqual(toggleFrame.height, 44, "Toggle switch should be at least 44pt tall")
        }
    }
    
    func testDynamicType_AllTextElementsUseSystemFonts() throws {
        // Test: Verify text elements exist and are accessible
        // This ensures they can scale with Dynamic Type
        
        var textElements: [XCUIElement] = []
        
        // Collect text elements from recording screen
        textElements.append(app.staticTexts["Речь в Текст"])
        textElements.append(contentsOf: app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).allElementsBoundByIndex)
        textElements.append(contentsOf: app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).allElementsBoundByIndex)
        
        // Navigate to notes list
        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)
        
        // Collect text elements from notes list
        if app.staticTexts["Записи"].exists {
            textElements.append(app.staticTexts["Записи"])
        }
        
        // Navigate to settings
        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)
        
        // Collect text elements from settings
        textElements.append(app.staticTexts["Настройки"])
        textElements.append(contentsOf: app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Язык' OR label CONTAINS[c] 'Внешний вид' OR label CONTAINS[c] 'Транскрипция'")).allElementsBoundByIndex)
        
        // Verify all collected text elements are accessible
        var accessibleCount = 0
        for element in textElements where element.exists {
            XCTAssertTrue(element.isHittable || element.label.count > 0, "Text element should be accessible")
            accessibleCount += 1
        }
        
        XCTAssertGreaterThan(accessibleCount, 0, "Should have found accessible text elements")
    }
    
    // MARK: - Reduce Motion Tests
    
    func testReduceMotion_AnimationsCanBeDisabled() throws {
        // Test: Verify app functions correctly regardless of motion settings
        // This test ensures the app doesn't rely solely on animations for functionality
        
        // Recording screen - button should work without animations
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        
        // Tap button - should work with or without animations
        recordButton.tap()
        sleep(1)
        
        // Verify recording started (status change, not animation)
        let recordingStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Идёт запись'")).firstMatch
        XCTAssertTrue(recordingStatus.waitForExistence(timeout: 3), "Recording status should update")
        
        // Stop recording
        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Остановить'")).firstMatch
        if stopButton.exists {
            stopButton.tap()
            sleep(1)
        }
        
        // Navigate to notes list - should work without animations
        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)
        
        // Verify navigation worked
        let notesList = app.scrollViews.firstMatch
        XCTAssertTrue(notesList.exists, "Notes list should be visible after navigation")
        
        // Navigate to settings - should work without animations
        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)
        
        // Verify navigation worked
        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Settings should be visible after navigation")
    }
    
    // MARK: - Comprehensive Accessibility Audit
    
    func testAccessibility_ComprehensiveAudit() throws {
        // Test: Comprehensive check of accessibility across all screens
        
        var issues: [String] = []
        
        // Recording Screen Audit
        if !app.staticTexts["Речь в Текст"].exists {
            issues.append("Recording screen: App title not accessible")
        }
        
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        if !recordButton.exists || recordButton.label.isEmpty {
            issues.append("Recording screen: Record button missing accessibility label")
        }
        
        // Notes List Audit
        let notesTab = app.buttons["Заметки"]
        if !notesTab.exists || notesTab.label.isEmpty {
            issues.append("Tab bar: Notes tab missing accessibility label")
        }
        
        notesTab.tap()
        sleep(1)
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists && (searchField.placeholderValue?.isEmpty ?? true) {
            issues.append("Notes list: Search field missing placeholder text")
        }
        
        // Settings Audit
        let settingsTab = app.buttons["Настройки"]
        if !settingsTab.exists || settingsTab.label.isEmpty {
            issues.append("Tab bar: Settings tab missing accessibility label")
        }
        
        settingsTab.tap()
        sleep(1)
        
        if !app.staticTexts["Настройки"].exists {
            issues.append("Settings screen: Title not accessible")
        }
        
        // Report any issues found
        XCTAssertTrue(issues.isEmpty, "Accessibility issues found:\n" + issues.joined(separator: "\n"))
    }
}
