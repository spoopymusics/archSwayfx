#!/usr/bin/env bash

ACTION="$1" # "create" or "move"
DIR="$2"    # "next" or "prev"

# 1. Get current state
WS_JSON=$(swaymsg -t get_workspaces)
# Get the name of the focused monitor (e.g., DP-1 or HDMI-A-1)
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
# Get the number of the currently focused workspace
CUR_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused) | .num')

if [ "$DIR" == "next" ]; then
    # Find the highest workspace number globally + 1 to ensure uniqueness
    MAX_GLOBAL=$(echo "$WS_JSON" | jq '. | map(.num) | max')
    [[ "$MAX_GLOBAL" == "null" || -z "$MAX_GLOBAL" ]] && MAX_GLOBAL=0
    TARGET=$((MAX_GLOBAL + 1))
else
    # Prev: Filter workspaces to ONLY those on the current monitor
    # Then find the largest number that is still smaller than the current one
    TARGET=$(echo "$WS_JSON" | jq "[.[] | select(.output == \"$FOCUS_OUTPUT\" and .num < $CUR_WS) | .num] | max")

    # Fallback: if no smaller workspace exists on THIS monitor, stay put
    if [ "$TARGET" == "null" ]; then
        TARGET=$CUR_WS
    fi
fi

# 2. Perform Action
if [ "$ACTION" == "move" ]; then
    swaymsg "move container to workspace number $TARGET"
    swaymsg "workspace number $TARGET"
else
    swaymsg "workspace number $TARGET"
fi

# 3. Explicitly pin the target workspace to the monitor we started on
swaymsg "workspace $TARGET output $FOCUS_OUTPUT"
