#!/bin/bash

# Navigate to the _Mods Files directory
cd "$(dirname "$0")/.." || exit 1

README="README.md"
TMP_TABLE=$(mktemp)

# Create the table header
echo "| Mod | Hotkey | Action |" > "$TMP_TABLE"
echo "|---|---|---|" >> "$TMP_TABLE"

TMP_ROWS=$(mktemp)

process_match() {
    local action="$1"
    local hotkey="$2"
    local mod_name="$3"
    local is_hotkey=0
    
    # If hotkey value matches SButton patterns
    if [[ "$hotkey" =~ ^([A-Z]|F[1-9]|F1[0-2]|Oem[A-Za-z]+|Left[A-Za-z]+|Right[A-Za-z]+|Space|Tab|Enter|Escape)$ ]]; then
        is_hotkey=1
    fi
    
    # If action name suggests it's a hotkey
    if echo "$action" | grep -qiE '(key|button|toggle)'; then
        if [[ "$hotkey" != "None" && "$hotkey" != "false" && "$hotkey" != "true" && -n "$hotkey" ]]; then
            is_hotkey=1
        fi
    fi
    
    if [ "$is_hotkey" -eq 1 ]; then
        # Clean pipes and newlines
        hotkey=$(echo "$hotkey" | tr '|' '-' | tr '\n' ' ')
        mod_name=$(echo "$mod_name" | tr '|' '-' | tr '\n' ' ')
        action=$(echo "$action" | tr '|' '-' | tr '\n' ' ')
        echo "${mod_name}|${hotkey}|${action}" >> "$TMP_ROWS"
    fi
}

find . -type f \( -name "config.json" -o -name "config.toml" \) | while read -r config; do
    if [[ "$config" == *"_scripts"* ]] || [[ "$config" == *".git"* ]]; then
        continue
    fi
    
    # Extract Mod name from directory path
    mod_dir=$(dirname "$config")
    mod_name=$(basename "$mod_dir")
    
    # Optional: try to get actual Name from manifest.json if it exists
    manifest="$mod_dir/manifest.json"
    if [ -f "$manifest" ]; then
        real_name=$(grep -oP '"Name"\s*:\s*"\K[^"]+' "$manifest" | head -1)
        if [ -n "$real_name" ]; then
            mod_name="$real_name"
        fi
    fi
    
    if [[ "$config" == *".json" ]]; then
        grep -oP '"([^"]+)"\s*:\s*"([^"]+)"' "$config" | while read -r match; do
            action=$(echo "$match" | grep -oP '^"\K[^"]+')
            hotkey=$(echo "$match" | grep -oP ':\s*"\K[^"]+')
            process_match "$action" "$hotkey" "$mod_name"
        done
    elif [[ "$config" == *".toml" ]]; then
        grep -oP '^[^#]*([A-Za-z0-9_]+)\s*=\s*"([^"]+)"' "$config" | while read -r match; do
            action=$(echo "$match" | awk -F'=' '{print $1}' | tr -d ' ')
            hotkey=$(echo "$match" | grep -oP '=\s*"\K[^"]+')
            process_match "$action" "$hotkey" "$mod_name"
        done
    fi
done

# Sort rows by Mod then Hotkey (case insensitive) and format as markdown table
sort -u -f -t'|' -k1,1 -k2,2 "$TMP_ROWS" | while IFS='|' read -r mod hotkey action; do
    echo "| ${mod} | ${hotkey} | ${action} |" >> "$TMP_TABLE"
done

# Replace the Mod Hotkeys section in README.md
awk '
BEGIN { output=1 }
/^## Mod Hotkeys$/ {
    print
    while ((getline line < "'"$TMP_TABLE"'") > 0) {
        print line
    }
    output=0
}
output { print }
' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"

rm "$TMP_TABLE" "$TMP_ROWS"

echo "Successfully updated README.md with the hotkey table."
