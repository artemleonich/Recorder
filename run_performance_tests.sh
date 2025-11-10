#!/bin/bash

# Performance Testing Script for Recorder App
# This script runs performance tests and collects metrics

set -e

echo "🚀 Starting Performance Tests for Recorder App"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SCHEME="Recorder"
DESTINATION="platform=iOS Simulator,name=iPhone 15"
TEST_CLASS="RecorderTests/PerformanceTests"

echo "📋 Configuration:"
echo "  Scheme: $SCHEME"
echo "  Destination: $DESTINATION"
echo "  Test Class: $TEST_CLASS"
echo ""

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: xcodebuild not found${NC}"
    echo "Please ensure Xcode Command Line Tools are installed"
    exit 1
fi

# Run performance tests
echo "🧪 Running Performance Tests..."
echo ""

xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:"$TEST_CLASS" \
    2>&1 | tee performance_test_output.log

# Check test results
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Performance Tests Passed${NC}"
    echo ""
    
    # Extract performance metrics from log
    echo "📊 Performance Metrics:"
    echo "======================"
    
    # Notes list loading time
    if grep -q "Notes list loading time" performance_test_output.log; then
        LOAD_TIME=$(grep "Notes list loading time" performance_test_output.log | grep -oE '[0-9]+\.[0-9]+s' | head -1)
        echo -e "  Notes List (100 notes): ${GREEN}$LOAD_TIME${NC} (Target: < 0.5s)"
    fi
    
    # Search performance
    if grep -q "Search time" performance_test_output.log; then
        SEARCH_TIME=$(grep "Search time" performance_test_output.log | grep -oE '[0-9]+\.[0-9]+s' | head -1)
        echo -e "  Search (100 notes): ${GREEN}$SEARCH_TIME${NC} (Target: < 0.1s)"
    fi
    
    # Batch operations
    if grep -q "Batch create time" performance_test_output.log; then
        CREATE_TIME=$(grep "Batch create time" performance_test_output.log | grep -oE '[0-9]+\.[0-9]+s' | head -1)
        echo -e "  Batch Create (50 notes): ${GREEN}$CREATE_TIME${NC} (Target: < 2.0s)"
    fi
    
    if grep -q "Batch update time" performance_test_output.log; then
        UPDATE_TIME=$(grep "Batch update time" performance_test_output.log | grep -oE '[0-9]+\.[0-9]+s' | head -1)
        echo -e "  Batch Update (50 notes): ${GREEN}$UPDATE_TIME${NC} (Target: < 2.0s)"
    fi
    
    # File operations
    if grep -q "File existence check time" performance_test_output.log; then
        FILE_TIME=$(grep "File existence check time" performance_test_output.log | grep -oE '[0-9]+\.[0-9]+s' | head -1)
        echo -e "  File Checks (1000 ops): ${GREEN}$FILE_TIME${NC} (Target: < 0.5s)"
    fi
    
    echo ""
    echo "📝 Full test output saved to: performance_test_output.log"
    echo ""
    
else
    echo ""
    echo -e "${RED}❌ Performance Tests Failed${NC}"
    echo "Check performance_test_output.log for details"
    exit 1
fi

# Recommendations
echo "💡 Performance Optimization Tips:"
echo "================================="
echo "1. Run Instruments Time Profiler to identify bottlenecks"
echo "2. Use Instruments Allocations to check memory usage"
echo "3. Use Instruments Leaks to verify no memory leaks"
echo "4. Test on physical devices for accurate results"
echo "5. Profile with different dataset sizes (10, 100, 500 notes)"
echo ""

# Instructions for Instruments
echo "🔧 To profile with Instruments:"
echo "  1. Open Xcode"
echo "  2. Select Product > Profile (⌘I)"
echo "  3. Choose Time Profiler or Allocations"
echo "  4. Record and perform operations"
echo "  5. Analyze results for optimization opportunities"
echo ""

echo -e "${GREEN}✨ Performance testing complete!${NC}"
