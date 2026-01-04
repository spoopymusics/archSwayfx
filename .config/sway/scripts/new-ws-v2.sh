
#!/usr/bin/env bash

ACTION="$1" # "create" or "move"
DIR="$2"    # "next" or "prev"

# Get Current State
WS_JSON=$(swaymsg -t get_workspaces)
CUR_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused) | .num')
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

if [ "$DIR" == "next" ]; then
    # Find highest workspace number and add 1
    MAX_WS=$(echo "$WS_JSON" | jq '. | map(.num) | max')
    [[ "$MAX_WS" == "null" || -z "$MAX_WS" ]] && MAX_WS=0
    TARGET=$((MAX_WS + 1))
else
    # Prev: Find the largest existing workspace number that is less than current
    TARGET=$(echo "$WS_JSON" | jq "[.[] | select(.num < $CUR_WS) | .num] | max")

    # If no smaller workspace exists, stay on current to avoid errors
    if [ "$TARGET" == "null" ]; then
        TARGET=$CUR_WS
    fi
fi

# Perform Action
if [ "$ACTION" == "move" ]; then
    swaymsg "move container to workspace number $TARGET"
    swaymsg "workspace number $TARGET"
else
    swaymsg "workspace number $TARGET"
fi

# Ensure the workspace stays on the correct monitor
swaymsg "workspace $TARGET output $FOCUS_OUTPUT"
