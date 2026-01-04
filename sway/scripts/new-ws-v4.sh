#!/usr/bin/env bash

ACTION="$1" # "create" or "move"
DIR="$2"    # "next" or "prev"

# 1. Get Workspace and Output data
WS_JSON=$(swaymsg -t get_workspaces)

# IMPROVED: Find the monitor that contains the CURRENTLY FOCUSED WINDOW
# If no window is focused, it falls back to the focused output.
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
CUR_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused) | .num')

if [ "$DIR" == "next" ]; then
    # Find the highest workspace number globally + 1
    MAX_GLOBAL=$(echo "$WS_JSON" | jq '. | map(.num) | max')
    [[ "$MAX_GLOBAL" == "null" || -z "$MAX_GLOBAL" ]] && MAX_GLOBAL=0
    TARGET=$((MAX_GLOBAL + 1))

    # CRITICAL: Tell Sway this NEW workspace belongs to the CURRENT monitor
    # before we try to move anything to it.
    swaymsg "workspace $TARGET; move workspace to output $FOCUS_OUTPUT"
else
    # PREV: Find the closest existing workspace to the left ON THIS MONITOR
    TARGET=$(echo "$WS_JSON" | jq -r "[.[] | select(.output == \"$FOCUS_OUTPUT\" and .num < $CUR_WS) | .num] | sort | last")

    if [[ -z "$TARGET" || "$TARGET" == "null" ]]; then
        exit 0
    fi
fi

# 2. Perform the Move/Focus Action
if [ "$ACTION" == "move" ]; then
    swaymsg "move container to workspace number $TARGET"
    swaymsg "workspace number $TARGET"
else
    swaymsg "workspace number $TARGET"
fi
