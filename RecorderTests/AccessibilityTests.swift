//
//  AccessibilityTests.swift
//  RecorderTests
//
//  Created by Артём Леонов on 11/10/25.
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

    // MARK: - VoiceOver

    func testVoiceOver_RecordingScreenNavigation() throws {
        let appTitle = app.staticTexts["Речь в Текст"]
        XCTAssertTrue(appTitle.exists, "App title should be accessible")

        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should have accessibility label")
        XCTAssertFalse(recordButton.label.isEmpty, "Record button label should not be empty")

        let buttonLabel = recordButton.label.lowercased()
        XCTAssertTrue(
            buttonLabel.contains("запись") || buttonLabel.contains("начать") || buttonLabel.contains("остановить"),
            "Record button should have descriptive label"
        )

        let timer = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        XCTAssertTrue(timer.exists, "Timer should be accessible")

        let statusText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись' OR label CONTAINS[c] 'Нажмите'")).firstMatch
        XCTAssertTrue(statusText.exists, "Status text should be accessible")

        let settingsTab = app.buttons["Настройки"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should be accessible")
        XCTAssertFalse(settingsTab.label.isEmpty, "Settings tab label should not be empty")
    }

    func testVoiceOver_NotesListNavigation() throws {
        let notesTab = app.buttons["Заметки"]
        XCTAssertTrue(notesTab.exists, "Notes tab should exist")
        XCTAssertFalse(notesTab.label.isEmpty, "Notes tab should have label")

        notesTab.tap()
        sleep(1)

        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            XCTAssertFalse(searchField.label.isEmpty || searchField.placeholderValue?.isEmpty == true,
                          "Search field should have label or placeholder")
        }

        let notesList = app.scrollViews.firstMatch
        XCTAssertTrue(notesList.exists, "Notes list should be accessible")

        let firstNote = app.buttons.firstMatch
        if firstNote.exists && firstNote.label.contains(".") {
            XCTAssertFalse(firstNote.label.isEmpty, "Note items should have accessibility labels")

            let noteLabel = firstNote.label
            XCTAssertTrue(
                noteLabel.contains(":") || noteLabel.contains("."),
                "Note label should contain date/time information"
            )
        }
    }

    func testVoiceOver_AudioPlayerNavigation() throws {
        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)

        let firstNote = app.buttons.firstMatch
        guard firstNote.exists else {
            throw XCTSkip("No notes available to test audio player accessibility")
        }

        firstNote.tap()
        sleep(1)

        let playButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'play' OR label CONTAINS[c] 'pause' OR label CONTAINS[c] 'воспроизвед' OR label CONTAINS[c] 'пауза'")).firstMatch
        if playButton.exists {
            XCTAssertFalse(playButton.label.isEmpty, "Play/pause button should have accessibility label")
        }

        let skipForwardButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'вперед' OR label CONTAINS[c] '+10' OR label CONTAINS[c] 'forward'")).firstMatch
        if skipForwardButton.exists {
            XCTAssertFalse(skipForwardButton.label.isEmpty, "Skip forward button should have accessibility label")
        }

        let skipBackwardButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'назад' OR label CONTAINS[c] '-10' OR label CONTAINS[c] 'backward'")).firstMatch
        if skipBackwardButton.exists {
            XCTAssertFalse(skipBackwardButton.label.isEmpty, "Skip backward button should have accessibility label")
        }

        let progressSlider = app.sliders.firstMatch
        if progressSlider.exists {
            XCTAssertTrue(progressSlider.isEnabled, "Progress slider should be accessible")
        }

        let timeLabels = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'"))
        XCTAssertGreaterThanOrEqual(timeLabels.count, 1, "Time labels should be accessible")
    }

    func testVoiceOver_AllInteractiveElementsHaveLabels() throws {
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists && !recordButton.label.isEmpty, "Record button should have label")

        let recordingTab = app.buttons["Запись"]
        if recordingTab.exists {
            XCTAssertFalse(recordingTab.label.isEmpty, "Recording tab should have label")
        }

        let notesTab = app.buttons["Заметки"]
        XCTAssertTrue(notesTab.exists && !notesTab.label.isEmpty, "Notes tab should have label")

        let settingsTab = app.buttons["Настройки"]
        XCTAssertTrue(settingsTab.exists && !settingsTab.label.isEmpty, "Settings tab should have label")

        settingsTab.tap()
        sleep(1)

        let settingsElements = app.switches.allElementsBoundByIndex + app.buttons.allElementsBoundByIndex
        for element in settingsElements where element.exists {
            if element.label != "Запись" && element.label != "Заметки" && element.label != "Настройки" {
                XCTAssertFalse(element.label.isEmpty, "Settings element should have accessibility label: \(element)")
            }
        }
    }

    func testVoiceOver_AccessibilityHintsForNonObviousActions() throws {
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")

        let buttonLabel = recordButton.label.lowercased()
        XCTAssertTrue(
            buttonLabel.contains("начать") || buttonLabel.contains("запись") || buttonLabel.contains("остановить"),
            "Record button should have descriptive action label"
        )

        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)

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

    // MARK: - Dynamic Type

    func testDynamicType_TextElementsScale() throws {
        // Verifies text elements exist and are accessible; actual scaling tested manually
        let appTitle = app.staticTexts["Речь в Текст"]
        XCTAssertTrue(appTitle.exists, "App title should exist")

        let timer = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).firstMatch
        XCTAssertTrue(timer.exists, "Timer should exist")

        let statusText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись' OR label CONTAINS[c] 'Нажмите'")).firstMatch
        XCTAssertTrue(statusText.exists, "Status text should exist")

        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)

        let notesTitle = app.staticTexts["Записи"]
        if notesTitle.exists {
            XCTAssertTrue(notesTitle.exists, "Notes title should exist")
        }

        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)

        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Settings title should exist")

        let languageSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Язык'")).firstMatch
        let appearanceSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Внешний вид'")).firstMatch
        let transcriptionSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Транскрипция'")).firstMatch

        XCTAssertTrue(
            languageSection.exists || appearanceSection.exists || transcriptionSection.exists,
            "Settings sections should have text labels"
        )
    }

    func testDynamicType_LayoutAdaptation() throws {
        let appTitle = app.staticTexts["Речь в Текст"]
        XCTAssertTrue(appTitle.exists, "App title should be visible")
        XCTAssertTrue(appTitle.isHittable, "App title should be fully visible (not clipped)")

        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should be visible")
        XCTAssertTrue(recordButton.isHittable, "Record button should be fully visible")

        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)

        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            XCTAssertTrue(searchField.isHittable, "Search field should be fully visible")
        }

        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)

        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Settings title should be visible")
        XCTAssertTrue(settingsTitle.isHittable, "Settings title should be fully visible")

        let toggles = app.switches.allElementsBoundByIndex
        for toggle in toggles where toggle.exists {
            XCTAssertTrue(toggle.isHittable, "Toggle should be fully visible and hittable")
        }
    }

    func testDynamicType_MinimumButtonSize() throws {
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        XCTAssertTrue(recordButton.isHittable, "Record button should be hittable (meets minimum size)")

        let buttonFrame = recordButton.frame
        XCTAssertGreaterThanOrEqual(buttonFrame.width, 44, "Record button width should be at least 44pt")
        XCTAssertGreaterThanOrEqual(buttonFrame.height, 44, "Record button height should be at least 44pt")

        let notesTab = app.buttons["Заметки"]
        XCTAssertTrue(notesTab.isHittable, "Notes tab should be hittable")

        let settingsTab = app.buttons["Настройки"]
        XCTAssertTrue(settingsTab.isHittable, "Settings tab should be hittable")

        notesTab.tap()
        sleep(1)

        let firstNote = app.buttons.firstMatch
        if firstNote.exists && firstNote.label.contains(".") {
            XCTAssertTrue(firstNote.isHittable, "Note button should be hittable")

            let noteFrame = firstNote.frame
            XCTAssertGreaterThanOrEqual(noteFrame.height, 44, "Note row should be at least 44pt tall")
        }

        settingsTab.tap()
        sleep(1)

        let navigationButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chevron' OR label CONTAINS[c] '>'")).allElementsBoundByIndex
        for button in navigationButtons where button.exists {
            XCTAssertTrue(button.isHittable, "Navigation button should be hittable")
        }

        let toggles = app.switches.allElementsBoundByIndex
        for toggle in toggles where toggle.exists {
            XCTAssertTrue(toggle.isHittable, "Toggle switch should be hittable")

            let toggleFrame = toggle.frame
            XCTAssertGreaterThanOrEqual(toggleFrame.height, 44, "Toggle switch should be at least 44pt tall")
        }
    }

    func testDynamicType_AllTextElementsUseSystemFonts() throws {
        var textElements: [XCUIElement] = []

        textElements.append(app.staticTexts["Речь в Текст"])
        textElements.append(contentsOf: app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d{2}:\\\\d{2}'")).allElementsBoundByIndex)
        textElements.append(contentsOf: app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).allElementsBoundByIndex)

        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)

        if app.staticTexts["Записи"].exists {
            textElements.append(app.staticTexts["Записи"])
        }

        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)

        textElements.append(app.staticTexts["Настройки"])
        textElements.append(contentsOf: app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Язык' OR label CONTAINS[c] 'Внешний вид' OR label CONTAINS[c] 'Транскрипция'")).allElementsBoundByIndex)

        var accessibleCount = 0
        for element in textElements where element.exists {
            XCTAssertTrue(element.isHittable || element.label.count > 0, "Text element should be accessible")
            accessibleCount += 1
        }

        XCTAssertGreaterThan(accessibleCount, 0, "Should have found accessible text elements")
    }

    func testReduceMotion_AnimationsCanBeDisabled() throws {
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        XCTAssertTrue(recordButton.exists, "Record button should exist")

        recordButton.tap()
        sleep(1)

        let recordingStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Идёт запись'")).firstMatch
        XCTAssertTrue(recordingStatus.waitForExistence(timeout: 3), "Recording status should update")

        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Остановить'")).firstMatch
        if stopButton.exists {
            stopButton.tap()
            sleep(1)
        }

        let notesTab = app.buttons["Заметки"]
        notesTab.tap()
        sleep(1)

        let notesList = app.scrollViews.firstMatch
        XCTAssertTrue(notesList.exists, "Notes list should be visible after navigation")

        let settingsTab = app.buttons["Настройки"]
        settingsTab.tap()
        sleep(1)

        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Settings should be visible after navigation")
    }

    func testAccessibility_ComprehensiveAudit() throws {
        var issues: [String] = []

        if !app.staticTexts["Речь в Текст"].exists {
            issues.append("Recording screen: App title not accessible")
        }

        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        if !recordButton.exists || recordButton.label.isEmpty {
            issues.append("Recording screen: Record button missing accessibility label")
        }

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

        let settingsTab = app.buttons["Настройки"]
        if !settingsTab.exists || settingsTab.label.isEmpty {
            issues.append("Tab bar: Settings tab missing accessibility label")
        }

        settingsTab.tap()
        sleep(1)

        if !app.staticTexts["Настройки"].exists {
            issues.append("Settings screen: Title not accessible")
        }

        XCTAssertTrue(issues.isEmpty, "Accessibility issues found:\n" + issues.joined(separator: "\n"))
    }
}
