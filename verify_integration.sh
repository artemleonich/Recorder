#!/bin/bash

# Integration Verification Script for Task 18.1
# This script verifies all integration points mentioned in the task

echo "========================================="
echo "Integration Verification for Task 18.1"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for checks
PASSED=0
FAILED=0

# Function to print check result
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAILED++))
    fi
}

echo "1. Checking ViewModels dependency injection..."
echo "----------------------------------------------"

# Check RecordingViewModel dependencies
grep -q "audioRecorder: AudioRecorderService" Recorder/ViewModels/RecordingViewModel.swift
check_result $? "RecordingViewModel has AudioRecorderService dependency"

grep -q "transcriptionService: TranscriptionService" Recorder/ViewModels/RecordingViewModel.swift
check_result $? "RecordingViewModel has TranscriptionService dependency"

grep -q "storageService: NotesStorageService" Recorder/ViewModels/RecordingViewModel.swift
check_result $? "RecordingViewModel has NotesStorageService dependency"

grep -q "settings: AppSettings" Recorder/ViewModels/RecordingViewModel.swift
check_result $? "RecordingViewModel has AppSettings dependency"

# Check NotesListViewModel dependencies
grep -q "storageService: NotesStorageService" Recorder/ViewModels/NotesListViewModel.swift
check_result $? "NotesListViewModel has NotesStorageService dependency"

grep -q "fileStorageService: FileStorageService" Recorder/ViewModels/NotesListViewModel.swift
check_result $? "NotesListViewModel has FileStorageService dependency"

grep -q "transcriptionService: TranscriptionService" Recorder/ViewModels/NotesListViewModel.swift
check_result $? "NotesListViewModel has TranscriptionService dependency"

# Check NoteDetailViewModel dependencies
grep -q "audioPlayer: AudioPlayerService" Recorder/ViewModels/NoteDetailViewModel.swift
check_result $? "NoteDetailViewModel has AudioPlayerService dependency"

grep -q "storageService: NotesStorageService" Recorder/ViewModels/NoteDetailViewModel.swift
check_result $? "NoteDetailViewModel has NotesStorageService dependency"

grep -q "fileStorageService: FileStorageService" Recorder/ViewModels/NoteDetailViewModel.swift
check_result $? "NoteDetailViewModel has FileStorageService dependency"

# Check SettingsViewModel dependencies
grep -q "settings: AppSettings" Recorder/ViewModels/SettingsViewModel.swift
check_result $? "SettingsViewModel has AppSettings dependency"

grep -q "notesStorageService: NotesStorageService" Recorder/ViewModels/SettingsViewModel.swift
check_result $? "SettingsViewModel has NotesStorageService dependency"

echo ""
echo "2. Checking Services dependencies..."
echo "----------------------------------------------"

# Check AudioRecorderService dependencies
grep -q "fileStorageService: FileStorageService" Recorder/Services/AudioRecorderService.swift
check_result $? "AudioRecorderService has FileStorageService dependency"

# Check NotesStorageService dependencies
grep -q "persistenceController: PersistenceController" Recorder/Services/NotesStorageService.swift
check_result $? "NotesStorageService has PersistenceController dependency"

grep -q "fileStorageService: FileStorageService" Recorder/Services/NotesStorageService.swift
check_result $? "NotesStorageService has FileStorageService dependency"

# Check TranscriptionService dependencies
grep -q "storageService: NotesStorageService" Recorder/Services/TranscriptionService.swift
check_result $? "TranscriptionService has NotesStorageService dependency"

echo ""
echo "3. Checking Core Data initialization..."
echo "----------------------------------------------"

# Check RecorderApp has PersistenceController
grep -q "let persistenceController = PersistenceController.shared" Recorder/RecorderApp.swift
check_result $? "RecorderApp initializes PersistenceController"

# Check Core Data environment injection
grep -q "managedObjectContext" Recorder/RecorderApp.swift
check_result $? "RecorderApp injects Core Data context into environment"

# Check PersistenceController exists
[ -f "Recorder/CoreData/PersistenceController.swift" ]
check_result $? "PersistenceController.swift exists"

echo ""
echo "4. Checking error handling..."
echo "----------------------------------------------"

# Check RecorderError enum exists
[ -f "Recorder/Models/RecorderError.swift" ]
check_result $? "RecorderError.swift exists"

# Check ViewModels have error properties
grep -q "@Published var error: RecorderError?" Recorder/ViewModels/RecordingViewModel.swift
check_result $? "RecordingViewModel has error property"

grep -q "@Published var error: RecorderError?" Recorder/ViewModels/NotesListViewModel.swift
check_result $? "NotesListViewModel has error property"

grep -q "@Published var error: RecorderError?" Recorder/ViewModels/NoteDetailViewModel.swift
check_result $? "NoteDetailViewModel has error property"

echo ""
echo "5. Checking async operations and threading..."
echo "----------------------------------------------"

# Check ViewModels are @MainActor
grep -q "@MainActor" Recorder/ViewModels/RecordingViewModel.swift
check_result $? "RecordingViewModel is @MainActor"

grep -q "@MainActor" Recorder/ViewModels/NotesListViewModel.swift
check_result $? "NotesListViewModel is @MainActor"

grep -q "@MainActor" Recorder/ViewModels/NoteDetailViewModel.swift
check_result $? "NoteDetailViewModel is @MainActor"

grep -q "@MainActor" Recorder/ViewModels/SettingsViewModel.swift
check_result $? "SettingsViewModel is @MainActor"

# Check TranscriptionService is actor
grep -q "actor TranscriptionService" Recorder/Services/TranscriptionService.swift
check_result $? "TranscriptionService is an actor for thread-safety"

# Check async methods exist
grep -q "func startRecording() async" Recorder/ViewModels/RecordingViewModel.swift
check_result $? "RecordingViewModel has async startRecording method"

grep -q "func loadNotes() async" Recorder/ViewModels/NotesListViewModel.swift
check_result $? "NotesListViewModel has async loadNotes method"

echo ""
echo "6. Checking utility classes..."
echo "----------------------------------------------"

# Check utilities exist
[ -f "Recorder/Utilities/StorageUtility.swift" ]
check_result $? "StorageUtility.swift exists"

[ -f "Recorder/Utilities/DateFormatter+Extensions.swift" ]
check_result $? "DateFormatter+Extensions.swift exists"

[ -f "Recorder/Utilities/AppSettings.swift" ]
check_result $? "AppSettings.swift exists"

[ -f "Recorder/Utilities/Logger+Extensions.swift" ]
check_result $? "Logger+Extensions.swift exists"

echo ""
echo "7. Checking model files..."
echo "----------------------------------------------"

# Check models exist
[ -f "Recorder/Models/AudioNote.swift" ]
check_result $? "AudioNote.swift exists"

[ -f "Recorder/Models/TranscriptionMode.swift" ]
check_result $? "TranscriptionMode.swift exists"

[ -f "Recorder/Models/TranscriptionResult.swift" ]
check_result $? "TranscriptionResult.swift exists"

[ -f "Recorder/Models/RecorderError.swift" ]
check_result $? "RecorderError.swift exists"

echo ""
echo "8. Building project..."
echo "----------------------------------------------"

# Try to build the project
xcodebuild build -scheme Recorder -destination 'platform=iOS Simulator,id=71DB792E-E0A6-4796-A9BC-61F0B7786EDC' > /dev/null 2>&1
check_result $? "Project builds successfully"

echo ""
echo "========================================="
echo "Integration Verification Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All integration checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some integration checks failed.${NC}"
    exit 1
fi
