#!/bin/bash

# Script to check if the Recorder app builds successfully
# Usage: ./check_build.sh

set -e

echo "🔍 Checking Recorder build..."
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Clean build folder
echo "🧹 Cleaning build folder..."
xcodebuild -project Recorder.xcodeproj -scheme Recorder clean

echo ""
echo "🔨 Building project..."
xcodebuild -project Recorder.xcodeproj \
    -scheme Recorder \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -quiet \
    build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "Next steps:"
    echo "1. Open Recorder.xcodeproj in Xcode"
    echo "2. Run the app (Cmd+R)"
    echo "3. Test the following:"
    echo "   - Theme switching (Settings → Appearance)"
    echo "   - Language switching (Settings → Language)"
    echo "   - Recording and transcription"
    echo ""
else
    echo ""
    echo "❌ Build failed!"
    echo "Please check the errors above and fix them."
    echo ""
    exit 1
fi
