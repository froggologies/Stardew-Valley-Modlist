#!/bin/bash

# Absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
MODS_DIR="$PARENT_DIR/../Mods"

# Use the first argument as the CSV file, defaulting to mods.csv
CSV_ARG="${1:-mods.csv}"
if [[ "$CSV_ARG" == /* ]]; then
    CSV_FILE="$CSV_ARG"
else
    CSV_FILE="$SCRIPT_DIR/$CSV_ARG"
fi

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found at $CSV_FILE"
    exit 1
fi

# Create Mods directory if it doesn't exist
mkdir -p "$MODS_DIR"

# Clear all links in ../Mods
echo "Clearing existing links in $MODS_DIR..."
find "$MODS_DIR" -maxdepth 1 -type l -delete

active_count=0

echo "Reading $CSV_FILE..."
# Read mods.csv, skipping the header.
while IFS=, read -r active name || [[ -n "$active" ]]; do
    # Clean up carriage returns in case the CSV was saved with CRLF
    active="${active//$'\r'/}"
    name="${name//$'\r'/}"

    if [[ "$active" == "TRUE" ]]; then
        ((active_count++))
        if [[ -d "$PARENT_DIR/$name" ]]; then
            echo "Linking: $name"
            ln -s "$PARENT_DIR/$name" "$MODS_DIR/$name"
        else
            echo "Warning: Mod directory not found - $name"
        fi
    fi
done < <(tail -n +2 "$CSV_FILE")

unlinked_count=0
echo "Checking for inactive mods..."
for dir in "$PARENT_DIR"/*/; do
    # Remove trailing slash
    dir="${dir%/}"
    dir_name="$(basename "$dir")"
    
    if [[ "$dir_name" == "_scripts" ]]; then continue; fi

    # Check if a link exists in MODS_DIR
    if [[ -d "$dir" && ! -L "$MODS_DIR/$dir_name" ]]; then
        echo "Not linked: $dir_name"
        ((unlinked_count++))
    fi
done

echo "Done!"
echo "Active mods: $active_count"
echo "Inactive mods: $unlinked_count"
