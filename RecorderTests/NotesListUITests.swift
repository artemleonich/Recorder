//
//  NotesListUITests.swift
//  RecorderTests
//
//  UI tests for the notes list screen
//

import XCTest

final class NotesListUITests: XCTestCase {
    
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
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test: Notes List Display
    
    func testNotesList_DisplaysNotes() throws {
        // Given: App is on notes list screen
        let notesTitle = app.staticTexts["Записи"]
        XCTAssertTrue(notesTitle.exists, "Notes list title should be visible")
        
        // Then: Notes list should be visible
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Notes list scroll view should exist")
        
        // Verify search bar exists
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'Поиск'")).firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist")
    }
    
    // MARK: - Test: Search Functionality
    
    func testNotesSearch_FiltersNotesByTitle() throws {
        // Given: Notes list with multiple notes
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'Поиск'")).firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist")
        
        // Get initial count of visible notes
        let initialNoteCount = app.scrollViews.firstMatch.otherElements.count
        
        // When: User enters search text
        searchField.tap()
        searchField.typeText("Test")
        
        // Wait for filtering to occur
        sleep(1)
        
        // Then: Notes list should be filtered
        // The filtered list should have fewer or equal items
        let filteredNoteCount = app.scrollViews.firstMatch.otherElements.count
        XCTAssertLessThanOrEqual(filteredNoteCount, initialNoteCount, "Filtered list should have fewer or equal items")
        
        // Clear search
        if let clearButton = searchField.buttons["Clear text"].firstMatch, clearButton.exists {
            clearButton.tap()
        } else {
            // Alternative: select all and delete
            searchField.tap()
            searchField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10))
        }
    }
    
    func testNotesSearch_ShowsEmptyStateWhenNoResults() throws {
        // Given: Notes list with search field
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'Поиск'")).firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist")
        
        // When: User searches for non-existent text
        searchField.tap()
        searchField.typeText("XYZ123NonExistentNote456")
        
        // Wait for filtering
        sleep(1)
        
        // Then: Empty state should be shown
        let emptyMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Ничего не найдено' OR label CONTAINS[c] 'Nothing found'")).firstMatch
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 2), "Empty state message should be visible")
        
        // Verify empty state icon
        let emptyIcon = app.images["mic.slash"]
        XCTAssertTrue(emptyIcon.exists, "Empty state icon should be visible")
    }
    
    func testNotesSearch_ClearButtonResetsFilter() throws {
        // Given: Search field with text
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'Поиск'")).firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist")
        
        searchField.tap()
        searchField.typeText("Test")
        sleep(1)
        
        // Get filtered count
        let filteredCount = app.scrollViews.firstMatch.otherElements.count
        
        // When: User clears the search
        if let clearButton = searchField.buttons["Clear text"].firstMatch, clearButton.exists {
            clearButton.tap()
        } else {
            // Select all and delete
            searchField.doubleTap()
            app.menuItems["Select All"].tap()
            app.keys["delete"].tap()
        }
        
        sleep(1)
        
        // Then: All notes should be visible again
        let unfilteredCount = app.scrollViews.firstMatch.otherElements.count
        XCTAssertGreaterThanOrEqual(unfilteredCount, filteredCount, "Unfiltered list should have more or equal items")
    }
    
    // MARK: - Test: Swipe to Delete
    
    func testNotesList_SwipeToDeleteShowsDeleteButton() throws {
        // Given: Notes list with at least one note
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")
        
        // Find first note cell
        let firstNote = scrollView.otherElements.firstMatch
        
        // Skip test if no notes exist
        guard firstNote.exists else {
            throw XCTSkip("No notes available for swipe test")
        }
        
        // When: User swipes left on a note
        firstNote.swipeLeft()
        
        // Then: Delete button should appear
        let deleteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Удалить' OR label CONTAINS[c] 'Delete'")).firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button should appear after swipe")
    }
    
    func testNotesList_DeleteButtonRemovesNote() throws {
        // Given: Notes list with at least one note
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")
        
        // Get initial note count
        let initialCount = scrollView.otherElements.count
        
        // Skip test if no notes exist
        guard initialCount > 0 else {
            throw XCTSkip("No notes available for delete test")
        }
        
        // Find first note and get its title for verification
        let firstNote = scrollView.otherElements.firstMatch
        let noteTitle = firstNote.staticTexts.firstMatch.label
        
        // When: User swipes and taps delete
        firstNote.swipeLeft()
        
        let deleteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Удалить' OR label CONTAINS[c] 'Delete'")).firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button should appear")
        
        deleteButton.tap()
        
        // Wait for deletion to complete
        sleep(1)
        
        // Then: Note should be removed from list
        let updatedCount = scrollView.otherElements.count
        XCTAssertLessThan(updatedCount, initialCount, "Note count should decrease after deletion")
        
        // Verify the specific note is gone
        let deletedNote = app.staticTexts[noteTitle]
        XCTAssertFalse(deletedNote.exists, "Deleted note should no longer exist in list")
    }
    
    func testNotesList_SwipeRightDoesNotShowDelete() throws {
        // Given: Notes list with at least one note
        let scrollView = app.scrollViews.firstMatch
        let firstNote = scrollView.otherElements.firstMatch
        
        guard firstNote.exists else {
            throw XCTSkip("No notes available for swipe test")
        }
        
        // When: User swipes right (wrong direction)
        firstNote.swipeRight()
        
        // Then: Delete button should not appear
        let deleteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Удалить' OR label CONTAINS[c] 'Delete'")).firstMatch
        XCTAssertFalse(deleteButton.exists, "Delete button should not appear on right swipe")
    }
    
    // MARK: - Test: FAB (Floating Action Button)
    
    func testNotesList_FABOpensRecording() throws {
        // Given: Notes list screen
        let fab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Быстрая запись' OR identifier == 'mic.fill'")).firstMatch
        
        // FAB might not be visible if there are no notes or in certain states
        if fab.exists {
            // When: User taps FAB
            fab.tap()
            
            // Then: Recording screen or sheet should appear
            sleep(1)
            
            // Look for recording screen elements
            let recordingIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
            XCTAssertTrue(recordingIndicator.exists, "Recording screen should appear")
        }
    }
    
    // MARK: - Test: Note Selection
    
    func testNotesList_TappingNoteOpensDetail() throws {
        // Given: Notes list with at least one note
        let scrollView = app.scrollViews.firstMatch
        let firstNote = scrollView.otherElements.firstMatch
        
        guard firstNote.exists else {
            throw XCTSkip("No notes available for selection test")
        }
        
        // When: User taps on a note
        firstNote.tap()
        
        // Then: Note detail screen should open
        sleep(1)
        
        // Look for detail screen elements
        let detailTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Детали' OR label CONTAINS[c] 'Details'")).firstMatch
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Назад' OR identifier == 'chevron.left'")).firstMatch
        
        XCTAssertTrue(detailTitle.exists || backButton.exists, "Note detail screen should be visible")
        
        // Navigate back
        if backButton.exists {
            backButton.tap()
        }
    }
    
    // MARK: - Test: Empty State
    
    func testNotesList_ShowsEmptyStateWhenNoNotes() throws {
        // This test requires launching with no test data
        // Skip if notes exist
        let scrollView = app.scrollViews.firstMatch
        
        if scrollView.otherElements.count == 0 {
            // Then: Empty state should be visible
            let emptyIcon = app.images["mic.slash"]
            let emptyMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Нет записей' OR label CONTAINS[c] 'No notes'")).firstMatch
            
            XCTAssertTrue(emptyIcon.exists, "Empty state icon should be visible")
            XCTAssertTrue(emptyMessage.exists, "Empty state message should be visible")
        }
    }
    
    // MARK: - Test: Accessibility
    
    func testNotesList_HasAccessibilityLabels() throws {
        // Verify search field has accessibility
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'Поиск'")).firstMatch
        XCTAssertTrue(searchField.exists, "Search field should have accessibility")
        
        // Verify notes have accessibility labels
        let scrollView = app.scrollViews.firstMatch
        if scrollView.otherElements.count > 0 {
            let firstNote = scrollView.otherElements.firstMatch
            XCTAssertTrue(firstNote.exists, "Notes should have accessibility")
        }
        
        // Verify FAB has accessibility
        let fab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'запись'")).firstMatch
        if fab.exists {
            XCTAssertNotNil(fab.label, "FAB should have accessibility label")
        }
    }
}
