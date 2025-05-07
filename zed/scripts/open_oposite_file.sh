#!/bin/bash

# Get the full path of the current file
current_file="$ZED_FILE"

# Define the base directory for the test files
test_base_dir="spec"

# Replace 'lib/' with 'spec/' and append '_spec.rb' to the filename
test_file="${current_file/lib\//${test_base_dir}\/}"
test_file="${test_file%.rb}_spec.rb"

# Check if the test file exists
if [ -f "$test_file" ]; then
    # Open the test file in a new right-side split
    zed --split=right "$test_file"
else
    echo "Test file not found: $test_file"
fi
