#!/usr/bin/env bash

ACTION="$1" # "create" or "move"
DIR="$2"    # "next" or "prev"

# 1. Get current state and the EXACT ID of the focused window
WS_JSON=$(swaymsg -t get_workspaces)
# Grab the ID of the currently focused window to prevent "focus lock"
CON_ID=$(swaymsg -t get_tree | jq -r '.. | select(.type? == "con" or .type? == "floating_con") | select(.focused == true) | .id')
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
CUR_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused) | .num')

if [ "$DIR" == "next" ]; then
    MAX_GLOBAL=$(echo "$WS_JSON" | jq '. | map(.num) | max')
    [[ "$MAX_GLOBAL" == "null" || -z "$MAX_GLOBAL" ]] && MAX_GLOBAL=0
    TARGET=$((MAX_GLOBAL + 1))
else
    # Try to find existing workspace on THIS monitor
    TARGET=$(echo "$WS_JSON" | jq -r "[.[] | select(.output == \"$FOCUS_OUTPUT\" and .num < $CUR_WS) | .num] | sort | last")

    # If nothing found, force restoration of the "Base" workspace for that monitor
    if [[ -z "$TARGET" || "$TARGET" == "null" ]]; then
        case "$FOCUS_OUTPUT" in
            "DP-1") [ "$CUR_WS" -gt 1 ] && TARGET=1 ;;
            "HDMI-A-1") [ "$CUR_WS" -gt 2 ] && TARGET=2 ;;
            "HDMI-A-2") [ "$CUR_WS" -gt 3 ] && TARGET=3 ;;
        esac
    fi
fi

# 2. Execution Logic
if [ -n "$TARGET" ] && [ "$TARGET" != "null" ]; then
    if [ "$ACTION" == "move" ] && [ -n "$CON_ID" ]; then
        # Use the specific window ID to move and then force focus back to it
        swaymsg "[con_id=$CON_ID] move container to workspace number $TARGET; workspace number $TARGET; [con_id=$CON_ID] focus"
    else
        swaymsg "workspace number $TARGET"
    fi

    # Ensure the workspace is on the correct monitor (unless it's a base workspace)
    # We skip pinning for 1, 2, 3 so your config anchors take over
    if [ "$TARGET" -gt 3 ]; then
        swaymsg "move workspace to output $FOCUS_OUTPUT"
    fi
fi
