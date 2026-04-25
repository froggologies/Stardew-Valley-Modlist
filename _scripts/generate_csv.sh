#!/bin/bash

# Absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
output_file="$SCRIPT_DIR/mods.csv"

echo "active,name" > "$output_file"

for dir in "$PARENT_DIR"/*/; do
    if [ -d "$dir" ]; then
        dirname="$(basename "$dir")"
        if [[ "$dirname" != _* ]]; then
            echo "TRUE,$dirname" >> "$output_file"
        fi
    fi
done

echo "Generated $output_file successfully."