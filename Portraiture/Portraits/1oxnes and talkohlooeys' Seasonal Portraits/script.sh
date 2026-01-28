#!/bin/bash

# Ensure the script runs in the directory where it's located
cd "$(dirname "$0")" || exit

# Use a temp file to track the counts of each prefix
temp_list=$(mktemp)

# First pass: Identify potential groups
for file in *; do
    # Skip directories and this script
    if [[ -d "$file" || "$file" == "script.sh" ]]; then
        continue
    fi
    
    # Determine base name (prefix)
    # Strategy: 
    # 1. If file has underscore, prefix is part before first underscore.
    # 2. If no underscore, prefix is filename without extension.
    if [[ "$file" == *"_"* ]]; then
        base="${file%%_*}"
    else
        base="${file%.*}"
    fi
    
    # Write base to temp file
    echo "$base" >> "$temp_list"
done

# Find prefixes that occur more than once
# sort and run uniq -d to get duplicates
groups_to_create=$(sort "$temp_list" | uniq -d)

rm "$temp_list"

if [[ -z "$groups_to_create" ]]; then
    echo "No files need organizing."
    exit 0
fi

# Create directories
while IFS= read -r group; do
    if [[ -n "$group" ]]; then
        if [[ ! -d "$group" ]]; then
            echo "Creating folder: $group"
            mkdir -p -- "$group"
        fi
    fi
done <<< "$groups_to_create"

# Second pass: Move files into their groups
for file in *; do
    # Skip directories and this script
    if [[ -d "$file" || "$file" == "script.sh" ]]; then
        continue
    fi
    
    # Re-calculate base
    if [[ "$file" == *"_"* ]]; then
        base="${file%%_*}"
    else
        base="${file%.*}"
    fi
    
    # If a directory exists for this base, move the file provided it matches the group logic
    # (Since we only created directories for groups with >1 file, this check suffices)
    if [[ -d "$base" ]]; then
        echo "Moving '$file' -> '$base/'"
        mv -- "$file" "$base/"
    fi
done

echo "Done!"
