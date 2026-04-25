#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
"$SCRIPT_DIR/apply_mods.sh" "mods_multiplayer.csv"