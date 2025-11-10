//
//  SettingsUITests.swift
//  RecorderTests
//
//  UI tests for the settings screen
//

import XCTest

final class SettingsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
        
        // Navigate to settings
        let settingsTab = app.buttons["Настройки"]
        if settingsTab.exists {
            settingsTab.tap()
            sleep(1)
        }
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test: Settings Screen Display
    
    func testSettings_DisplaysAllSections() throws {
        // Given: Settings screen is open
        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Settings title should be visible")
        
        // Then: All main sections should be visible
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Settings scroll view should exist")
        
        // Verify section headers exist
        let languageSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Язык'")).firstMatch
        let appearanceSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Внешний вид'")).firstMatch
        let transcriptionSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Транскрипция'")).firstMatch
        
        XCTAssertTrue(languageSection.exists, "Language section should exist")
        XCTAssertTrue(appearanceSection.exists, "Appearance section should exist")
        XCTAssertTrue(transcriptionSection.exists, "Transcription section should exist")
    }
    
    // MARK: - Test: Language Settings
    
    func testSettings_ChangeLanguage() throws {
        // Given: Settings screen with language option
        let languageOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Язык приложения' OR label CONTAINS[c] 'App language'")).firstMatch
        
        // Scroll to language option if needed
        if !languageOption.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(languageOption.waitForExistence(timeout: 2), "Language option should exist")
        
        // Get current language value
        let currentLanguage = languageOption.staticTexts.element(boundBy: 1).label
        
        // When: User taps language option
        languageOption.tap()
        sleep(1)
        
        // Then: Language selection screen should appear
        let languageList = app.tables.firstMatch
        XCTAssertTrue(languageList.exists || app.collectionViews.firstMatch.exists, "Language selection list should appear")
        
        // Select a different language
        let russianOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Русский' OR label CONTAINS[c] 'Russian'")).firstMatch
        let englishOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Английский' OR label CONTAINS[c] 'English'")).firstMatch
        
        if russianOption.exists && !currentLanguage.contains("Русский") {
            russianOption.tap()
        } else if englishOption.exists {
            englishOption.tap()
        }
        
        // Wait for navigation back
        sleep(1)
        
        // Then: Should return to settings screen
        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.exists, "Should return to settings screen")
    }
    
    func testSettings_LanguageSelectionShowsCheckmark() throws {
        // Given: Settings screen
        let languageOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Язык'")).firstMatch
        
        if !languageOption.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(languageOption.waitForExistence(timeout: 2), "Language option should exist")
        
        // When: User opens language selection
        languageOption.tap()
        sleep(1)
        
        // Then: Current selection should have checkmark
        let checkmark = app.images["checkmark"]
        XCTAssertTrue(checkmark.exists, "Checkmark should indicate current selection")
        
        // Navigate back
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Назад' OR identifier == 'chevron.left'")).firstMatch
        if backButton.exists {
            backButton.tap()
        } else {
            app.swipeRight()
        }
    }
    
    // MARK: - Test: Appearance Settings
    
    func testSettings_ChangeTheme() throws {
        // Given: Settings screen with appearance option
        let themeOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Тема' OR label CONTAINS[c] 'Theme'")).firstMatch
        
        // Scroll to theme option if needed
        if !themeOption.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(themeOption.waitForExistence(timeout: 2), "Theme option should exist")
        
        // When: User taps theme option
        themeOption.tap()
        sleep(1)
        
        // Then: Theme selection screen should appear
        let themeList = app.tables.firstMatch
        XCTAssertTrue(themeList.exists || app.collectionViews.firstMatch.exists, "Theme selection list should appear")
        
        // Verify theme options exist
        let autoOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Авто' OR label CONTAINS[c] 'Auto'")).firstMatch
        let lightOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Светлая' OR label CONTAINS[c] 'Light'")).firstMatch
        let darkOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Тёмная' OR label CONTAINS[c] 'Dark'")).firstMatch
        
        XCTAssertTrue(autoOption.exists || lightOption.exists || darkOption.exists, "Theme options should exist")
        
        // Select dark theme
        if darkOption.exists {
            darkOption.tap()
            sleep(1)
        }
        
        // Then: Should return to settings
        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2), "Should return to settings screen")
    }
    
    func testSettings_TextSizeOption() throws {
        // Given: Settings screen
        let textSizeOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Размер текста' OR label CONTAINS[c] 'Text size'")).firstMatch
        
        // Scroll to text size option if needed
        if !textSizeOption.exists {
            app.swipeUp()
        }
        
        // Then: Text size option should exist
        XCTAssertTrue(textSizeOption.waitForExistence(timeout: 2), "Text size option should exist")
    }
    
    // MARK: - Test: Transcription Settings
    
    func testSettings_ChangeTranscriptionMode() throws {
        // Given: Settings screen with transcription mode option
        let transcriptionModeOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Режим транскрипции' OR label CONTAINS[c] 'Transcription mode'")).firstMatch
        
        // Scroll to transcription mode if needed
        if !transcriptionModeOption.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(transcriptionModeOption.waitForExistence(timeout: 2), "Transcription mode option should exist")
        
        // Get current mode
        let currentMode = transcriptionModeOption.staticTexts.element(boundBy: 1).label
        
        // When: User taps transcription mode
        transcriptionModeOption.tap()
        sleep(1)
        
        // Then: Mode selection screen should appear
        let modeList = app.tables.firstMatch
        XCTAssertTrue(modeList.exists || app.collectionViews.firstMatch.exists, "Mode selection list should appear")
        
        // Verify mode options exist
        let fastMode = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Быстрый' OR label CONTAINS[c] 'Fast'")).firstMatch
        let accurateMode = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Точный' OR label CONTAINS[c] 'Accurate'")).firstMatch
        
        XCTAssertTrue(fastMode.exists || accurateMode.exists, "Mode options should exist")
        
        // Select accurate mode if not already selected
        if accurateMode.exists && !currentMode.contains("Точный") {
            accurateMode.tap()
            sleep(1)
        }
        
        // Then: Should return to settings
        let settingsTitle = app.staticTexts["Настройки"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2), "Should return to settings screen")
    }
    
    // MARK: - Test: Toggle Settings
    
    func testSettings_ToggleAudioImport() throws {
        // Given: Settings screen with audio import toggle
        let importToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'Импорт аудио' OR label CONTAINS[c] 'Import audio'")).firstMatch
        
        // Scroll to toggle if needed
        if !importToggle.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(importToggle.waitForExistence(timeout: 2), "Audio import toggle should exist")
        
        // Get initial state
        let initialState = importToggle.value as? String
        
        // When: User toggles the switch
        importToggle.tap()
        sleep(1)
        
        // Then: Toggle state should change
        let newState = importToggle.value as? String
        XCTAssertNotEqual(initialState, newState, "Toggle state should change")
        
        // Toggle back to original state
        importToggle.tap()
        sleep(1)
    }
    
    func testSettings_ToggleArchiveAudio() throws {
        // Given: Settings screen with archive audio toggle
        let archiveToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'Архивировать аудио' OR label CONTAINS[c] 'Archive audio'")).firstMatch
        
        // Scroll to toggle if needed
        if !archiveToggle.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(archiveToggle.waitForExistence(timeout: 2), "Archive audio toggle should exist")
        
        // When: User toggles the switch
        let initialState = archiveToggle.value as? String
        archiveToggle.tap()
        sleep(1)
        
        // Then: Toggle state should change
        let newState = archiveToggle.value as? String
        XCTAssertNotEqual(initialState, newState, "Toggle state should change")
        
        // Toggle back
        archiveToggle.tap()
    }
    
    func testSettings_ToggleAutoDelete() throws {
        // Given: Settings screen with auto-delete toggle
        let autoDeleteToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'Автоудаление' OR label CONTAINS[c] 'Auto-delete'")).firstMatch
        
        // Scroll to toggle if needed
        if !autoDeleteToggle.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(autoDeleteToggle.waitForExistence(timeout: 2), "Auto-delete toggle should exist")
        
        // When: User enables auto-delete
        if (autoDeleteToggle.value as? String) == "0" {
            autoDeleteToggle.tap()
            sleep(1)
            
            // Then: Days picker should appear
            let daysPicker = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'дней' OR label CONTAINS[c] 'days'")).firstMatch
            XCTAssertTrue(daysPicker.exists, "Days picker should appear when auto-delete is enabled")
            
            // Toggle back off
            autoDeleteToggle.tap()
        }
    }
    
    func testSettings_ToggleAutoBackup() throws {
        // Given: Settings screen with auto-backup toggle
        let autoBackupToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'Автоматическое резервное копирование' OR label CONTAINS[c] 'Auto-backup'")).firstMatch
        
        // Scroll to toggle if needed
        if !autoBackupToggle.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(autoBackupToggle.waitForExistence(timeout: 2), "Auto-backup toggle should exist")
        
        // When: User toggles the switch
        let initialState = autoBackupToggle.value as? String
        autoBackupToggle.tap()
        sleep(1)
        
        // Then: Toggle state should change
        let newState = autoBackupToggle.value as? String
        XCTAssertNotEqual(initialState, newState, "Toggle state should change")
        
        // Toggle back
        autoBackupToggle.tap()
    }
    
    func testSettings_ToggleSoundEffects() throws {
        // Given: Settings screen with sound effects toggle
        let soundEffectsToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'Звуковые эффекты' OR label CONTAINS[c] 'Sound effects'")).firstMatch
        
        // Scroll to toggle if needed
        if !soundEffectsToggle.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(soundEffectsToggle.waitForExistence(timeout: 2), "Sound effects toggle should exist")
        
        // When: User toggles the switch
        let initialState = soundEffectsToggle.value as? String
        soundEffectsToggle.tap()
        sleep(1)
        
        // Then: Toggle state should change
        let newState = soundEffectsToggle.value as? String
        XCTAssertNotEqual(initialState, newState, "Toggle state should change")
        
        // Toggle back
        soundEffectsToggle.tap()
    }
    
    // MARK: - Test: Storage Information
    
    func testSettings_DisplaysStorageInformation() throws {
        // Given: Settings screen
        // Scroll to storage section
        app.swipeUp()
        sleep(1)
        
        // Then: Storage information should be visible
        let storageSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Хранилище' OR label CONTAINS[c] 'Storage'")).firstMatch
        
        if storageSection.exists {
            let usedStorage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Занято' OR label CONTAINS[c] 'Used'")).firstMatch
            let availableStorage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Доступно' OR label CONTAINS[c] 'Available'")).firstMatch
            
            XCTAssertTrue(usedStorage.exists || availableStorage.exists, "Storage information should be displayed")
        }
    }
    
    // MARK: - Test: About Section
    
    func testSettings_DisplaysVersionNumber() throws {
        // Given: Settings screen
        // Scroll to about section
        app.swipeUp()
        app.swipeUp()
        sleep(1)
        
        // Then: Version number should be visible
        let versionLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Версия' OR label CONTAINS[c] 'Version'")).firstMatch
        
        if versionLabel.exists {
            let versionNumber = app.staticTexts["1.0.0"]
            XCTAssertTrue(versionNumber.exists, "Version number should be displayed")
        }
    }
    
    func testSettings_PrivacyPolicyOption() throws {
        // Given: Settings screen
        // Scroll to about section
        app.swipeUp()
        app.swipeUp()
        sleep(1)
        
        // Then: Privacy policy option should exist
        let privacyOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Политика конфиденциальности' OR label CONTAINS[c] 'Privacy policy'")).firstMatch
        
        XCTAssertTrue(privacyOption.exists, "Privacy policy option should exist")
    }
    
    func testSettings_RateAppOption() throws {
        // Given: Settings screen
        // Scroll to about section
        app.swipeUp()
        app.swipeUp()
        sleep(1)
        
        // Then: Rate app option should exist
        let rateOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Оценить приложение' OR label CONTAINS[c] 'Rate app'")).firstMatch
        
        XCTAssertTrue(rateOption.exists, "Rate app option should exist")
    }
    
    // MARK: - Test: Settings Persistence
    
    func testSettings_SettingsPersistAfterRestart() throws {
        // Given: Settings screen with a toggle
        let importToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'Импорт аудио'")).firstMatch
        
        if !importToggle.exists {
            app.swipeUp()
        }
        
        guard importToggle.waitForExistence(timeout: 2) else {
            throw XCTSkip("Import toggle not found")
        }
        
        // Get initial state
        let initialState = importToggle.value as? String
        
        // When: User changes setting
        importToggle.tap()
        sleep(1)
        
        let changedState = importToggle.value as? String
        XCTAssertNotEqual(initialState, changedState, "State should change")
        
        // Restart app
        app.terminate()
        app.launch()
        
        // Navigate back to settings
        let settingsTab = app.buttons["Настройки"]
        if settingsTab.exists {
            settingsTab.tap()
            sleep(1)
        }
        
        // Scroll to toggle
        if !importToggle.exists {
            app.swipeUp()
        }
        
        // Then: Setting should persist
        let persistedState = importToggle.value as? String
        XCTAssertEqual(changedState, persistedState, "Setting should persist after restart")
        
        // Restore original state
        if persistedState != initialState {
            importToggle.tap()
        }
    }
    
    // MARK: - Test: Accessibility
    
    func testSettings_AllTogglesHaveAccessibility() throws {
        // Given: Settings screen
        let switches = app.switches
        
        // Then: All switches should have accessibility labels
        for i in 0..<min(switches.count, 5) {
            let toggle = switches.element(boundBy: i)
            XCTAssertNotNil(toggle.label, "Toggle \(i) should have accessibility label")
            XCTAssertTrue(toggle.isEnabled, "Toggle \(i) should be enabled")
        }
    }
    
    func testSettings_NavigationOptionsHaveAccessibility() throws {
        // Given: Settings screen
        let navigationButtons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'chevron.right'"))
        
        // Then: Navigation options should have accessibility
        for i in 0..<min(navigationButtons.count, 3) {
            let button = navigationButtons.element(boundBy: i)
            if button.exists {
                XCTAssertNotNil(button.label, "Navigation button \(i) should have accessibility label")
            }
        }
    }
    
    // MARK: - Test: Section Icons
    
    func testSettings_SectionsHaveIcons() throws {
        // Given: Settings screen
        // Then: Section icons should be visible
        let globeIcon = app.images["globe"]
        let paintbrushIcon = app.images["paintbrush.fill"]
        let waveformIcon = app.images["waveform"]
        
        // At least some icons should exist
        let iconCount = [globeIcon.exists, paintbrushIcon.exists, waveformIcon.exists].filter { $0 }.count
        XCTAssertGreaterThan(iconCount, 0, "At least one section icon should be visible")
    }
}
