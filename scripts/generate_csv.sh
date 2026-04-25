#!/bin/bash

# Absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MODS_SOURCE_DIR="$SCRIPT_DIR/../mods"
output_file="$SCRIPT_DIR/mods.csv"

echo "active,name" > "$output_file"

for dir in "$MODS_SOURCE_DIR"/*/; do
    if [ -d "$dir" ]; then
        dirname="$(basename "$dir")"
        if [[ "$dirname" != _* ]]; then
            echo "TRUE,$dirname" >> "$output_file"
        fi
    fi
done

echo "Generated $output_file successfully."