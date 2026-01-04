
#!/usr/bin/env bash

ACTION="$1" # "create" or "move"
DIR="$2"    # "next" or "prev"

# 1. Get current state
WS_JSON=$(swaymsg -t get_workspaces)
# Get the monitor containing the currently focused window
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
CUR_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused) | .num')

if [ "$DIR" == "next" ]; then
    # Find global max and add 1
    MAX_GLOBAL=$(echo "$WS_JSON" | jq '. | map(.num) | max')
    [[ "$MAX_GLOBAL" == "null" || -z "$MAX_GLOBAL" ]] && MAX_GLOBAL=0
    TARGET=$((MAX_GLOBAL + 1))

    # PRE-PREP: Create the workspace and pin it to the monitor immediately
    swaymsg "workspace $TARGET; move workspace to output $FOCUS_OUTPUT"
else
    # PREV: Find the closest workspace to the left on this monitor
    TARGET=$(echo "$WS_JSON" | jq -r "[.[] | select(.output == \"$FOCUS_OUTPUT\" and .num < $CUR_WS) | .num] | sort | last")

    if [[ -z "$TARGET" || "$TARGET" == "null" ]]; then
        exit 0
    fi
fi

# 2. Perform Action
if [ "$ACTION" == "move" ]; then
    # We use a chained command to ensure the window is sent and followed immediately
    swaymsg "move container to workspace number $TARGET; workspace number $TARGET"
else
    swaymsg "workspace number $TARGET"
fi
