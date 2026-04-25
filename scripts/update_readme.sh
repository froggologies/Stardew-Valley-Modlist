#!/bin/bash

# Navigate to the _Mods Files directory
cd "$(dirname "$0")/../mods" || exit 1

README="../README.md"
TMP_TABLE=$(mktemp)

# Create the table header
echo "| Mod Name | Description | Author | Version |" > "$TMP_TABLE"
echo "|---|---|---|---|" >> "$TMP_TABLE"

# Temporary file to store extracted JSON values to sort them later
TMP_ROWS=$(mktemp)

find . -name "manifest.json" | while read -r manifest; do
    # Exclude _scripts and .git directories
    if [[ "$manifest" == *"_scripts"* ]] || [[ "$manifest" == *".git"* ]]; then
        continue
    fi
    
    # Simple regex extraction to avoid jq trailing comma issues
    name=$(grep -oP '"Name"\s*:\s*"\K[^"]+' "$manifest" | head -1)
    description=$(grep -oP '"Description"\s*:\s*"\K[^"]+' "$manifest" | head -1)
    author=$(grep -oP '"Author"\s*:\s*"\K[^"]+' "$manifest" | head -1)
    
    # Version might be a string like "1.2.3" or an object like {"MajorVersion": 1, "MinorVersion": 0}
    version=$(grep -oP '"Version"\s*:\s*"\K[^"]+' "$manifest" | head -1)
    
    if [ -z "$version" ]; then
        # Check if it's an object version
        major=$(grep -oP '"MajorVersion"\s*:\s*\K\d+' "$manifest" | head -1)
        minor=$(grep -oP '"MinorVersion"\s*:\s*\K\d+' "$manifest" | head -1)
        patch=$(grep -oP '"PatchVersion"\s*:\s*\K\d+' "$manifest" | head -1)
        if [ -n "$major" ]; then
            version="${major}.${minor:-0}.${patch:-0}"
        fi
    fi
    # Extract Nexus ID if available
    nexus_id=$(grep -ioP '"nexus:\s*\K\d+' "$manifest" | head -1)
    
    # If Name is empty, we skip
    if [ -z "$name" ]; then
        continue
    fi
    
    # Clean up pipes and newlines for markdown table
    name=$(echo "$name" | tr '|' '-' | tr '\n' ' ')
    description=$(echo "$description" | tr '|' '-' | tr '\n' ' ')
    author=$(echo "$author" | tr '|' '-' | tr '\n' ' ')
    version=$(echo "$version" | tr '|' '-' | tr '\n' ' ')
    
    # Add markdown link if Nexus ID exists
    if [ -n "$nexus_id" ]; then
        name="[${name}](https://www.nexusmods.com/stardewvalley/mods/${nexus_id})"
    fi
    
    echo "${name}|${description}|${author}|${version}" >> "$TMP_ROWS"
done

# Sort rows by name (case insensitive) and format as markdown table
sort -f -t'|' -k1,1 "$TMP_ROWS" | while IFS='|' read -r name description author version; do
    echo "| ${name} | ${description} | ${author} | ${version} |" >> "$TMP_TABLE"
done

# Replace the Included Mods section in README.md
awk '
BEGIN { output=1 }
/^## Included Mods$/ {
    print
    while ((getline line < "'"$TMP_TABLE"'") > 0) {
        print line
    }
    output=0
}
/^## Mod Hotkeys$/ {
    output=1
}
output { print }
' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"

# Cleanup
rm "$TMP_TABLE" "$TMP_ROWS"

echo "Successfully updated README.md with the mod list."
